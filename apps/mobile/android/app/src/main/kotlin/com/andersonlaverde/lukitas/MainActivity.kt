package com.andersonlaverde.lukitas

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import com.andersonlaverde.lukitas.haptics.HapticsChannel
import com.andersonlaverde.lukitas.passkeys.PasskeyChannel
import com.andersonlaverde.lukitas.sounds.SoundChannel
import com.andersonlaverde.lukitas.voice.VoiceChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId

class MainActivity : FlutterActivity() {
    private var voice: VoiceChannel? = null
    private var haptics: HapticsChannel? = null
    private var sounds: SoundChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        PasskeyChannel(this, messenger)
        // Quick capture: the microphone and the on-phone speech engine (voice/VoiceChannel.kt).
        voice = VoiceChannel(this, messenger)

        // Feel (lib/feedback): the motor (haptics/HapticsChannel.kt) and a SoundPool for the web's
        // tiny sounds (sounds/SoundChannel.kt).
        haptics = HapticsChannel(this, messenger)
        sounds = SoundChannel(this, messenger)

        // The phone's IANA time zone (lib/api/device.dart): Dart only knows its abbreviation.
        MethodChannel(messenger, "lukitas/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "timeZone" -> result.success(ZoneId.systemDefault().id)
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
                    else -> result.notImplemented()
                }
            }
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
