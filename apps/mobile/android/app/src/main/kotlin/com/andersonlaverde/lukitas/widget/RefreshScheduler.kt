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
import java.time.ZonedDateTime

/**
 * When the widget's figures are refreshed ([RefreshWorker], spec section 7.1): about every
 * [INTERVAL] on a network, and a minute after each local midnight (day and month change). Only
 * while a widget is on the home screen: the first one added schedules it, the last one removed
 * cancels it. AndroidX WorkManager, no Google.
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

    /** Schedules both; what is already scheduled is kept, so calling it again costs nothing. */
    fun schedule(context: Context, now: ZonedDateTime = ZonedDateTime.now()) {
        val workManager = WorkManager.getInstance(context)
        val periodic = PeriodicWorkRequestBuilder<RefreshWorker>(INTERVAL)
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .build()
        workManager.enqueueUniquePeriodicWork(PERIODIC, ExistingPeriodicWorkPolicy.KEEP, periodic)
        scheduleMidnight(context, now, ExistingWorkPolicy.KEEP)
    }

    /** The next run a minute after local midnight (no network needed: the labels change too). */
    fun scheduleMidnight(
        context: Context,
        now: ZonedDateTime = ZonedDateTime.now(),
        policy: ExistingWorkPolicy = ExistingWorkPolicy.REPLACE,
    ) {
        val next = now.toLocalDate().plusDays(1).atStartOfDay(now.zone).plusMinutes(1)
        val request = OneTimeWorkRequestBuilder<RefreshWorker>()
            .setInitialDelay(Duration.between(now, next))
            .addTag(MIDNIGHT)
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(MIDNIGHT, policy, request)
    }

    /** Stops refreshing once no Lukitas widget is left. */
    fun cancelIfNoWidgets(context: Context) {
        if (hasWidgets(context)) return
        val workManager = WorkManager.getInstance(context)
        workManager.cancelUniqueWork(PERIODIC)
        workManager.cancelUniqueWork(MIDNIGHT)
    }
}
