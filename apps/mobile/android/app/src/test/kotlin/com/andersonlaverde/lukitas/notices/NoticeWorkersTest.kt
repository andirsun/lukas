package com.andersonlaverde.lukitas.notices

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.testing.WorkManagerTestInitHelper
import com.andersonlaverde.lukitas.widget.ServerSetting
import com.andersonlaverde.lukitas.widget.SessionSource
import com.andersonlaverde.lukitas.widget.TinyHttpServer
import com.andersonlaverde.lukitas.widget.TinyRequest
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.Duration
import java.time.Instant

/** A stored session in memory, which the test can sign out. */
private class FakeSession(var stored: String?, var serverUrl: String?) : SessionSource {
    var serverUnreadable = false

    override fun token(): String? = stored
    override fun mark(): String? = stored?.let { "mark:$it" }
    override fun server(): ServerSetting = when {
        serverUnreadable -> ServerSetting.Unreadable
        serverUrl == null -> ServerSetting.Default
        else -> ServerSetting.Chosen(serverUrl!!)
    }
}

@RunWith(RobolectricTestRunner::class)
class NoticeWorkersTest {
    private val context: Context = ApplicationProvider.getApplicationContext()

    /** 09:00 in Bogota on Thursday the 22nd. */
    private var now = Instant.parse("2026-10-22T14:00:00Z")
    private lateinit var server: TinyHttpServer
    private val requests = mutableListOf<TinyRequest>()
    private lateinit var session: FakeSession
    private lateinit var settings: NoticeSettings

    private var meStatus = 200
    private var anonymous = false
    private var timezone = "America/Bogota"

    /** Pages of the pending list by cursor ("" is the first page). */
    private val pages = mutableMapOf<String, String>()
    private var transactionsStatus = 200

    /** Called while the server holds the answer (a request in flight). */
    private var whileAnswering: (() -> Unit)? = null

    private fun me() = """
        {"id":"u1","email":"a@b.c","timezone":"$timezone","locale":"es","onboardingCompletedAt":null,
         "currency":"COP","isAnonymous":$anonymous}
    """.trimIndent()

    private fun item(
        name: String,
        date: String,
        recurrence: String? = "r-$name",
        createdAt: String = "2026-10-01T10:00:00.000Z",
        status: String = "pending",
    ) = """
        {"id":"t-$name","name":"$name","amount":1500000,"currency":"COP","date":"$date","status":"$status",
         "note":null,"categoryId":"c1","recurrenceId":${recurrence?.let { "\"$it\"" } ?: "null"},
         "importId":null,"source":"app","createdAt":"$createdAt","updatedAt":"$createdAt"}
    """.trimIndent()

    private fun page(vararg items: String, next: String? = null) =
        """{"items":[${items.joinToString(",")}],"nextCursor":${next?.let { "\"$it\"" } ?: "null"}}"""

    @Before
    fun setUp() {
        WorkManagerTestInitHelper.initializeTestWorkManager(context)
        server = TinyHttpServer { request ->
            requests += request
            whileAnswering?.invoke()
            when (request.path.removePrefix("/lukitas")) {
                "/api/v1/me" -> meStatus to me()
                "/api/v1/transactions" -> {
                    val cursor = Regex("cursor=([^&]*)").find(request.query)?.groupValues?.get(1) ?: ""
                    transactionsStatus to (pages[cursor] ?: page())
                }
                else -> 404 to "{}"
            }
        }
        session = FakeSession("token-1", "http://127.0.0.1:${server.port}")
        settings = NoticeSettings(context).also {
            it.dueEnabled = true
            it.guestEnabled = true
            it.language = "es"
        }
        NoticeHooks.dependencies = { NoticeDependencies(session = session, clock = { now }) }
    }

    @After
    fun tearDown() {
        NoticeHooks.dependencies = null
        server.stop()
        settings.clear()
        notifications().cancelAll()
    }

    private fun notifications() = context.getSystemService(NotificationManager::class.java)

    private fun posted(): List<Notification> = shadowOf(notifications()).allNotifications

    private fun text(notification: Notification) = notification.extras.getString(Notification.EXTRA_TEXT)

    private fun runDue(attempt: Int = 0): ListenableWorker.Result = runBlocking {
        TestListenableWorkerBuilder<DueWorker>(context).setRunAttemptCount(attempt).build().doWork()
    }

    private fun runGuest(attempt: Int = 0): ListenableWorker.Result = runBlocking {
        TestListenableWorkerBuilder<GuestWorker>(context).setRunAttemptCount(attempt).build().doWork()
    }

    private fun work(name: String) = WorkManager.getInstance(context).getWorkInfosForUniqueWork(name).get()

    private fun enqueued(name: String) = work(name).filter { it.state == WorkInfo.State.ENQUEUED }

    // --- "Hoy vence…" -------------------------------------------------------------------------

