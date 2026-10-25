package com.andersonlaverde.lukitas.voice

import java.util.concurrent.CompletableFuture
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/**
 * One speech model kept loaded for as long as the process lives, so a tap on 🎤 never waits for the
 * 300 ms or more a Vosk model takes to load. It is loaded in the background ([warm], from Dart's
 * `warmUp` or from the hint at the process start), handed to a recording for as long as it needs it
 * ([acquire], released with [Lease.close]) and freed by [drop] (memory pressure, the models
 * deleted). A model that is dropped while a recording uses it is closed when that recording lets go,
 * never under its recognizers. Generic over the model so it can be tested without Vosk's native
 * library.
 */
class ModelCache<T : AutoCloseable>(
    private val open: (String) -> T,
    private val loader: ExecutorService,
) {
    private class Load(val path: String) {
        val result = CompletableFuture<Boolean>()
    }

    /** The model in use by a recording; [close] hands it back. */
    class Lease<T : AutoCloseable> internal constructor(
        val model: T,
        private val cache: ModelCache<T>,
    ) : AutoCloseable {
        private var closed = false

        override fun close() {
            synchronized(cache.lock) {
                if (closed) return
                closed = true
                cache.uses--
                cache.closeRetiredWhenIdle()
            }
        }
    }

    internal val lock = Any()
    private var model: T? = null
    private var path: String? = null
    private var loading: Load? = null
    internal var uses = 0

    /** Models that were dropped or replaced while in use: closed once nobody uses any. */
    private val retired = mutableListOf<T>()

    /** Counts the drops, so a load that was running when one came is thrown away. */
    private var generation = 0

    /** The path of the model that is loaded now, or null. */
    fun loadedPath(): String? = synchronized(lock) { if (model != null) path else null }

    /**
     * Loads the model at [path] in the background, unless it is loaded (or loading) already. The
     * future completes with true once it is loaded, with false when it was dropped meanwhile, and
     * with the failure when it could not be opened.
     */
    fun warm(path: String): CompletableFuture<Boolean> = synchronized(lock) {
        if (model != null && this.path == path) return CompletableFuture.completedFuture(true)
        startLoad(path).result
    }

    /**
     * The model at [path], loading it first if it is not (waiting for a load already running),
     * as a [Lease] to close when done. Null when [abort] says so while waiting: the load carries on
     * for the next listener. Throws the load's failure.
     */
    fun acquire(path: String, abort: () -> Boolean): Lease<T>? {
        while (true) {
            val load = synchronized(lock) {
                val current = model
                if (current != null && this.path == path) {
                    uses++
                    return Lease(current, this)
                }
                startLoad(path)
            }
            while (true) {
                if (abort()) return null
                try {
                    load.result.get(POLL_MS, TimeUnit.MILLISECONDS)
                    break
                } catch (_: TimeoutException) {
                    // Still loading.
                } catch (error: ExecutionException) {
                    throw error.cause ?: error
                }
            }
        }
    }

    /** Frees the model now, or when the recording that uses it lets go. */
    fun drop() {
        synchronized(lock) {
            generation++
            model?.let { retired += it }
            model = null
            path = null
            loading = null
            closeRetiredWhenIdle()
        }
    }

    /** Under [lock]. */
    private fun startLoad(path: String): Load {
        loading?.takeIf { it.path == path }?.let { return it }
        val load = Load(path)
        loading = load
        val started = generation
        loader.execute {
            val opened = try {
                open(path)
            } catch (error: Throwable) {
                synchronized(lock) { if (loading === load) loading = null }
                load.result.completeExceptionally(error)
                return@execute
            }
            val kept = synchronized(lock) {
                if (loading === load) loading = null
                if (started != generation) {
                    retired += opened
                    false
                } else {
                    model?.let { retired += it }
                    model = opened
                    this.path = path
                    true
                }.also { closeRetiredWhenIdle() }
            }
            load.result.complete(kept)
        }
        return load
    }

    /** Under [lock]. */
    internal fun closeRetiredWhenIdle() {
        if (uses > 0) return
        for (old in retired) {
            try {
                old.close()
            } catch (_: Throwable) {
                // Already gone.
            }
        }
        retired.clear()
    }

    private companion object {
        /** How often a waiting listener checks whether it was told to stop. */
        const val POLL_MS = 20L
    }
}
