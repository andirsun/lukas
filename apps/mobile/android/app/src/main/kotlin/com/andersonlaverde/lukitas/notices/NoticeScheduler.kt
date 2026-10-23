package com.andersonlaverde.lukitas.notices

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Duration
import java.time.Instant
import java.time.ZoneId

/**
 * When the two notices run (spec section 7.2), on AndroidX WorkManager: no Google, no exact
 * alarms.
 *
 *  * "Hoy vence…": a one-time job aimed at the next 9:00 in the profile's zone; it schedules the
 *    next one when it ends ([DueWorker]). WorkManager may run it a few minutes late.
 *  * The guest warning: a one-time job 45 days ahead, replaced each time the app opens on a guest
 *    account and the server accepts a request from it (lib/notices/notice_sync.dart), so it only
 *    ever fires after 45 days without that.
 *
 * "Hoy vence…" waits for a network, since it asks the server before saying anything. The guest
 * warning asks nothing, so it waits for none: a phone offline on day 45 is warned all the same.
 */
object NoticeScheduler {
    const val DUE = "lukitas.notice.due"
    const val GUEST = "lukitas.notice.guest"

    /** The server deletes an inactive guest at 60 days (apps/api/src/services/guest-cleanup.ts). */
    val GUEST_AFTER: Duration = Duration.ofDays(45)

    private val network = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

    /**
     * Turns "Hoy vence…" on: the next 9:00 in [zone] (the profile's; null keeps the one known, else
     * the phone's). Called at every app open, so a job already waiting for that zone is kept.
     */
    fun scheduleDue(context: Context, zone: String?, language: String?, now: Instant = Instant.now()) {
        val settings = NoticeSettings(context)
        val known = settings.zone
        val kept = settings.dueEnabled && (zone == null || zone == known)
        val zoneId = NoticeTimes.zoneOr(zone ?: known, ZoneId.systemDefault())
        settings.dueEnabled = true
        settings.language = language
        if (zone != null) settings.zone = zoneId.id
        enqueueDue(context, zoneId, now, if (kept) ExistingWorkPolicy.KEEP else ExistingWorkPolicy.REPLACE)
    }

    /** The job after this one ([DueWorker] calls it as its last step), 9:00 in [zone]. */
    fun enqueueNextDue(context: Context, zone: ZoneId, now: Instant) =
        enqueueDue(context, zone, now, ExistingWorkPolicy.REPLACE)

    private fun enqueueDue(context: Context, zone: ZoneId, now: Instant, policy: ExistingWorkPolicy) {
        val request = OneTimeWorkRequestBuilder<DueWorker>()
            .setInitialDelay(Duration.between(now, NoticeTimes.nextDueRun(now, zone).toInstant()))
            .setConstraints(network)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(DUE, policy, request)
    }

    fun cancelDue(context: Context) {
        val settings = NoticeSettings(context)
        settings.dueEnabled = false
        // Another person, or the switch on again later, starts with no day recorded.
        settings.lastDueDay = null
        WorkManager.getInstance(context).cancelUniqueWork(DUE)
    }

    /** Sets the guest warning 45 days from now, in place of any earlier one. */
    fun scheduleGuest(context: Context, language: String?) {
        val settings = NoticeSettings(context)
        settings.guestEnabled = true
        settings.language = language
        val request = OneTimeWorkRequestBuilder<GuestWorker>()
            .setInitialDelay(GUEST_AFTER)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(GUEST, ExistingWorkPolicy.REPLACE, request)
    }

    fun cancelGuest(context: Context) {
        NoticeSettings(context).guestEnabled = false
        WorkManager.getInstance(context).cancelUniqueWork(GUEST)
    }

    fun cancelAll(context: Context) {
        cancelDue(context)
        cancelGuest(context)
    }
}
