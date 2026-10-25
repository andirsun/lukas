package com.andersonlaverde.lukitas.voice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** The microphone level sent to Dart (voice/AudioLevel.kt): one number per chunk, never the audio. */
class AudioLevelTest {
    private fun tone(amplitude: Int, count: Int = 640): ShortArray =
        ShortArray(count) { if (it % 2 == 0) amplitude.toShort() else (-amplitude).toShort() }

    @Test
    fun `silence is 0`() {
        assertEquals(0.0, AudioLevel.of(ShortArray(640), 640), 0.0)
    }

    @Test
    fun `full scale is 1`() {
        assertEquals(1.0, AudioLevel.of(tone(32767), 640), 0.001)
        assertEquals(1.0, AudioLevel.of(ShortArray(640) { Short.MIN_VALUE }, 640), 0.001)
    }

    @Test
    fun `it follows decibels - half the amplitude is 6 dB down and a hundredth is 40 dB down`() {
        assertEquals((50 - 6.02) / 50, AudioLevel.of(tone(16384), 640), 0.01)
        assertEquals((50 - 40.0) / 50, AudioLevel.of(tone(328), 640), 0.01)
    }

    @Test
    fun `below the floor, which is the room's own noise, it is 0`() {
        assertEquals(0.0, AudioLevel.of(tone(30), 640), 0.0)
        assertEquals(0.0, AudioLevel.of(tone(1), 640), 0.0)
    }

    @Test
    fun `louder is never lower, and it stays between 0 and 1`() {
        var previous = -1.0
        for (amplitude in listOf(0, 10, 50, 200, 800, 3000, 12000, 32767)) {
            val level = AudioLevel.of(tone(amplitude), 640)
            assertTrue("$amplitude: $level", level in 0.0..1.0)
            assertTrue("$amplitude not below the quieter one", level >= previous)
            previous = level
        }
    }

    @Test
    fun `only the samples that were read count`() {
        val chunk = tone(32767, 640)
        for (i in 320 until 640) chunk[i] = 0
        // Half the chunk loud, but only its first 320 samples were read.
        assertEquals(1.0, AudioLevel.of(chunk, 320), 0.001)
        assertEquals(0.0, AudioLevel.of(chunk, 0), 0.0)
    }
}
