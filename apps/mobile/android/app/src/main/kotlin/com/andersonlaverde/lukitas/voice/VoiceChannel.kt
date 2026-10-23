package com.andersonlaverde.lukitas.voice

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.vosk.LibVosk
import org.vosk.LogLevel
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File
import java.util.concurrent.Executors
import java.util.zip.ZipInputStream

/**
 * Quick capture's ears (lib/capture/engine/voice_channel.dart), on the `lukitas/voice` method channel
 * and the `lukitas/voice/events` event channel.
 *
 * Speech is recognised on the phone by Vosk (the voice spike's choice), never by Android's platform
 * speech recognition API, which hands audio to the phone's recognition service. Audio comes from
 * AudioRecord (VOICE_RECOGNITION, 16 kHz mono PCM16) in 100 ms chunks and is fed, while the person
 * speaks, to two recognizers sharing one Model: a free one and one biased by a grammar (a JSON list
 * of words built in Dart). Both give word timestamps. Every result at an endpoint is sent, not only
 * the final one: the grammar recognizer hits endpoints mid-sentence. Dart merges the two.
 *
 * Methods: `supported` → Boolean (the native library loads); `requestPermission` → Boolean;
 * `stop`; `modelsDirectory` → String; `unzip({zip, into})`; `releaseModels`.
 * Events, after listening with `{modelPath, grammar}`: `{type: partial, text}`,
 * `{type: result, pass: free|grammar, json}`, `{type: done}` (then the stream ends) or
 * `{type: error, code}`.
 */
class VoiceChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methods = MethodChannel(messenger, "lukitas/voice")
    private val events = EventChannel(messenger, "lukitas/voice/events")
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private val files = Executors.newSingleThreadExecutor()

    private var pendingPermission: MethodChannel.Result? = null

    @Volatile private var stopRequested = false
    @Volatile private var session: Int = 0

    // Kept loaded between sentences (loading takes about 300 ms); freed by releaseModels.
    private var model: Model? = null
    private var modelPath: String? = null

    init {
        // JNA passes Java strings to Vosk in this encoding: the grammar must reach it as UTF-8, or
        // every accented word (gasté, millón…) is silently dropped.
        System.setProperty("jna.encoding", "UTF-8")
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "supported" -> files.execute {
                val ok = try {
                    LibVosk.setLogLevel(LogLevel.WARNINGS)
                    true
                } catch (error: Throwable) {
                    false
                }
                main.post { result.success(ok) }
            }
            "requestPermission" -> requestPermission(result)
            "stop" -> {
                stopRequested = true
                result.success(null)
            }
            "modelsDirectory" -> result.success(activity.noBackupFilesDir.absolutePath)
            "unzip" -> {
                val zip = call.argument<String>("zip")
                val into = call.argument<String>("into")
                if (zip == null || into == null) {
                    result.error("failed", "Missing zip or into", null)
                    return
                }
                files.execute {
                    try {
                        unzip(File(zip), File(into))
                        main.post { result.success(null) }
                    } catch (error: Exception) {
                        main.post { result.error("failed", error.message, null) }
                    }
                }
            }
            "releaseModels" -> {
                stopRequested = true
                worker.execute {
                    model?.close()
                    model = null
                    modelPath = null
                    main.post { result.success(null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION_REQUEST)
    }

    /** From MainActivity.onRequestPermissionsResult. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermission?.success(granted)
        pendingPermission = null
        return true
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        val args = arguments as? Map<*, *>
        val path = args?.get("modelPath") as? String
        val grammar = args?.get("grammar") as? String
        if (path == null || grammar == null) {
            sink.success(mapOf("type" to "error", "code" to "bad_arguments"))
            sink.endOfStream()
            return
        }
        stopRequested = false
        val id = ++session
        worker.execute { record(id, path, grammar, sink) }
    }

    override fun onCancel(arguments: Any?) {
        // The Dart side stopped listening (the sheet closed): stop recording, send nothing more.
        stopRequested = true
        session++
    }

    private fun send(id: Int, sink: EventChannel.EventSink, event: Map<String, Any>) {
        main.post { if (id == session) sink.success(event) }
    }

    private fun record(id: Int, path: String, grammar: String, sink: EventChannel.EventSink) {
        var free: Recognizer? = null
        var biased: Recognizer? = null
        var audio: AudioRecord? = null
        try {
            val loaded = if (modelPath == path && model != null) {
                model!!
            } else {
                model?.close()
                Model(path).also {
                    model = it
                    modelPath = path
                }
            }
            free = Recognizer(loaded, SAMPLE_RATE.toFloat()).apply { setWords(true) }
            biased = Recognizer(loaded, SAMPLE_RATE.toFloat(), grammar).apply { setWords(true) }

            val minimum = AudioRecord.getMinBufferSize(
                SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
            )
            if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                throw IllegalStateException("permission")
            }
            audio = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minimum, CHUNK * 2 * 4),
            )
            if (audio.state != AudioRecord.STATE_INITIALIZED) throw IllegalStateException("mic")
            audio.startRecording()

            val chunk = ShortArray(CHUNK)
            var lastPartial = ""
            while (!stopRequested && id == session) {
                val read = audio.read(chunk, 0, chunk.size)
                if (read < 0) throw IllegalStateException("mic_read_$read")
                if (read == 0) continue
                if (free.acceptWaveForm(chunk, read)) {
                    send(id, sink, mapOf("type" to "result", "pass" to "free", "json" to free.result))
                    lastPartial = ""
                } else {
                    val partial = JSONObject(free.partialResult).optString("partial", "")
                    if (partial != lastPartial) {
                        lastPartial = partial
                        send(id, sink, mapOf("type" to "partial", "text" to partial))
                    }
                }
                if (biased.acceptWaveForm(chunk, read)) {
                    send(id, sink, mapOf("type" to "result", "pass" to "grammar", "json" to biased.result))
                }
            }
            audio.stop()
            if (id == session) {
                send(id, sink, mapOf("type" to "result", "pass" to "free", "json" to free.finalResult))
                send(id, sink, mapOf("type" to "result", "pass" to "grammar", "json" to biased.finalResult))
                send(id, sink, mapOf("type" to "done"))
                main.post { if (id == session) sink.endOfStream() }
            }
        } catch (error: Throwable) {
            val code = when (error.message) {
                "permission" -> "permission"
                "mic" -> "mic_unavailable"
                else -> "failed"
            }
            send(id, sink, mapOf("type" to "error", "code" to code))
            main.post { if (id == session) sink.endOfStream() }
        } finally {
            audio?.release()
            free?.close()
            biased?.close()
        }
    }

    /** Unzips [zip] into [into], refusing entries that would land outside it. */
    private fun unzip(zip: File, into: File) {
        val root = into.canonicalFile
        root.mkdirs()
        ZipInputStream(zip.inputStream().buffered()).use { stream ->
            while (true) {
                val entry = stream.nextEntry ?: break
                val target = File(root, entry.name).canonicalFile
                if (!target.path.startsWith(root.path + File.separator)) {
                    throw SecurityException("Zip entry outside the target: ${entry.name}")
                }
                if (entry.isDirectory) {
                    target.mkdirs()
                } else {
                    target.parentFile?.mkdirs()
                    target.outputStream().use { stream.copyTo(it) }
                }
            }
        }
    }

    companion object {
        private const val SAMPLE_RATE = 16000

        /** 100 ms of 16 kHz mono audio. */
        private const val CHUNK = 1600
        private const val PERMISSION_REQUEST = 4210
    }
}
