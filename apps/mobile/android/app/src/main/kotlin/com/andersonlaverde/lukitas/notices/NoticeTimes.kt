package com.andersonlaverde.lukitas.notices

import java.time.DateTimeException
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

/** When "Hoy vence…" goes out (spec section 7.2). */
object NoticeTimes {
    /** 9:00, local time in the profile's zone. */
    val DUE_AT: LocalTime = LocalTime.of(9, 0)

    /**
     * The next 9:00 in [zone] after [now]: today's when it is still ahead, else tomorrow's. The
     * zone is the profile's (where "today" is read for the payments), never the phone's or UTC.
     */
    fun nextDueRun(now: Instant, zone: ZoneId): ZonedDateTime {
        val today = now.atZone(zone).toLocalDate()
        val first = ZonedDateTime.of(today, DUE_AT, zone)
        return if (first.toInstant().isAfter(now)) first else ZonedDateTime.of(today.plusDays(1), DUE_AT, zone)
    }

    /** The zone named [name], or [fallback] when there is none or the phone does not know it. */
    fun zoneOr(name: String?, fallback: ZoneId): ZoneId {
        if (name.isNullOrBlank()) return fallback
        return try {
            ZoneId.of(name)
        } catch (_: DateTimeException) {
            fallback
        }
    }
}
