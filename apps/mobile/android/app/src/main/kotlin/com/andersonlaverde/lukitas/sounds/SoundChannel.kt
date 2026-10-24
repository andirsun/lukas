package com.andersonlaverde.lukitas.sounds

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The feedback sounds (lib/feedback/feedback_platform.dart), on the `lukitas/sounds` method
 * channel: Android's own [SoundPool], so there is no audio plugin and nothing from Google.
 *
 * `preload({assets})` → Int loads Flutter assets (the web's tiny mp3 files, under 4 KB each) so the
 * first sound is not late; `play({asset})` → Boolean plays one at once, on top of any still playing, at the web's
 * volume. A sound asked for before it has loaded plays as soon as it has. The sounds are
 * sonification (like a keyboard's click), so they follow the phone's own sound volume and stay
 * quiet in silent mode, and they take no audio focus: music playing carries on.
 */
class SoundChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val methods = MethodChannel(messenger, "lukitas/sounds")
    private var pool: SoundPool? = null
    private val ids = HashMap<String, Int>()
    private val loaded = HashSet<Int>()
    private val waiting = HashSet<Int>()

    init {
        methods.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "preload" -> {
                val assets = (call.argument<List<*>>("assets") ?: emptyList<Any>()).filterIsInstance<String>()
                // How many are loading, so a test on a phone can tell the assets were found.
                result.success(assets.count { load(it) != null })
            }
            "play" -> {
                val asset = call.argument<String>("asset")
                if (asset == null) {
                    result.error("bad-sound", "No asset", null)
                    return
                }
                result.success(play(asset))
            }
            else -> result.notImplemented()
        }
    }

    @Synchronized
    fun dispose() {
        methods.setMethodCallHandler(null)
        pool?.release()
        pool = null
        ids.clear()
        loaded.clear()
        waiting.clear()
    }

    @Synchronized
    private fun soundPool(): SoundPool = pool ?: SoundPool.Builder()
        .setMaxStreams(3)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build(),
        )
        .build()
        .also { created ->
            created.setOnLoadCompleteListener { soundPool, id, status ->
                synchronized(this) {
                    if (status != 0) return@setOnLoadCompleteListener
                    loaded.add(id)
                    if (waiting.remove(id)) soundPool.play(id, VOLUME, VOLUME, 1, 0, 1f)
                }
            }
            pool = created
        }

    @Synchronized
    private fun load(asset: String): Int? {
        ids[asset]?.let { return it }
        return try {
            val id = loadFromAssets(soundPool(), asset)
            ids[asset] = id
            id
        } catch (e: Exception) {
            // A missing or unreadable file: that sound stays silent.
            null
        }
    }

    private fun loadFromAssets(pool: SoundPool, asset: String): Int {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        return try {
            context.assets.openFd(key).use { pool.load(it, 1) }
        } catch (e: java.io.IOException) {
            // A compressed asset has no file descriptor: copy it out once, and load the copy.
            val copy = File(context.cacheDir, "sound-" + asset.replace('/', '_'))
            if (!copy.exists()) {
                context.assets.open(key).use { input -> copy.outputStream().use { input.copyTo(it) } }
            }
            pool.load(copy.path, 1)
        }
    }

    @Synchronized
    private fun play(asset: String): Boolean {
        val id = load(asset) ?: return false
        if (id in loaded) soundPool().play(id, VOLUME, VOLUME, 1, 0, 1f) else waiting.add(id)
        return true
    }

    private companion object {
        /** The web's `VOLUME`. */
        const val VOLUME = 0.6f
    }
}
