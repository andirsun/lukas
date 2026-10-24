package com.andersonlaverde.lukitas.voice

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** The speech model kept loaded for the life of the process (voice/ModelCache.kt), on a stand-in. */
class ModelCacheTest {
    /** A "model": counts how often it was opened and closed, and can be made slow or broken. */
    private class Fake(val path: String) : AutoCloseable {
        var closed = 0
        override fun close() {
            closed++
        }
    }

    private val opened = mutableListOf<Fake>()
    private val opens = AtomicInteger()
    private var gate: CountDownLatch? = null
    private var failWith: Throwable? = null
    private val executor = Executors.newSingleThreadExecutor()

    private val cache = ModelCache<Fake>(
        open = { path ->
            opens.incrementAndGet()
            gate?.await(5, TimeUnit.SECONDS)
            failWith?.let { throw it }
            Fake(path).also { synchronized(opened) { opened += it } }
        },
        loader = executor,
    )

    @After
    fun tearDown() {
        executor.shutdownNow()
    }

    @Test
    fun `nothing is loaded until it is asked for`() {
        assertNull(cache.loadedPath())
        assertEquals(0, opens.get())
    }

    @Test
    fun `warming loads the model once, however often it is asked`() {
        assertTrue(cache.warm("/models/es").get(5, TimeUnit.SECONDS))
        assertTrue(cache.warm("/models/es").get(5, TimeUnit.SECONDS))
        assertEquals(1, opens.get())
        assertEquals("/models/es", cache.loadedPath())
    }

    @Test
    fun `asking twice while it loads joins the load that is running`() {
        gate = CountDownLatch(1)
        val first = cache.warm("/models/es")
        val second = cache.warm("/models/es")
        assertFalse(first.isDone)
        gate!!.countDown()
        assertTrue(first.get(5, TimeUnit.SECONDS))
        assertTrue(second.get(5, TimeUnit.SECONDS))
        assertEquals(1, opens.get())
    }

    @Test
    fun `a listener gets the model that was loaded in advance, at once`() {
        cache.warm("/models/es").get(5, TimeUnit.SECONDS)
        val lease = cache.acquire("/models/es") { false }
        assertNotNull(lease)
        assertSame(opened.single(), lease!!.model)
        assertEquals(1, opens.get())
        lease.close()
    }

    @Test
    fun `a listener who asks while it loads waits for that load, not a second one`() {
        gate = CountDownLatch(1)
        cache.warm("/models/es")
        val got = Executors.newSingleThreadExecutor().submit<ModelCache.Lease<Fake>?> {
            cache.acquire("/models/es") { false }
        }
        Thread.sleep(80)
        assertFalse(got.isDone)
        gate!!.countDown()
        val lease = got.get(5, TimeUnit.SECONDS)
        assertNotNull(lease)
        assertEquals(1, opens.get())
        lease!!.close()
    }

    @Test
    fun `a listener that is told to stop while it loads leaves at once, and the load still finishes`() {
        gate = CountDownLatch(1)
        var abort = false
        val got = Executors.newSingleThreadExecutor().submit<ModelCache.Lease<Fake>?> {
            cache.acquire("/models/es") { abort }
        }
        Thread.sleep(60)
        abort = true
        assertNull(got.get(2, TimeUnit.SECONDS))
        gate!!.countDown()
        assertTrue(cache.warm("/models/es").get(5, TimeUnit.SECONDS))
        assertEquals("the model was loaded once and kept for the next listener", 1, opens.get())
        assertEquals(0, opened.single().closed)
    }

    @Test
    fun `dropping an idle model closes it, and asking again loads it again`() {
        cache.warm("/models/es").get(5, TimeUnit.SECONDS)
        cache.drop()
        assertNull(cache.loadedPath())
        assertEquals(1, opened.single().closed)
        cache.warm("/models/es").get(5, TimeUnit.SECONDS)
        assertEquals(2, opens.get())
    }

    @Test
    fun `dropping a model that is being used closes it only when the listener lets go`() {
        cache.warm("/models/es").get(5, TimeUnit.SECONDS)
        val lease = cache.acquire("/models/es") { false }!!
        cache.drop()
        assertNull("nobody new gets it", cache.loadedPath())
        assertEquals("still in use: not closed under the recognizers", 0, opened.single().closed)
        lease.close()
        assertEquals(1, opened.single().closed)
        lease.close()
        assertEquals("closing twice changes nothing", 1, opened.single().closed)
    }

    @Test
    fun `dropping while it loads throws that load away`() {
        gate = CountDownLatch(1)
        val load = cache.warm("/models/es")
        cache.drop()
        gate!!.countDown()
        assertFalse("not loaded: it was dropped meanwhile", load.get(5, TimeUnit.SECONDS))
        assertNull(cache.loadedPath())
        assertEquals("the model it opened is closed, not leaked", 1, opened.single().closed)
    }

    @Test
    fun `another model replaces the loaded one, which is closed`() {
        cache.warm("/models/es").get(5, TimeUnit.SECONDS)
        cache.warm("/models/en").get(5, TimeUnit.SECONDS)
        assertEquals("/models/en", cache.loadedPath())
        assertEquals(1, opened.first { it.path == "/models/es" }.closed)
        assertEquals(0, opened.first { it.path == "/models/en" }.closed)
    }

    @Test
    fun `a model that fails to load is no model, and the next ask tries again`() {
        failWith = IllegalStateException("corrupt")
        try {
            cache.warm("/models/es").get(5, TimeUnit.SECONDS)
            fail("expected the failure")
        } catch (_: java.util.concurrent.ExecutionException) {
        }
        assertNull(cache.loadedPath())
        failWith = null
        assertTrue(cache.warm("/models/es").get(5, TimeUnit.SECONDS))
        assertEquals("/models/es", cache.loadedPath())
    }

    @Test
    fun `a listener meets the load failure instead of waiting for ever`() {
        failWith = IllegalStateException("corrupt")
        try {
            cache.acquire("/models/es") { false }
            fail("expected the failure")
        } catch (e: IllegalStateException) {
            assertEquals("corrupt", e.message)
        }
    }

    @Test
    fun `memory pressure frees the model while the app is running low or in the background, not when the screen merely goes away`() {
        // TRIM_MEMORY_RUNNING_MODERATE (5): not yet. UI_HIDDEN (20): the app just went to the
        // background, which is when the next foreground wants the model loaded.
        assertFalse(VoiceModels.shouldReleaseOnTrim(5))
        assertFalse(VoiceModels.shouldReleaseOnTrim(20))
        // RUNNING_LOW (10), RUNNING_CRITICAL (15), BACKGROUND (40), MODERATE (60), COMPLETE (80).
        for (level in listOf(10, 15, 40, 60, 80)) assertTrue("level $level", VoiceModels.shouldReleaseOnTrim(level))
    }
}
