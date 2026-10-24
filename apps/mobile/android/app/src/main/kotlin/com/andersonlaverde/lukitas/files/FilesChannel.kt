package com.andersonlaverde.lukitas.files

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import kotlin.concurrent.thread

/**
 * Files in and out of the app, on the `lukitas/files` method channel (lib/files/files_channel.dart),
 * and nothing else: the app asks for no storage permission. A person picks a file with the system's
 * document picker (Storage Access Framework, `ACTION_OPEN_DOCUMENT`), chooses where to save one
 * (`ACTION_CREATE_DOCUMENT`), or hands one to another app (the share sheet, `ACTION_SEND` with a
 * `FileProvider` link to a copy in the app's cache). The app sees only the one document the person
 * chose.
 *
 *  * `pick({mimeTypes, maxBytes})` → `{name, bytes}`, or null when the picker was closed. The file
 *    is read on a background thread, and never past `maxBytes`: a larger one fails with
 *    `too-large`. Other failures: `unreadable`, `unavailable` (no picker on the phone), `busy`.
 *  * `save({name, bytes, mime})` → true when saved, false when the picker was closed.
 *  * `share({name, bytes, mime})` → true once the share sheet is up.
 *  * `clearShared()` → null once every copy made for the share sheet is deleted.
 *
 * Android has one result slot per request code, so one pick or save is under way at a time.
 */
class FilesChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val methods = MethodChannel(messenger, "lukitas/files")
    private val main = Handler(Looper.getMainLooper())

    private class PendingPick(val result: MethodChannel.Result, val limit: Int)
    private class PendingSave(val result: MethodChannel.Result, val bytes: ByteArray)

    private var pick: PendingPick? = null
    private var save: PendingSave? = null

    init {
        methods.setMethodCallHandler(this)
        // Copies left by an earlier run (a share whose app was killed before the next one).
        thread(name = "files-clean") { clearShared() }
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        clearShared()
    }

    /** Deletes every copy made for the share sheet. */
    private fun clearShared() {
        File(activity.cacheDir, SHARED).listFiles()?.forEach { it.delete() }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(call, result)
            "save" -> save(call, result)
            "share" -> share(call, result)
            // Deleting the account: the copies made for the share sheet go now.
            "clearShared" -> {
                thread(name = "files-clean") {
                    clearShared()
                    main.post { result.success(null) }
                }
            }
            // Debug builds only (src/debug): a test stands in for the person at the picker.
            else -> if (!FilesTestHook.handle(call, result)) result.notImplemented()
        }
    }

    private fun pick(call: MethodCall, result: MethodChannel.Result) {
        if (pick != null || save != null) {
            result.error("busy", "A file is already being picked", null)
            return
        }
        val limit = FileTransfer.limitOf(call.argument<Any>("maxBytes"))
        val pending = PendingPick(result, limit)
        val stand = FilesTestHook.take()
        if (stand != null) {
            pick = pending
            read(stand, limit)
            return
        }
        val types = FileTransfer.mimeTypesOf(call.argument<Any>("mimeTypes"))
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(if (types.size == 1) types[0] else "*/*")
        if (types.size > 1) intent.putExtra(Intent.EXTRA_MIME_TYPES, types.toTypedArray())
        pick = pending
        try {
            activity.startActivityForResult(intent, PICK)
        } catch (e: ActivityNotFoundException) {
            pick = null
            result.error("unavailable", "This phone has no document picker", null)
        }
    }

    private fun save(call: MethodCall, result: MethodChannel.Result) {
        if (pick != null || save != null) {
            result.error("busy", "A file is already being saved", null)
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")
        if (bytes == null || name == null) {
            result.error("bad-arguments", "A name and bytes are needed", null)
            return
        }
        val mime = call.argument<String>("mime") ?: "application/octet-stream"
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(mime)
            .putExtra(Intent.EXTRA_TITLE, FileTransfer.safeName(name))
        val pendingSave = PendingSave(result, bytes)
        save = pendingSave
        val stand = FilesTestHook.takeSave()
        if (stand != null) {
            write(stand, pendingSave)
            return
        }
        try {
            activity.startActivityForResult(intent, SAVE)
        } catch (e: ActivityNotFoundException) {
            save = null
            result.error("unavailable", "This phone has no document picker", null)
        }
    }

    private fun share(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")
        if (bytes == null || name == null) {
            result.error("bad-arguments", "A name and bytes are needed", null)
            return
        }
        val mime = call.argument<String>("mime") ?: "application/octet-stream"
        thread(name = "files-share") {
            try {
                val uri = copyToCache(FileTransfer.safeName(name), bytes)
                main.post {
                    val send = Intent(Intent.ACTION_SEND)
                        .setType(mime)
                        .putExtra(Intent.EXTRA_STREAM, uri)
                        .putExtra(Intent.EXTRA_TITLE, FileTransfer.safeName(name))
                        .apply { clipData = ClipData.newRawUri(name, uri) }
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    try {
                        activity.startActivity(Intent.createChooser(send, null))
                        // The receiving app reads the copy in its own time; it is not needed after.
                        thread(name = "files-clean", isDaemon = true) {
                            Thread.sleep(SHARED_LIFE_MS)
                            clearShared()
                        }
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        result.error("unavailable", "Nothing on this phone can take the file", null)
                    }
                }
            } catch (e: IOException) {
                main.post { result.error("write-failed", e.message, null) }
            }
        }
    }

    /** A copy of the file under `cache/shared/` (the only folder the FileProvider serves). */
    private fun copyToCache(name: String, bytes: ByteArray): Uri {
        val folder = File(activity.cacheDir, SHARED)
        folder.mkdirs()
        // Earlier shares are done with: the receiving app has had the whole time since to read them.
        folder.listFiles()?.forEach { it.delete() }
        val file = File(folder, name)
        file.writeBytes(bytes)
        return FileProvider.getUriForFile(activity, "${activity.packageName}.files", file)
    }

    /** The activity's result: MainActivity hands it over. True when it was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            PICK -> {
                val uri = data?.data
                if (pick == null) return true
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    finishPick { it.success(null) }
                } else {
                    read(uri, pick?.limit ?: return true)
                }
                return true
            }
            SAVE -> {
                val pending = save ?: return true
                val uri = data?.data
                if (resultCode != Activity.RESULT_OK || uri == null) {
                    save = null
                    pending.result.success(false)
                } else {
                    write(uri, pending)
                }
                return true
            }
        }
        return false
    }

    /** Answers the pick on the main thread, where [pick] is kept: it is let go only then. */
    private fun finishPick(deliver: (MethodChannel.Result) -> Unit) {
        main.post {
            val pending = pick ?: return@post
            pick = null
            deliver(pending.result)
        }
    }

    /** Reads the picked document off the main thread, within the limit. */
    private fun read(uri: Uri, limit: Int) {
        thread(name = "files-read") {
            try {
                val size = sizeOf(uri)
                if (size != null && size > limit) {
                    finishPick { it.error("too-large", "The file is larger than $limit bytes", size) }
                    return@thread
                }
                val stream = activity.contentResolver.openInputStream(uri)
                if (stream == null) {
                    finishPick { it.error("unreadable", "The file could not be opened", null) }
                    return@thread
                }
                val bytes = stream.use { FileTransfer.readBounded(it, limit) }
                if (bytes == null) {
                    // No size was announced, or it lied: the stream itself went past the limit.
                    finishPick { it.error("too-large", "The file is larger than $limit bytes", null) }
                } else {
                    val name = nameOf(uri)
                    finishPick { it.success(mapOf("name" to name, "bytes" to bytes)) }
                }
            } catch (e: Exception) {
                // A document that vanished, a provider that refuses, a revoked grant.
                finishPick { it.error("unreadable", e.message ?: "The file could not be opened", null) }
            }
        }
    }

    private fun write(uri: Uri, pending: PendingSave) {
        thread(name = "files-write") {
            try {
                val stream = activity.contentResolver.openOutputStream(uri, "wt")
                    ?: throw IOException("The file could not be opened")
                stream.use { it.write(pending.bytes) }
                main.post {
                    save = null
                    pending.result.success(true)
                }
            } catch (e: Exception) {
                main.post {
                    save = null
                    pending.result.error("write-failed", e.message ?: "The file could not be written", null)
                }
            }
        }
    }

    private fun sizeOf(uri: Uri): Long? = query(uri, OpenableColumns.SIZE)?.toLongOrNull()?.takeIf { it >= 0 }

    private fun nameOf(uri: Uri): String =
        query(uri, OpenableColumns.DISPLAY_NAME)?.takeIf { it.isNotBlank() }
            ?: uri.lastPathSegment?.substringAfterLast('/')
            ?: "file"

    /** One text column of a document's row, or null (a `file:` link has no provider to ask). */
    private fun query(uri: Uri, column: String): String? = try {
        activity.contentResolver.query(uri, arrayOf(column), null, null, null)?.use {
            if (it.moveToFirst() && !it.isNull(0)) it.getString(0) else null
        }
    } catch (e: Exception) {
        null
    }

    private companion object {
        const val PICK = 0x4c46
        const val SAVE = 0x4c47
        const val SHARED = "shared"

        /** How long a copy made for the share sheet stays: ample for any receiver to take it. */
        const val SHARED_LIFE_MS = 10 * 60 * 1000L
    }
}