    @Test
    fun `at 9 one notice groups today's pending recurring payments`() {
        pages[""] = page(
            item("Spotify", "2026-10-22", createdAt = "2026-10-02T10:00:00.000Z"),
            item("Arriendo", "2026-10-22", createdAt = "2026-10-01T10:00:00.000Z"),
            // A pending movement that is not recurring, another day's payments: not announced.
            item("Café", "2026-10-22", recurrence = null),
            item("Gimnasio", "2026-10-23"),
            item("Seguro", "2026-10-21"),
        )

        assertEquals(ListenableWorker.Result.success().javaClass, runDue().javaClass)

        val notice = posted().single()
        assertEquals("Hoy vencen Arriendo y Spotify", text(notice))
        // The sentence is also what the expanded notice reads.
        assertEquals("Hoy vencen Arriendo y Spotify", notice.extras.getCharSequence(Notification.EXTRA_BIG_TEXT).toString())
    }

    @Test
    fun `the payments are asked of the API with the stored session, pending, this month, at most 200`() {
        pages[""] = page(item("Arriendo", "2026-10-22"))
        runDue()

        assertEquals(listOf("/api/v1/me", "/api/v1/transactions"), requests.map { it.path })
        val query = requests[1].query.split("&").toSet()
        assertTrue(query.toString(), "status=pending" in query)
        assertTrue(query.toString(), "month=2026-10" in query)
        assertTrue(query.toString(), "limit=200" in query)
    }

    @Test
    fun `no pending payment today means no notice, and tomorrow's 9 is still scheduled`() {
        pages[""] = page(item("Gimnasio", "2026-10-23"), item("Café", "2026-10-22", recurrence = null))
        runDue()

        assertTrue(posted().isEmpty())
        val next = enqueued(NoticeScheduler.DUE).single()
        assertEquals(Duration.ofHours(24).toMillis(), next.initialDelayMillis)
    }

