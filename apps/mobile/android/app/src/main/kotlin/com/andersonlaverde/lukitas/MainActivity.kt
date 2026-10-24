package com.andersonlaverde.lukitas

import android.app.Notification
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Bundle
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.andersonlaverde.lukitas.files.FilesChannel
import com.andersonlaverde.lukitas.haptics.HapticsChannel
import com.andersonlaverde.lukitas.launch.LaunchLinks
import com.andersonlaverde.lukitas.notices.DueWorker
import com.andersonlaverde.lukitas.notices.GuestWorker
import com.andersonlaverde.lukitas.notices.NOTICE_OUTCOME
import com.andersonlaverde.lukitas.notices.NoticePoster
import com.andersonlaverde.lukitas.notices.NoticeSettings
import com.andersonlaverde.lukitas.notices.NoticesChannel
import com.andersonlaverde.lukitas.passkeys.PasskeyChannel
import com.andersonlaverde.lukitas.sounds.SoundChannel
import com.andersonlaverde.lukitas.voice.VoiceChannel
import com.andersonlaverde.lukitas.voice.VoiceModels
import com.andersonlaverde.lukitas.widget.RefreshScheduler
import com.andersonlaverde.lukitas.widget.RefreshWorker
import com.andersonlaverde.lukitas.widget.SecureStorageSession
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private var voice: VoiceChannel? = null
    private var haptics: HapticsChannel? = null
    private var sounds: SoundChannel? = null
    private var notices: NoticesChannel? = null
    private var files: FilesChannel? = null
    private var launch: MethodChannel? = null

    /** The widget's or the tile's `lukitas://` link, until Dart takes it (lib/launch/launch_links.dart). */
    private var pendingLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Taken before Flutter starts, so its router never sees it (it would read "lukitas://add"
        // as "/"). An activity recreated from saved state gets its first link again: not reopened.
        takeLink(intent, act = savedInstanceState == null)
        // The speech model Dart last asked to have loaded in advance (after a first capture) loads in
        // the background while Flutter starts, so 🎤 from the widget or the tile finds it ready.
        VoiceModels.warmFromHint(this)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        // The widget or the tile with the app already open: Dart is told and takes the link.
        if (takeLink(intent, act = true)) launch?.invokeMethod("linkArrived", null)
        super.onNewIntent(intent)
    }

    /**
     * Keeps [intent]'s `lukitas://` link for Dart (when [act]) and strips it from the intent. Flutter
     * reads an intent's data as a route to open, so nothing but the sign-in email's magic link may
     * stay on it ([LaunchLinks.routerMayRead]): a `lukitas://` link (taken here, or one that did not
     * come through the app's own entry and only opens the app), a web link for a host other than the
     * configured server's, and the `glance-action:/CALLBACK?...` Glance puts on a tap on the widget
     * itself are all stripped.
     */
    private fun takeLink(intent: Intent?, act: Boolean): Boolean {
        val link = LaunchLinks.linkOf(intent)
        if (intent?.data != null) {
            // The server's host is read (a decrypt) only for a web link, rarely: every other start
            // keeps the setting untouched.
            val host = if (LaunchLinks.isWebLink(intent) && intent.data?.scheme in setOf("http", "https")) {
                configuredServerHost()
            } else {
                null
            }
            if (!LaunchLinks.routerMayRead(intent, host)) intent.data = null
        }
        if (link == null || !act) return false
        pendingLink = link
        return true
    }

    /** The host of the server the app talks to (Settings, else the build's default); null when unreadable. */
    private fun configuredServerHost(): String? =
        LaunchLinks.serverHost(SecureStorageSession(this).server(), getString(R.string.default_server))

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // The widget's ＋ and 🎤 and the Quick Settings tile (launch/LaunchLinks.kt).
        launch = MethodChannel(messenger, "lukitas/launch").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "take" -> {
                        result.success(pendingLink)
                        pendingLink = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // The widget's refresh job runs while a widget is on the home screen; scheduling it again
        // keeps what is there (the first widget added schedules it too).
        if (RefreshScheduler.hasWidgets(this)) RefreshScheduler.schedule(this)

        PasskeyChannel(this, messenger)
        // Quick capture: the microphone and the on-phone speech engine (voice/VoiceChannel.kt).
        voice = VoiceChannel(this, messenger)

        // Feel (lib/feedback): the motor (haptics/HapticsChannel.kt) and a SoundPool for the web's
        // tiny sounds (sounds/SoundChannel.kt).
        haptics = HapticsChannel(this, messenger)
        sounds = SoundChannel(this, messenger)

        // The two local notices (lib/notices): scheduling them, and the notification permission.
        notices = NoticesChannel(this, messenger)

        // Files in and out (lib/files): the document picker and the share sheet, no storage permission.
        files = FilesChannel(this, messenger)

        // The phone's IANA time zone (lib/api/device.dart): Dart only knows its abbreviation. And
        // the browser, for "Más en la web".
        MethodChannel(messenger, "lukitas/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "timeZone" -> result.success(ZoneId.systemDefault().id)
                // "Más en la web" (lib/settings/url_opener.dart): the address in the phone's
                // browser, as any link does. True when a browser took it.
                "openUrl" -> result.success(openInBrowser(call.arguments as? String))
                else -> result.notImplemented()
            }
        }

        // Debuggable builds only: the integration tests open a link in this app as Android
        // delivers an App Link (an ACTION_VIEW intent), to test the manifest's filter and routing.
        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            MethodChannel(messenger, "lukitas/test").setMethodCallHandler { call, result ->
                when (call.method) {
                    "openLink" -> {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(call.arguments as String))
                            .addCategory(Intent.CATEGORY_BROWSABLE)
                            .setPackage(packageName)
                        startActivity(intent)
                        result.success(null)
                    }
                    // What a browser does with the web page's "Abrir en Lukitas": it parses the
                    // `intent://` address and starts the intent as a browsable view, with no
                    // component of its own, so Android resolves it through the manifest's filters.
                    "openIntentUri" -> {
                        val intent = Intent.parseUri(call.arguments as String, Intent.URI_INTENT_SCHEME)
                            .addCategory(Intent.CATEGORY_BROWSABLE)
                        intent.component = null
                        intent.selector = null
                        startActivity(intent)
                        result.success(null)
                    }
                    // What the widget's ＋ ("add"), 🎤 ("capture") and body ("home") start, exactly.
                    "openWidgetButton" -> {
                        val link = when (call.arguments) {
                            "add" -> LaunchLinks.ADD
                            "home" -> LaunchLinks.HOME
                            else -> LaunchLinks.CAPTURE
                        }
                        startActivity(LaunchLinks.intent(this, link))
                        result.success(null)
                    }
                    // What the widget's body started before it was a link (the shape Glance's own
                    // `actionStartActivity<MainActivity>()` gave it, logged by the emulator): this
                    // activity, `glance-action:/CALLBACK?...` as data and no action. Flutter's
                    // router read it as a route and showed "Page Not Found" with the app running.
                    "openGlanceTap" -> {
                        startActivity(
                            Intent()
                                .setClass(this, MainActivity::class.java)
                                .setData(
                                    Uri.parse(
                                        "glance-action:/CALLBACK?appWidgetId=5&viewId=2131296449" +
                                            "&viewSize=110.09524.dp%20x%2040.0.dp&extraData=0",
                                    ),
                                )
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    }
                    // What another app can do: the exported launcher activity, explicitly, on a link.
                    "openOnLauncherActivity" -> {
                        startActivity(
                            Intent(Intent.ACTION_VIEW, Uri.parse(call.arguments as String))
                                .setClass(this, MainActivity::class.java),
                        )
                        result.success(null)
                    }
                    // Every SharedPreferences file flutter_secure_storage uses, as stored.
                    "secureStorageFiles" -> result.success(
                        listOf(
                            "FlutterSecureStorage",
                            "FlutterSecureKeyStorage",
                            "FlutterSecureStorageConfiguration:FlutterSecureStorage",
                        ).associateWith { name ->
                            getSharedPreferences(name, MODE_PRIVATE).all.mapValues { it.value.toString() }
                        },
                    )
                    // Changes one byte of the stored session token's ciphertext (a decrypt failure).
                    "corruptStoredToken" -> {
                        val prefs = getSharedPreferences("FlutterSecureStorage", MODE_PRIVATE)
                        val key = prefs.all.keys.single { it.endsWith("_session.token") }
                        val bytes = android.util.Base64.decode(prefs.getString(key, null), 0)
                        bytes[bytes.size / 2] = (bytes[bytes.size / 2].toInt() xor 0x5A).toByte()
                        prefs.edit().putString(key, android.util.Base64.encodeToString(bytes, 0)).commit()
                        result.success(null)
                    }
                    // Runs the widget's refresh job once through WorkManager and answers what it
                    // did (RefreshWorker's outcome), or its final state when it did not succeed.
                    "refreshWidget" -> runOnce(OneTimeWorkRequestBuilder<RefreshWorker>().build(), RefreshWorker.OUTCOME, result)
                    // The same for the two notices' jobs (notices/NoticeWorkers.kt), as they run at
                    // 9:00 and 45 days on; they post only when the person allowed notifications.
                    "runDueNotice" -> runOnce(OneTimeWorkRequestBuilder<DueWorker>().build(), NOTICE_OUTCOME, result)
                    "runGuestNotice" -> runOnce(OneTimeWorkRequestBuilder<GuestWorker>().build(), NOTICE_OUTCOME, result)
                    // Whether "Hoy vence…" is scheduled: the switch the app sets when it schedules the
                    // job and clears when it cancels it (NoticeScheduler).
                    "dueScheduled" -> result.success(NoticeSettings(this).dueEnabled)
                    // The text of each notice this app has on the shade.
                    "activeNotices" -> result.success(
                        getSystemService(NotificationManager::class.java).activeNotifications.map {
                            it.notification.extras.getString(Notification.EXTRA_TEXT)
                        },
                    )
                    // Taps the "Hoy vence…" notice: sends the very PendingIntent the shade would.
                    "tapDueNotice" -> {
                        val notice = getSystemService(NotificationManager::class.java).activeNotifications
                            .firstOrNull { it.id == NoticePoster.DUE_ID }
                        notice?.notification?.contentIntent?.send()
                        result.success(notice != null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** Runs [request] once through WorkManager and answers its [outputKey] result, or its final
     *  state when it did not succeed (debuggable builds' test channel only). */
    private fun runOnce(request: OneTimeWorkRequest, outputKey: String, result: MethodChannel.Result) {
        val workManager = WorkManager.getInstance(this)
        workManager.enqueue(request)
        thread {
            var done: WorkInfo? = workManager.getWorkInfoById(request.id).get()
            var waited = 0
            while (done?.state?.isFinished != true && waited < 30_000) {
                Thread.sleep(100)
                waited += 100
                done = workManager.getWorkInfoById(request.id).get()
            }
            val answer = if (done?.state == WorkInfo.State.SUCCEEDED) {
                done.outputData.getString(outputKey)
            } else {
                "state ${done?.state}"
            }
            runOnUiThread { result.success(answer) }
        }
    }

    /** Opens an http or https [address] with `ACTION_VIEW`; false when it is neither or no app
     *  takes it. Nothing else is ever opened from a string Dart sends. */
    private fun openInBrowser(address: String?): Boolean {
        val uri = address?.let { Uri.parse(it) } ?: return false
        if (uri.scheme != "https" && uri.scheme != "http") return false
        return try {
            startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    override fun onStop() {
        // In the background the microphone is let go at once; Dart also cancels listening.
        voice?.stopRecording()
        super.onStop()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // The engine goes away (the activity is destroyed): no Dart is left to stop a recording.
        voice?.dispose()
        voice = null
        haptics?.dispose()
        haptics = null
        sounds?.dispose()
        sounds = null
        notices?.dispose()
        notices = null
        files?.dispose()
        files = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        voice?.dispose()
        voice = null
        super.onDestroy()
    }

    @Deprecated("The platform's result callback; FlutterActivity has no ActivityResult API to use instead")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        // The document picker's answer (files/FilesChannel.kt); anything else is Flutter's or a plugin's.
        if (files?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (voice?.onPermissionResult(requestCode, grantResults) == true) return
        if (notices?.onPermissionResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
