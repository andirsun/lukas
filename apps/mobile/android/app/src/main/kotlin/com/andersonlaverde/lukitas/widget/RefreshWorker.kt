package com.andersonlaverde.lukitas.widget

import android.content.Context
import androidx.annotation.VisibleForTesting
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.andersonlaverde.lukitas.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Instant
import kotlin.coroutines.CoroutineContext

/** What the refresh needs from outside: the stored session, the API, the clock. */
class RefreshDependencies(
    val session: SessionSource,
    val fetcher: SummaryFetcher,
    val clock: () -> Instant = Instant::now,
    /**
     * Where the snapshot is checked and written: the main thread, where home_widget writes the
     * app's (its method calls run there), so a check and its write never interleave with the app's
     * sign-out write.
     */
    val writeContext: CoroutineContext = Dispatchers.Main,
)

/**
 * Refreshes the widget's figures from `GET /v1/summary` with the stored session (spec section
 * 7.1): about every 3 hours on a network, and just after midnight ([RefreshScheduler]). It reads
 * the token where the app keeps it ([SecureStorageSession]: no second copy) and the server picked
 * in Settings.
 *
 * It never brings a signed-out person's figures back (Review Focus 4): no token, it writes the
 * signed-out snapshot; and what it fetched is dropped when, by the time it writes, the token
 * changed or went, the snapshot was signed out, or the app wrote newer figures. Offline, the last
 * figure stays and the widget marks it "hace un rato" once it is old.
 */
class RefreshWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val context = applicationContext
        val dependencies = Companion.dependencies?.invoke(context) ?: RefreshDependencies(
            session = SecureStorageSession(context),
            fetcher = SummaryFetcher(),
        )
        val outcome = try {
            refresh(context, dependencies)
        } finally {
            // Redrawn either way: "este mes" and "hace un rato" depend on the clock too.
            WidgetUpdates.redrawAll(context)
            if (tags.contains(RefreshScheduler.MIDNIGHT)) RefreshScheduler.scheduleMidnight(context)
        }
        return Result.success(workDataOf(OUTCOME to outcome))
    }

    companion object {
        /** The output key of what a run did ([refresh]'s answer). */
        const val OUTCOME = "outcome"

        /** Replaced in tests. */
        @VisibleForTesting
        var dependencies: ((Context) -> RefreshDependencies)? = null

        /** One refresh; what it did, for the logs and the tests. */
        suspend fun refresh(context: Context, dependencies: RefreshDependencies): String {
            val session = dependencies.session
            val mark = session.mark()
            if (mark == null) {
                withContext(dependencies.writeContext) { writeSignedOut(context) }
                return "signed out"
            }
            // The currency and language come from the app's last snapshot: without one, the app
            // writes everything at its next start.
            val known = WidgetSnapshot.read(context)
            if (known == null || !known.signedIn) return "nothing from the app yet"
            // A server setting that cannot be read is never replaced by the default: for someone
            // on their own server, that would send their token to ours.
            val server = when (val setting = session.server()) {
                ServerSetting.Default -> context.getString(R.string.default_server)
                is ServerSetting.Chosen -> setting.url
                ServerSetting.Unreadable -> return "server unreadable"
            }
            val token = session.token() ?: return "token unreadable"
            val asked = dependencies.clock()
            val result = dependencies.fetcher.fetch(server, token)
            return withContext(dependencies.writeContext) {
                // Checked and written with nothing in between, on the thread of the app's writes.
                if (session.mark() != mark) return@withContext "session changed"
                when (result) {
                    is SummaryResult.Ok -> {
                        val latest = WidgetSnapshot.read(context)
                        if (latest == null || !latest.signedIn) return@withContext "signed out meanwhile"
                        val written = latest.updatedAt
                        if (written != null && written.isAfter(asked)) return@withContext "app was newer"
                        val figures = result.figures
                        write(
                            context,
                            latest.copy(
                                remaining = figures.remaining,
                                spent = figures.spent,
                                budgetTotal = figures.budgetTotal,
                                month = figures.month,
                                mood = if (figures.worried) "worried" else "happy",
                                updatedAt = dependencies.clock(),
                            ),
                        )
                        "refreshed"
                    }
                    SummaryResult.Unauthorized -> {
                        writeSignedOut(context)
                        "session refused"
                    }
                    SummaryResult.Failed -> "failed"
                }
            }
        }

        /** The signed-out snapshot, keeping the person's choices; nothing when already signed out. */
        private fun writeSignedOut(context: Context) {
            val latest = WidgetSnapshot.read(context)
            if (latest != null && !latest.signedIn) return
            write(
                context,
                WidgetSnapshot(
                    signedIn = false,
                    locale = latest?.locale,
                    hideAmount = latest?.hideAmount ?: false,
                    theme = latest?.theme ?: "dark",
                ),
            )
        }

        private fun write(context: Context, snapshot: WidgetSnapshot) {
            WidgetSnapshot.preferences(context).edit()
                .putString(WidgetSnapshot.KEY, snapshot.toJson())
                .commit()
        }
    }
}