    @Test
    fun `an empty list means no notice`() {
        runDue()
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `today is the day in the profile's zone, never the phone's or UTC`() {
        // 03:00 UTC on the 23rd is still the 22nd in Bogota.
        now = Instant.parse("2026-10-23T03:00:00Z")
        pages[""] = page(item("Arriendo", "2026-10-22"), item("Gimnasio", "2026-10-23"))
        runDue()
        assertEquals("Hoy vence Arriendo", text(posted().single()))

        // 02:00 UTC on 1 November is still 31 October: the month asked is October's.
        notifications().cancelAll()
        requests.clear()
        now = Instant.parse("2026-11-01T02:00:00Z")
        pages[""] = page(item("Luz", "2026-10-31"))
        runDue()
        assertTrue("month=2026-10" in requests[1].query.split("&"))
        assertEquals("Hoy vence Luz", text(posted().single()))
    }

    @Test
    fun `every page is read until the list is older than today`() {
        pages[""] = page(item("Arriendo", "2026-10-22"), next = "p2")
        pages["p2"] = page(item("Spotify", "2026-10-22"), item("Luz", "2026-10-20"), next = "p3")
        pages["p3"] = page(item("Agua", "2026-10-02"))
        runDue()

        assertEquals("Hoy vencen Arriendo y Spotify", text(posted().single()))
        // The third page is never asked: the second one already reached older days.
        assertEquals(3, requests.size)
        assertTrue("cursor=p2" in requests[2].query.split("&"))
    }

    @Test
    fun `the next run is 9 tomorrow in the zone the profile says, which is remembered`() {
        timezone = "Asia/Tokyo"
        // 14:00 UTC is 23:00 in Tokyo; the next 9:00 there is 10 hours away.
        runDue()
        assertEquals(Duration.ofHours(10).toMillis(), enqueued(NoticeScheduler.DUE).single().initialDelayMillis)
        assertEquals("Asia/Tokyo", settings.zone)
    }

    @Test
    fun `the switch in settings stops it`() {
        settings.dueEnabled = false
        pages[""] = page(item("Arriendo", "2026-10-22"))
        runDue()

        assertTrue(posted().isEmpty())
        assertTrue("nothing is asked of the server", requests.isEmpty())
        assertTrue("and it is not scheduled again", work(NoticeScheduler.DUE).none { !it.state.isFinished })
    }

    @Test
    fun `signed out, nothing is asked, posted or scheduled again`() {
        session.stored = null
        runDue()
        assertTrue(requests.isEmpty())
        assertTrue(posted().isEmpty())
        assertTrue(work(NoticeScheduler.DUE).none { !it.state.isFinished })
    }

    @Test
    fun `a session the server no longer knows posts nothing and stops`() {
        meStatus = 401
        runDue()
        assertTrue(posted().isEmpty())
        assertTrue(work(NoticeScheduler.DUE).none { !it.state.isFinished })
    }

    @Test
    fun `a server setting that cannot be read sends nothing, never the token to the default server`() {
        session.serverUnreadable = true
        runDue()
        assertTrue(requests.isEmpty())
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `the server chosen in Settings is used, with any path it has`() {
        session.serverUrl = "http://127.0.0.1:${server.port}/lukitas/"
        pages[""] = page(item("Arriendo", "2026-10-22"))
        runDue()
        assertEquals(listOf("/lukitas/api/v1/me", "/lukitas/api/v1/transactions"), requests.map { it.path })
        assertEquals("Hoy vence Arriendo", text(posted().single()))
    }

    @Test
    fun `offline or a server error tries again later, and gives up after a few tries until tomorrow`() {
        transactionsStatus = 500
        pages[""] = page(item("Arriendo", "2026-10-22"))

        assertEquals(ListenableWorker.Result.retry(), runDue(attempt = 0))
        assertTrue(posted().isEmpty())
        assertTrue("a retry is not a new day's job", enqueued(NoticeScheduler.DUE).isEmpty())

        assertEquals(ListenableWorker.Result.retry(), runDue(attempt = 2))
        // The fourth try gives up on today and keeps tomorrow.
        runDue(attempt = 3)
        assertTrue(posted().isEmpty())
        assertEquals(1, enqueued(NoticeScheduler.DUE).size)
    }

    @Test
    fun `a sign-out while the request is on its way drops what it fetched`() {
        pages[""] = page(item("Arriendo", "2026-10-22"))
        whileAnswering = { session.stored = null }
        runDue()
        assertTrue(posted().isEmpty())
        assertTrue(work(NoticeScheduler.DUE).none { !it.state.isFinished })
    }

    @Test
    fun `the switch turned off while the request is on its way drops it too`() {
        pages[""] = page(item("Arriendo", "2026-10-22"))
        whileAnswering = { settings.dueEnabled = false }
        runDue()
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `without the notification permission nothing is posted, and nothing is asked of the person`() {
        shadowOf(notifications()).setNotificationsEnabled(false)
        pages[""] = page(item("Arriendo", "2026-10-22"))
        runDue()
        assertTrue(posted().isEmpty())
        assertEquals("tomorrow is still scheduled", 1, enqueued(NoticeScheduler.DUE).size)
    }

    @Test
    fun `tapping it opens home through the app's own link entry`() {
        pages[""] = page(item("Arriendo", "2026-10-22"))
        runDue()
        val tap = shadowOf(posted().single().contentIntent).savedIntent
        assertEquals("lukitas://due", tap.dataString)
        // The same not-exported alias the widget uses: no other app can start it.
        assertEquals("com.andersonlaverde.lukitas.LaunchLinkAlias", tap.component?.className)
        assertTrue(posted().single().flags and Notification.FLAG_AUTO_CANCEL != 0)
    }

    @Test
    fun `each notice has its own channel, named in the phone's language`() {
        pages[""] = page(item("Arriendo", "2026-10-22"))
        runDue()
        anonymous = true
        runGuest()
        val channels = notifications().notificationChannels.associate { it.id to it.name.toString() }
        assertEquals(setOf(NoticeChannels.DUE, NoticeChannels.GUEST), channels.keys)
        assertEquals(2, channels.values.toSet().size)
        assertEquals(NoticeChannels.DUE, posted().first { text(it)!!.startsWith("Hoy vence") }.channelId)
        assertEquals(NoticeChannels.GUEST, posted().first { text(it)!!.startsWith("Tus datos") }.channelId)
    }

    // --- The guest warning ---------------------------------------------------------------------

    @Test
    fun `a guest not opening the app for 45 days gets the warning`() {
        anonymous = true
        runGuest()
        val notice = posted().single()
        assertEquals("Tus datos se borrarán en 15 días si no agregas tu correo", text(notice))
        assertEquals(listOf("/api/v1/me"), requests.map { it.path })
        assertEquals("Bearer token-1", requests[0].headers["authorization"])
    }

    @Test
    fun `an account that has an email by then gets nothing`() {
        anonymous = false
        runGuest()
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `signed out or unknown to the server, the guest warning is not posted`() {
        session.stored = null
        runGuest()
        assertTrue(requests.isEmpty())
        assertTrue(posted().isEmpty())

        session.stored = "token-1"
        anonymous = true
        meStatus = 401
        runGuest()
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `the guest switch off, nothing is posted`() {
        settings.guestEnabled = false
        anonymous = true
        runGuest()
        assertTrue(posted().isEmpty())
        assertTrue(requests.isEmpty())
    }

    @Test
    fun `offline the warning waits for a network, and never guesses`() {
        anonymous = true
        meStatus = 503
        assertEquals(ListenableWorker.Result.retry(), runGuest(attempt = 1))
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `a sign-out during the check drops the warning`() {
        anonymous = true
        whileAnswering = { session.stored = null }
        runGuest()
        assertTrue(posted().isEmpty())
    }

    @Test
    fun `the guest warning opens the app, and is not announced twice`() {
        anonymous = true
        runGuest()
        runGuest()
        val notice = posted().single()
        val tap = shadowOf(notice.contentIntent).savedIntent
        assertNull(tap.data)
        assertNotNull(tap.component ?: tap.`package`)
    }

    @Test
    fun `a guest account with the permission refused posts nothing`() {
        shadowOf(notifications()).setNotificationsEnabled(false)
        anonymous = true
        runGuest()
        assertTrue(posted().isEmpty())
    }
}
