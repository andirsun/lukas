package com.andersonlaverde.lukitas

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import com.andersonlaverde.lukitas.passkeys.PasskeyChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        PasskeyChannel(this, messenger)

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
}
