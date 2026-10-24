package com.andersonlaverde.lukitas.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Duration
import java.time.Instant
import java.time.ZoneId

/**
 * When the widget's figures are refreshed ([RefreshWorker], spec section 7.1): about every
 * [INTERVAL] on a network, and a minute after each midnight in the profile's zone (the
 * snapshot's, else the phone's: day and month change). Only while a widget is on the home screen:
 * the first one added schedules it, the last one removed cancels it. AndroidX WorkManager, no
 * Google.
 */
object RefreshScheduler {
    const val PERIODIC = "lukitas.widget.refresh"
    const val MIDNIGHT = "lukitas.widget.midnight"
    val INTERVAL: Duration = Duration.ofHours(3)

    private val RECEIVERS = listOf(
        LukitasSmallWidgetReceiver::class.java,
        LukitasMediumWidgetReceiver::class.java,
    )

    /** Whether any Lukitas widget is on the home screen. */
    fun hasWidgets(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context) ?: return false
        return RECEIVERS.any { manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty() }
    }

    /**
     * Schedules both; what is already scheduled is kept, so calling it again costs nothing, unless
     * the profile's zone has changed since midnight was planned: midnight then moves to the new one.
     */
    fun schedule(context: Context, now: Instant = Instant.now(), phoneZone: ZoneId = ZoneId.systemDefault()) {
        val workManager = WorkManager.getInstance(context)
        val periodic = PeriodicWorkRequestBuilder<RefreshWorker>(INTERVAL)
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .build()
        workManager.enqueueUniquePeriodicWork(PERIODIC, ExistingPeriodicWorkPolicy.KEEP, periodic)
        keepMidnight(context, now, phoneZone)
    }

    /** Midnight as planned, or planned again when the profile's zone is no longer the one it was for. */
    fun keepMidnight(context: Context, now: Instant = Instant.now(), phoneZone: ZoneId = ZoneId.systemDefault()) {
        val zone = zoneOf(context, phoneZone)
        val planned = preferences(context).getString(MIDNIGHT_ZONE, null)
        val policy = if (planned == zone.id) ExistingWorkPolicy.KEEP else ExistingWorkPolicy.REPLACE
        scheduleMidnight(context, now, phoneZone, policy)
    }

    /**
     * The next run a minute after midnight in the profile's zone (no network needed: the labels
     * change too).
     */
    fun scheduleMidnight(
        context: Context,
        now: Instant = Instant.now(),
        phoneZone: ZoneId = ZoneId.systemDefault(),
        policy: ExistingWorkPolicy = ExistingWorkPolicy.REPLACE,
    ) {
        val zone = zoneOf(context, phoneZone)
        val here = now.atZone(zone)
        val next = here.toLocalDate().plusDays(1).atStartOfDay(zone).plusMinutes(1)
        val request = OneTimeWorkRequestBuilder<RefreshWorker>()
            .setInitialDelay(Duration.between(here, next))
            .addTag(MIDNIGHT)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(MIDNIGHT, policy, request)
        preferences(context).edit().putString(MIDNIGHT_ZONE, zone.id).apply()
    }

    /** The profile's zone, from the snapshot the app wrote; [phoneZone] without one. */
    private fun zoneOf(context: Context, phoneZone: ZoneId): ZoneId =
        WidgetSnapshot.read(context)?.zone(phoneZone) ?: phoneZone

    private const val PREFS = "lukitas.widget.refresh"

    /** The zone the midnight run was planned in. */
    private const val MIDNIGHT_ZONE = "midnightZone"

    private fun preferences(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Stops refreshing once no Lukitas widget is left. */
    fun cancelIfNoWidgets(context: Context) {
        if (hasWidgets(context)) return
        val workManager = WorkManager.getInstance(context)
        workManager.cancelUniqueWork(PERIODIC)
        workManager.cancelUniqueWork(MIDNIGHT)
        preferences(context).edit().remove(MIDNIGHT_ZONE).apply()
    }
}
