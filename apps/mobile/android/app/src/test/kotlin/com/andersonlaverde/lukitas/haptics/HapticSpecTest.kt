package com.andersonlaverde.lukitas.haptics

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class HapticSpecTest {
    private fun args(
        waveform: Any? = listOf(14, 30, 8),
        primitives: Any? = listOf(
            mapOf("name" to "click", "scale" to 0.8, "delay" to 0),
            mapOf("name" to "tick", "scale" to 0.5, "delay" to 30),
        ),
    ) = mapOf("waveform" to waveform, "primitives" to primitives)

    @Test
    fun readsWhatDartSends() {
        val spec = HapticSpec.parse(args())!!
        assertEquals(listOf(14L, 30L, 8L), spec.waveform)
        assertEquals(
            listOf(PrimitiveStep("click", 0.8f, 0), PrimitiveStep("tick", 0.5f, 30)),
            spec.primitives,
        )
    }

    @Test
    fun androidTimingsStartWithAPauseWhereTheWebsPatternStartsWithAVibration() {
        val spec = HapticSpec.parse(args())!!
        assertEquals(listOf(0L, 14L, 30L, 8L), spec.timings().toList())
    }

    @Test
    fun withoutPrimitivesTheWaveformStillPlays() {
        val spec = HapticSpec.parse(args(primitives = null))!!
        assertEquals(emptyList<PrimitiveStep>(), spec.primitives)
        assertEquals(listOf(8L), HapticSpec.parse(args(waveform = listOf(8), primitives = null))!!.waveform)
    }

    @Test
    fun aPrimitiveWeDoNotKnowDropsTheCompositionNotTheWaveform() {
        val spec = HapticSpec.parse(
            args(primitives = listOf(mapOf("name" to "spin", "scale" to 1.0, "delay" to 0))),
        )!!
        assertEquals(emptyList<PrimitiveStep>(), spec.primitives)
        assertEquals(listOf(14L, 30L, 8L), spec.waveform)
    }

    @Test
    fun readsTheDeepPrimitivesWithAClickAndATickToFallBackOn() {
        val spec = HapticSpec.parse(
            args(
                primitives = listOf(
                    mapOf("name" to "thud", "scale" to 0.7, "delay" to 0),
                    mapOf("name" to "lowTick", "scale" to 0.35, "delay" to 50),
                ),
            ),
        )!!
        assertEquals(
            listOf(PrimitiveStep("thud", 0.7f, 0), PrimitiveStep("lowTick", 0.35f, 50)),
            spec.primitives,
        )
        assertEquals(listOf("click", "tick"), spec.primitives.map { it.fallback })
        assertNull(PrimitiveStep("click", 1f, 0).fallback)
    }

    @Test
    fun scalesAreHeldBetweenZeroAndOneAndDelaysAboveZero() {
        val spec = HapticSpec.parse(
            args(
                primitives = listOf(
                    mapOf("name" to "tick", "scale" to 3.0, "delay" to -5),
                    mapOf("name" to "click", "scale" to -1.0, "delay" to 10),
                ),
            ),
        )!!
        assertEquals(listOf(PrimitiveStep("tick", 1f, 0), PrimitiveStep("click", 0f, 10)), spec.primitives)
    }

    @Test
    fun nothingToPlayIsNoSpec() {
        assertNull(HapticSpec.parse(null))
        assertNull(HapticSpec.parse("tick"))
        assertNull(HapticSpec.parse(args(waveform = emptyList<Int>())))
        assertNull(HapticSpec.parse(args(waveform = null)))
        assertNull(HapticSpec.parse(args(waveform = listOf(10, "x"))))
        assertNull(HapticSpec.parse(args(waveform = listOf(10, -3))))
    }

    @Test
    fun aRunawayPatternIsRefused() {
        assertNull(HapticSpec.parse(args(waveform = List(100) { 10 })))
        assertNull(HapticSpec.parse(args(waveform = listOf(5000))))
        assertNotNull(HapticSpec.parse(args(waveform = List(20) { 10 })))
    }
}
