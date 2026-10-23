package com.andersonlaverde.lukitas.notices

import android.content.Context
import androidx.annotation.VisibleForTesting
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.andersonlaverde.lukitas.R
import com.andersonlaverde.lukitas.widget.SecureStorageSession
import com.andersonlaverde.lukitas.widget.ServerSetting
import com.andersonlaverde.lukitas.widget.SessionSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** What the notices' jobs need from outside: the stored session, the API, the clock. */
class NoticeDependencies(
    val session: SessionSource,
    val api: NoticeApi = NoticeApi(),
    val clock: () -> Instant = Instant::now,
)

object NoticeHooks {
    /** Replaced in tests. */
    @VisibleForTesting
    var dependencies: ((Context) -> NoticeDependencies)? = null

    /**
     * The real ones read the token where the app keeps it ([SecureStorageSession], read-only: never
     * a second copy of the token, never a write to the secure storage).
     */
    fun of(context: Context): NoticeDependencies =
        dependencies?.invoke(context) ?: NoticeDependencies(session = SecureStorageSession(context))
}

/**
 * The server a job asks: the one picked in Settings, else the app's default. A setting that is
 * stored but cannot be read is never replaced by the default (that would send the person's token to
 * our server instead of theirs): null, and the job does nothing.
 */
internal fun serverOf(context: Context, session: SessionSource): String? = when (val setting = session.server()) {
    ServerSetting.Default -> context.getString(R.string.default_server)
    is ServerSetting.Chosen -> setting.url
    ServerSetting.Unreadable -> null
}

/** Tries a job gets on a network that fails before it gives up on today. */
private const val DUE_TRIES = 3

private const val GUEST_TRIES = 30

/**
 * "Hoy vence…" (spec section 7.2): at 9:00 in the profile's zone, one notice for the recurring
 * payments still pending today, joined naturally ("Arriendo y Spotify"); none when there are none.
 * Then it schedules tomorrow's 9:00, unless the switch is off or the session is gone. It reads the
 * session where the app keeps it and only reads the server; the notification permission is the
 * app's to ask, in the app.
 */
class DueWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val context = applicationContext
        val dependencies = NoticeHooks.of(context)
        val settings = NoticeSettings(context)
        var zone = NoticeTimes.zoneOr(settings.zone, ZoneId.systemDefault())
        var outcome = "off"
        var keepGoing = true
        if (settings.dueEnabled) {
            val mark = dependencies.session.mark()
            if (mark == null) {
                outcome = "signed out"
            } else {
                val attempt = withContext(Dispatchers.IO) { attempt(context, dependencies, settings, mark, zone) }
                if (attempt == null) {
                    if (runAttemptCount < DUE_TRIES) return Result.retry()
                    outcome = "gave up"
                } else {
                    outcome = attempt.outcome
                    zone = attempt.zone
                    keepGoing = attempt.keepGoing
                }
            }
        }
        // Tomorrow's 9:00, as the last step: only while the switch is on and someone is signed in.
        if (keepGoing && settings.dueEnabled && dependencies.session.mark() != null) {
            NoticeScheduler.enqueueNextDue(context, zone, dependencies.clock())
        }
        return Result.success(workDataOf(OUTCOME to outcome))
    }

    private class Run(val outcome: String, val zone: ZoneId, val keepGoing: Boolean = true)

    /** A run's result; null when the network or the server failed (try again). */
    private fun attempt(
        context: Context,
        dependencies: NoticeDependencies,
        settings: NoticeSettings,
        mark: String,
        known: ZoneId,
    ): Run? {
        val server = serverOf(context, dependencies.session) ?: return Run("server unreadable", known)
        val token = dependencies.session.token() ?: return Run("token unreadable", known)
        val profile = when (val answer = dependencies.api.profile(server, token)) {
            is ApiResult.Ok -> answer.value
            ApiResult.Unauthorized -> return Run("session refused", known, keepGoing = false)
            ApiResult.Failed -> return null
        }
        val zone = NoticeTimes.zoneOr(profile.timezone, known)
        if (settings.zone != zone.id) settings.zone = zone.id
        val today = LocalDate.ofInstant(dependencies.clock(), zone)
        val names = when (val answer = dependencies.api.dueToday(server, token, today)) {
            is ApiResult.Ok -> answer.value
            ApiResult.Unauthorized -> return Run("session refused", zone, keepGoing = false)
            ApiResult.Failed -> return null
        }
        // Signed out, or the switch turned off, while the request was on its way: nothing is said.
        if (dependencies.session.mark() != mark || !settings.dueEnabled) return Run("dropped", zone)
        if (names.isEmpty()) return Run("nothing due today", zone)
        val posted = NoticePoster(context).postDue(names, settings.language)
        return Run(if (posted) "posted" else "not allowed", zone)
    }

    companion object {
        /** The output key of what a run did, for the logs and the tests. */
        const val OUTCOME = "outcome"
    }
}

/**
 * The guest warning (spec section 7.2): it fires 45 days after the app was last opened on a guest
 * account (the app replaces the job at every open). If the account is still a guest, it posts
 * "Tus datos se borrarán en 15 días si no agregas tu correo": the server deletes an inactive guest
 * at 60 days. It asks the server rather than trusting a flag that only the app updates.
 */
class GuestWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val context = applicationContext
        val dependencies = NoticeHooks.of(context)
        val settings = NoticeSettings(context)
        if (!settings.guestEnabled) return done("off")
        val mark = dependencies.session.mark() ?: return done("signed out")
        val outcome = withContext(Dispatchers.IO) {
            val server = serverOf(context, dependencies.session) ?: return@withContext "server unreadable"
            val token = dependencies.session.token() ?: return@withContext "token unreadable"
            val profile = when (val answer = dependencies.api.profile(server, token)) {
                is ApiResult.Ok -> answer.value
                ApiResult.Unauthorized -> return@withContext "session refused"
                // Not knowing is not a reason to say it: wait for a better moment.
                ApiResult.Failed -> return@withContext null
            }
            when {
                !profile.anonymous -> "has an email"
                dependencies.session.mark() != mark || !settings.guestEnabled -> "dropped"
                NoticePoster(context).postGuestWarning(settings.language) -> "posted"
                else -> "not allowed"
            }
        }
        if (outcome == null) return if (runAttemptCount < GUEST_TRIES) Result.retry() else done("gave up")
        return done(outcome)
    }

    private fun done(outcome: String) = Result.success(workDataOf(DueWorker.OUTCOME to outcome))
}
