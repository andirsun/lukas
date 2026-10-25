package com.andersonlaverde.lukitas.notices

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

class NoticeTimesTest {
    private val bogota = ZoneId.of("America/Bogota")

    @Test
    fun `before 9 the next run is today at 9 in the profile's zone`() {
        val now = Instant.parse("2026-10-22T11:00:00Z") // 06:00 in Bogota
        val next = NoticeTimes.nextDueRun(now, bogota)
        assertEquals(ZonedDateTime.of(2026, 10, 22, 9, 0, 0, 0, bogota), next)
        assertEquals(Duration.ofHours(3), Duration.between(now, next))
    }

    @Test
    fun `from 9 on the next run is tomorrow at 9`() {
        val now = Instant.parse("2026-10-22T14:00:00Z") // 09:00 exactly in Bogota
        assertEquals(ZonedDateTime.of(2026, 10, 23, 9, 0, 0, 0, bogota), NoticeTimes.nextDueRun(now, bogota))
    }

    @Test
    fun `the zone is the profile's, not the phone's or UTC`() {
        // 03:00 UTC is still the 22nd (22:00) in Bogota, and already 12:00 in Tokyo.
        val now = Instant.parse("2026-10-23T03:00:00Z")
        assertEquals(ZonedDateTime.of(2026, 10, 23, 9, 0, 0, 0, bogota), NoticeTimes.nextDueRun(now, bogota))
        val tokyo = ZoneId.of("Asia/Tokyo")
        assertEquals(ZonedDateTime.of(2026, 10, 24, 9, 0, 0, 0, tokyo), NoticeTimes.nextDueRun(now, tokyo))
    }

    @Test
    fun `a zone name that does not exist falls back to the one given`() {
        assertEquals(bogota, NoticeTimes.zoneOr("Not/AZone", bogota))
        assertEquals(bogota, NoticeTimes.zoneOr(null, bogota))
        assertEquals(ZoneId.of("Asia/Tokyo"), NoticeTimes.zoneOr("Asia/Tokyo", bogota))
    }
}
