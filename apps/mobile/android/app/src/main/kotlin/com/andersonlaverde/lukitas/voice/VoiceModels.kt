package com.andersonlaverde.lukitas.voice

import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import org.vosk.LibVosk
import org.vosk.LogLevel
import org.vosk.Model
import java.io.File
import java.util.concurrent.Executors

/**
 * The speech model of the whole process (the Vosk [Model], in a [ModelCache]): it outlives the
 * activity and its Flutter engine, so reopening the app from the widget or the tile finds it
 * loaded while the process lives. Freed on memory pressure ([shouldReleaseOnTrim]) and when the
 * models are deleted (VoiceChannel's `releaseModels`).
 */
object VoiceModels {
    val cache = ModelCache<Model>(
        open = { path ->
            LibVosk.setLogLevel(LogLevel.WARNINGS)
            Model(path)
        },
        loader = Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "lukitas-voice-model").apply {
                isDaemon = true
                priority = Thread.NORM_PRIORITY - 1
            }
        },
    )

    private var registered = false

    /**
     * Whether a [ComponentCallbacks2.onTrimMemory] [level] frees the model: the app running low
     * (10, 15) or cached in the background (40 and up). Not 5 (moderate) nor 20 (the screen just
     * went away), which is when the next foreground wants it loaded.
     */
    fun shouldReleaseOnTrim(level: Int): Boolean = level == 10 || level == 15 || level >= 40

    /** Starts listening to memory pressure for the whole process, once. */
    @Synchronized
    fun register(context: Context) {
        if (registered) return
        registered = true
        context.applicationContext.registerComponentCallbacks(object : ComponentCallbacks2 {
            override fun onTrimMemory(level: Int) {
                if (shouldReleaseOnTrim(level)) cache.drop()
            }

            override fun onConfigurationChanged(newConfig: Configuration) {}

            @Deprecated("Deprecated in Java")
            override fun onLowMemory() {
                cache.drop()
            }
        })
    }

    /**
     * At the process start, before Dart runs: loads the model Dart last asked to have loaded in
     * advance ([WarmHint]), in the background, in parallel with the Flutter engine's own start.
     */
    fun warmFromHint(context: Context) {
        val path = WarmHint.path(context) ?: return
        cache.warm(path)
    }
}

/**
 * The model Dart last asked to load in advance (lib/capture/prewarm.dart does so only for someone
 * who has captured before, and only when the model is downloaded), kept so the next process start
 * can load it before Dart runs. Nothing is remembered until then, so a first use loads nothing in
 * advance. A model folder that is gone or not whole (no `.ready` marker next to it, which the
 * download writes last) is not returned.
 */
object WarmHint {
    private const val FILE = "lukitas_voice"
    private const val KEY = "warm_model_path"

    private fun prefs(context: Context) = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun remember(context: Context, path: String) {
        prefs(context).edit().putString(KEY, path).apply()
    }

    fun forget(context: Context) {
        prefs(context).edit().remove(KEY).apply()
    }

    fun path(context: Context): String? {
        val path = prefs(context).getString(KEY, null) ?: return null
        val folder = File(path)
        return path.takeIf { folder.isDirectory && File("$path.ready").isFile }
    }
}
