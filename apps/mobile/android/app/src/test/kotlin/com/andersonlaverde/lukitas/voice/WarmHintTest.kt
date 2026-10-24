package com.andersonlaverde.lukitas.voice

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File

/**
 * Which model to load when the process starts, before Dart runs (voice/VoiceModels.kt): the one
 * Dart last asked to have loaded in advance, which it only does for someone who has captured before
 * and whose model is downloaded. Nothing is remembered, so nothing is loaded, until then.
 */
@RunWith(RobolectricTestRunner::class)
class WarmHintTest {
    @get:Rule val temp = TemporaryFolder()
    private val context: Context = ApplicationProvider.getApplicationContext()

    /** A model folder as the app leaves it: the folder, and `<folder>.ready` next to it. */
    private fun installed(name: String): String {
        val dir = temp.newFolder(name)
        File(dir.path + ".ready").writeText("sha")
        return dir.path
    }

    @Test
    fun `nothing is remembered at first`() {
        assertNull(WarmHint.path(context))
    }

    @Test
    fun `a model Dart asked to load is the one loaded at the next start`() {
        val path = installed("vosk-model-small-es-0.42")
        WarmHint.remember(context, path)
        assertEquals(path, WarmHint.path(context))
    }

    @Test
    fun `a model that is gone, or not whole, is not loaded`() {
        val path = installed("vosk-model-small-es-0.42")
        WarmHint.remember(context, path)
        File(path + ".ready").delete()
        assertNull("no ready marker: a half-downloaded model", WarmHint.path(context))
        File(path + ".ready").writeText("sha")
        File(path).deleteRecursively()
        assertNull("deleted", WarmHint.path(context))
    }

    @Test
    fun `deleting the models forgets it`() {
        WarmHint.remember(context, installed("vosk-model-small-es-0.42"))
        WarmHint.forget(context)
        assertNull(WarmHint.path(context))
    }

    @Test
    fun `the last one asked for wins`() {
        WarmHint.remember(context, installed("vosk-model-small-es-0.42"))
        val english = installed("vosk-model-small-en-us-0.15")
        WarmHint.remember(context, english)
        assertEquals(english, WarmHint.path(context))
    }
}
