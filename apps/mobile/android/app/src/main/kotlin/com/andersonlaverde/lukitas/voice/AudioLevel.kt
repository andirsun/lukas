package com.andersonlaverde.lukitas.voice

import kotlin.math.log10
import kotlin.math.sqrt

/**
 * The microphone's level for the capture sheet's live animation (lib/capture/mic_level.dart): one
 * number per chunk of audio, from 0 (silence) to 1 (full scale). Only this number goes to Dart;
 * the audio never does.
 */
object AudioLevel {
    /** The quietest level shown, in dBFS: below it (a room's own noise) is 0. Full scale is 1. */
    private const val FLOOR_DB = -50.0

    /** The level of the first [count] samples of [samples]: their RMS in dBFS, from [FLOOR_DB] up to 0 dBFS as 0..1. */
    fun of(samples: ShortArray, count: Int): Double {
        val n = minOf(count, samples.size)
        if (n <= 0) return 0.0
        var sum = 0.0
        for (i in 0 until n) {
            val s = samples[i].toDouble()
            sum += s * s
        }
        val rms = sqrt(sum / n)
        if (rms <= 0.0) return 0.0
        val db = 20 * log10(rms / 32768.0)
        return ((db - FLOOR_DB) / -FLOOR_DB).coerceIn(0.0, 1.0)
    }
}
