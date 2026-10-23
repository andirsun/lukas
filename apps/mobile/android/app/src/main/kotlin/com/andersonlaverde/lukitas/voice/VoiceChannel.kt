package com.andersonlaverde.lukitas.voice

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.os.StatFs
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
 * `warmUp({modelPath})` → Boolean (loads the model in the background, keeps it while the process
 * lives; never records); `isWarm({modelPath})` → Boolean (loaded, and the microphone allowed);
 * `stop`; `modelsDirectory` → String; `freeBytes` → Long; `unzip({zip, into})`; `releaseModels`.
 * Events, after listening with `{modelPath, grammar}`: `{type: ready}` once the microphone records,
 * `{type: level, value}` (0..1, about 25 a second: only a number, never the audio),
 * `{type: partial, text}`, `{type: result, pass: free|grammar, json}`, `{type: done}` (then the
 * stream ends) or `{type: error, code}`.
 *
 * Fast start: the microphone is opened first, the moment the person's tap reaches here, with room
 * for four seconds of audio; the model and the two recognizers attach while it records, and what was
 * said meanwhile is read from that buffer first, so no word is lost. The model is the process's
 * ([VoiceModels]), loaded in advance and kept; a recording only borrows it.
 */
class VoiceChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methods = MethodChannel(messenger, "lukitas/voice")
    private val events = EventChannel(messenger, "lukitas/voice/events")
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private val files = Executors.newSingleThreadExecutor()

    private var pendingPermission: MethodChannel.Result? = null

    /** The person is done talking (or listening ends for any reason): reading the microphone stops. */
    @Volatile private var stopRequested = false

    /**
     * Nothing more is wanted, not even what was said while the model loaded: the app went to the
     * background, the sheet closed, the models are being deleted, the channel is disposed. A plain
     * [stopRequested] still recognises what the microphone kept while the recognizers attached.
     */
    @Volatile private var hardStop = false
    @Volatile private var session: Int = 0
    @Volatile private var disposed = false

    // The model is the process's (VoiceModels): loaded in advance, kept between sentences and across
    // activities, freed on memory pressure and by releaseModels.
    private val models = VoiceModels.cache

    init {
        VoiceModels.register(activity)
        // JNA passes Java strings to Vosk in this encoding: the grammar must reach it as UTF-8, or
        // every accented word (gasté, millón…) is silently dropped.
        System.setProperty("jna.encoding", "UTF-8")
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (disposed) {
            result.error("failed", "Voice channel disposed", null)
            return
        }
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
            "warmUp" -> {
                val path = call.argument<String>("modelPath")
                if (path == null) {
                    result.error("failed", "Missing modelPath", null)
                    return
                }
                // The next process start loads this one before Dart runs (VoiceModels.warmFromHint).
                WarmHint.remember(activity, path)
                models.warm(path).whenComplete { loaded, error ->
                    main.post {
                        if (error != null) result.error("failed", error.message, null) else result.success(loaded)
                    }
                }
            }
            "isWarm" -> {
                val path = call.argument<String>("modelPath")
                result.success(
                    path != null && models.loadedPath() == path &&
                        activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                        PackageManager.PERMISSION_GRANTED,
                )
            }
            "stop" -> {
                stopRequested = true
                result.success(null)
            }
            "modelsDirectory" -> result.success(activity.noBackupFilesDir.absolutePath)
            "freeBytes" -> result.success(StatFs(activity.noBackupFilesDir.absolutePath).availableBytes)
            "unzip" -> {
                val zip = call.argument<String>("zip")
                val into = call.argument<String>("into")
                if (zip == null || into == null) {
                    result.error("failed", "Missing zip or into", null)
                    return
                }
                files.execute {
                    try {
                        ZipExtract.unzip(File(zip), File(into))
                        main.post { result.success(null) }
                    } catch (error: Exception) {
                        main.post { result.error("failed", error.message, null) }
                    }
                }
            }
            "releaseModels" -> {
                stopRequested = true
                hardStop = true
                WarmHint.forget(activity)
                // Behind a running recording on the worker, which ends within one chunk now; the
                // model itself is closed when nobody uses it.
                worker.execute {
                    models.drop()
                    main.post { result.success(null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Stops recording now (the app went to the background): the loop ends within one chunk. */
    fun stopRecording() {
        stopRequested = true
        hardStop = true
    }

    /**
     * The activity or engine is going away: end the recording loop (it holds the microphone and two
     * recognizers), shut the threads down, and answer nothing more. Safe to call
     * twice.
     */
    fun dispose() {
        if (disposed) return
        disposed = true
        stopRequested = true
        hardStop = true
        session++
        pendingPermission?.success(false)
        pendingPermission = null
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        // The model stays: it is the process's, for the next activity (VoiceModels).
        worker.shutdown()
        files.shutdown()
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
        if (disposed || path == null || grammar == null) {
            sink.success(mapOf("type" to "error", "code" to "bad_arguments"))
            sink.endOfStream()
            return
        }
        stopRequested = false
        hardStop = false
        val id = ++session
        worker.execute { record(id, path, grammar, sink) }
    }

    override fun onCancel(arguments: Any?) {
        // The Dart side stopped listening (the sheet closed): stop recording, send nothing more.
        stopRequested = true
        hardStop = true
        session++
    }

    private fun send(id: Int, sink: EventChannel.EventSink, event: Map<String, Any>) {
        main.post { if (id == session) sink.success(event) }
    }

    private fun record(id: Int, path: String, grammar: String, sink: EventChannel.EventSink) {
        var free: Recognizer? = null
        var biased: Recognizer? = null
        var audio: AudioRecord? = null
        var lease: ModelCache.Lease<Model>? = null
        try {
            if (stopRequested || hardStop || id != session) return endUnheard(id, sink, null, null)
            if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                throw IllegalStateException("permission")
            }
            // 1. The microphone, first: from here every word is kept in AudioRecord's own buffer
            // while the model and the recognizers attach.
            val minimum = AudioRecord.getMinBufferSize(
                SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT,
            )
            audio = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minimum, BUFFER_BYTES),
            )
            if (audio.state != AudioRecord.STATE_INITIALIZED) throw IllegalStateException("mic")
            audio.startRecording()
            send(id, sink, mapOf("type" to "ready"))

            // 2. The model: loaded already when it was warmed up; otherwise loading starts now.
            // Meanwhile the audio is read (and its level shown) and kept, to be recognised first.
            val chunk = ShortArray(CHUNK)
            val backlog = ArrayDeque<ShortArray>()
            val loading = models.warm(path)
            while (!loading.isDone) {
                if (hardStop || id != session) return endUnheard(id, sink, null, null)
                if (stopRequested) {
                    // Done talking before the model was up: no more audio is read, but what was
                    // said is still recognised once it is.
                    Thread.sleep(10)
                    continue
                }
                val read = audio.read(chunk, 0, chunk.size)
                if (read < 0) throw IllegalStateException("mic_read_$read")
                if (read == 0) continue
                backlog.addLast(chunk.copyOf(read))
                sendLevel(id, sink, chunk, read)
            }
            lease = models.acquire(path) { hardStop || id != session }
                ?: return endUnheard(id, sink, null, null)
            val model = lease.model
            free = Recognizer(model, SAMPLE_RATE.toFloat()).apply { setWords(true) }
            biased = Recognizer(model, SAMPLE_RATE.toFloat(), grammar).apply { setWords(true) }

            // 3. Recognise: first what was said while the above attached, then live.
            var lastPartial = ""
            fun feed(samples: ShortArray, count: Int) {
                if (free.acceptWaveForm(samples, count)) {
                    send(id, sink, mapOf("type" to "result", "pass" to "free", "json" to free.result))
                    lastPartial = ""
                } else {
                    val partial = JSONObject(free.partialResult).optString("partial", "")
                    if (partial != lastPartial) {
                        lastPartial = partial
                        send(id, sink, mapOf("type" to "partial", "text" to partial))
                    }
                }
                if (biased.acceptWaveForm(samples, count)) {
                    send(id, sink, mapOf("type" to "result", "pass" to "grammar", "json" to biased.result))
                }
            }
            while (backlog.isNotEmpty() && !hardStop && id == session) {
                val old = backlog.removeFirst()
                feed(old, old.size)
            }
            while (!stopRequested && !hardStop && id == session) {
                val read = audio.read(chunk, 0, chunk.size)
                if (read < 0) throw IllegalStateException("mic_read_$read")
                if (read == 0) continue
                sendLevel(id, sink, chunk, read)
                feed(chunk, read)
            }
            audio.stop()
            endUnheard(id, sink, free, biased)
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
            lease?.close()
        }
    }

    /** One level event for the audio just read (never the audio itself). */
    private fun sendLevel(id: Int, sink: EventChannel.EventSink, samples: ShortArray, count: Int) {
        send(id, sink, mapOf("type" to "level", "value" to AudioLevel.of(samples, count)))
    }

    /**
     * Ends the stream: the final result of each recognizer that exists, then done. Called when the
     * recording was stopped, whether or not the recognizers had come up.
     */
    private fun endUnheard(id: Int, sink: EventChannel.EventSink, free: Recognizer?, biased: Recognizer?) {
        if (id != session) return
        if (free != null) send(id, sink, mapOf("type" to "result", "pass" to "free", "json" to free.finalResult))
        if (biased != null) send(id, sink, mapOf("type" to "result", "pass" to "grammar", "json" to biased.finalResult))
        send(id, sink, mapOf("type" to "done"))
        main.post { if (id == session) sink.endOfStream() }
    }

    companion object {
        private const val SAMPLE_RATE = 16000

        /** 40 ms of 16 kHz mono audio: 25 level events a second. */
        private const val CHUNK = 640

        /** Room for four seconds of audio while the model loads and the recognizers attach (PCM16). */
        private const val BUFFER_BYTES = SAMPLE_RATE * 2 * 4
        private const val PERMISSION_REQUEST = 4210
    }
}
