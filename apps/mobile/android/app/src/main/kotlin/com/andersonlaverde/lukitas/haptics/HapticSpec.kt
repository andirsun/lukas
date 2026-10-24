package com.andersonlaverde.lukitas.haptics

/** One step of a composition: `click` or `tick` at a [scale] (0 to 1) after [delayMs] of quiet. */
data class PrimitiveStep(val name: String, val scale: Float, val delayMs: Int)

/**
 * What Dart asks the motor for (lib/feedback/feedback_event.dart's `HapticPattern`): the web's
 * pattern as [waveform] (ms: vibrate, pause, vibrate...), and the same feel as [primitives] for
 * Android 11 and up. Plain data, so it is tested without a phone.
 */
data class HapticSpec(val waveform: List<Long>, val primitives: List<PrimitiveStep>) {
    /**
     * Android's waveform timings start with a pause (off, on, off, on...), where the web's patterns
     * start with a vibration: a zero pause goes in front.
     */
    fun timings(): LongArray = (listOf(0L) + waveform).toLongArray()

    companion object {
        private const val MAX_STEPS = 32
        private const val MAX_MS = 1000L
        private val KNOWN = setOf("click", "tick")

        /** The spec in a method call's arguments, or null when there is nothing sound to play. */
        fun parse(arguments: Any?): HapticSpec? {
            val map = arguments as? Map<*, *> ?: return null
            val raw = map["waveform"] as? List<*> ?: return null
            if (raw.isEmpty() || raw.size > MAX_STEPS) return null
            val waveform = raw.map { (it as? Number)?.toLong() ?: return null }
            if (waveform.any { it < 0 || it > MAX_MS }) return null
            return HapticSpec(waveform, primitives(map["primitives"]))
        }

        // A step it cannot read drops the whole composition: the waveform still plays.
        private fun primitives(raw: Any?): List<PrimitiveStep> {
            val steps = raw as? List<*> ?: return emptyList()
            if (steps.size > MAX_STEPS) return emptyList()
            return steps.map { step ->
                val entry = step as? Map<*, *> ?: return emptyList()
                val name = entry["name"] as? String ?: return emptyList()
                if (name !in KNOWN) return emptyList()
                val scale = (entry["scale"] as? Number)?.toFloat() ?: return emptyList()
                val delay = (entry["delay"] as? Number)?.toInt() ?: return emptyList()
                PrimitiveStep(name, scale.coerceIn(0f, 1f), delay.coerceAtLeast(0))
            }
        }
    }
}
