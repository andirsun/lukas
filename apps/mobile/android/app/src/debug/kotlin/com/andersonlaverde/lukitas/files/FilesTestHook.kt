package com.andersonlaverde.lukitas.files

import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Debug builds only (this source set; release and profile have a no-op of the same name): lets an
 * integration test stand in for the person at the document picker. `injectPick(path)` makes the next
 * `pick` return that file, which then goes through the same bounded read as a picked document, and
 * `injectSave(path)` makes the next `save` write to that file (the place the person would have chosen),
 * through the same write as a saved document.
 */
internal object FilesTestHook {
    @Volatile private var injected: Uri? = null
    @Volatile private var injectedSave: Uri? = null

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        if (call.method != "injectPick" && call.method != "injectSave") return false
        val path = call.arguments as? String
        if (path == null) {
            result.error("bad-arguments", "A path is needed", null)
        } else {
            if (call.method == "injectPick") injected = Uri.fromFile(File(path))
            else injectedSave = Uri.fromFile(File(path))
            result.success(null)
        }
        return true
    }

    /** The injected file, once. */
    fun take(): Uri? = injected.also { injected = null }

    /** Where the next save goes instead of the picker, once. */
    fun takeSave(): Uri? = injectedSave.also { injectedSave = null }
}
