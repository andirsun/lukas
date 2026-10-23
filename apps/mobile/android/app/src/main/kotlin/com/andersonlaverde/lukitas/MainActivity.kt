package com.andersonlaverde.lukitas

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Bundle
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.andersonlaverde.lukitas.haptics.HapticsChannel
import com.andersonlaverde.lukitas.launch.LaunchLinks
import com.andersonlaverde.lukitas.passkeys.PasskeyChannel
import com.andersonlaverde.lukitas.sounds.SoundChannel
import com.andersonlaverde.lukitas.voice.VoiceChannel
import com.andersonlaverde.lukitas.widget.RefreshScheduler
import com.andersonlaverde.lukitas.widget.RefreshWorker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private var voice: VoiceChannel? = null
    private var haptics: HapticsChannel? = null
    private var sounds: SoundChannel? = null
    private var launch: MethodChannel? = null

    /** The widget's or the tile's `lukitas://` link, until Dart takes it (lib/launch/launch_links.dart). */
    private var pendingLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Taken before Flutter starts, so its router never sees it (it would read "lukitas://add"
        // as "/"). An activity recreated from saved state gets its first link again: not reopened.
        takeLink(intent, act = savedInstanceState == null)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        // The widget or the tile with the app already open: Dart is told and takes the link.
        if (takeLink(intent, act = true)) launch?.invokeMethod("linkArrived", null)
        super.onNewIntent(intent)
    }

    /** Keeps [intent]'s `lukitas://` link for Dart (when [act]) and strips it from the intent. */
    private fun takeLink(intent: Intent?, act: Boolean): Boolean {
        val link = LaunchLinks.linkOf(intent) ?: return false
        intent?.data = null
        if (act) pendingLink = link
        return act
    }

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
                    // What the widget's ＋ ("add") and 🎤 ("capture") start, exactly.
                    "openWidgetButton" -> {
                        val link = if (call.arguments == "add") LaunchLinks.ADD else LaunchLinks.CAPTURE
                        startActivity(LaunchLinks.intent(this, link))
                        result.success(null)
                    }
                    // Runs the widget's refresh job once through WorkManager and answers what it
                    // did (RefreshWorker's outcome), or its final state when it did not succeed.
                    "refreshWidget" -> {
                        val request = OneTimeWorkRequestBuilder<RefreshWorker>().build()
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
                                done.outputData.getString(RefreshWorker.OUTCOME)
                            } else {
                                "state ${done?.state}"
                            }
                            runOnUiThread { result.success(answer) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
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
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        voice?.dispose()
        voice = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (voice?.onPermissionResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
