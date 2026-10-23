import java.util.Base64

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The values a build was given with --dart-define (Flutter hands them to Gradle base64-encoded).
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { encoded ->
            runCatching { String(Base64.getDecoder().decode(encoded)) }.getOrNull()
        }
        ?.mapNotNull { pair ->
            pair.split("=", limit = 2).takeIf { it.size == 2 }?.let { it[0] to it[1] }
        }
        ?.toMap()
        ?: emptyMap()

android {
    namespace = "com.andersonlaverde.lukitas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.andersonlaverde.lukitas"
        // Android 8 (API 26) or newer (spec section 6.3).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // From pubspec.yaml's version; release builds set them from the mobile-v* tag.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // The server the widget's refresh job (widget/RefreshWorker.kt) asks when the person chose
        // none in Settings: the app's own default (lib/api/server_address.dart), which a build can
        // point elsewhere with --dart-define=LUKITAS_SERVER=... (the dev stack, from the emulator).
        resValue(
            "string",
            "default_server",
            dartDefines["LUKITAS_SERVER"] ?: "https://app-lukas.andersonlaverde.com",
        )

        ndk {
            // Phones only: 64- and 32-bit ARM. The Flutter Gradle plugin, applied above, has just
            // set its own list (x86_64 included), so it is replaced rather than added to.
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    buildFeatures {
        resValues = true
    }

    testOptions {
        // Robolectric (the widget's rendering tests, the refresh job's) reads the app's resources.
        unitTests.isIncludeAndroidResources = true
    }

    buildTypes {
        release {
            // The release signing key lives only on the founder's Mac (scripts/release.sh, later).
            // Until then a local release build is signed with the debug key, so it still installs.
            signingConfig = signingConfigs.getByName("debug")
            // Vosk reaches its native library through JNA, by reflection: R8 must keep both.
            proguardFiles("proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Robolectric's resources (testOptions above) are packaged from the merged assets, which the Flutter
// plugin's copy task also writes: the unit tests wait for it.
tasks.configureEach {
    if (name.startsWith("package") && name.endsWith("UnitTestForUnitTest")) {
        val variant = name.removePrefix("package").removeSuffix("UnitTestForUnitTest")
        dependsOn("copyFlutterAssets$variant")
    }
}

dependencies {
    // Passkeys through the platform's Credential Manager (Android 14+), never through the
    // library's Play Services bridge, which scripts/check-no-google.sh refuses.
    implementation("androidx.credentials:credentials:1.6.0")
    // Quick capture's speech engine, on the phone with no network (the voice spike's choice,
    // docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md). Apache-2.0; it brings JNA 5.18.1
    // (Apache-2.0 / LGPL-2.1). Never Android's SpeechRecognizer, which hands the audio to the
    // phone's recognition service (Google's, mostly).
    implementation("com.alphacephei:vosk-android:0.3.75")
    // The home-screen widget (widget/), drawn with Jetpack Glance, and its refresh job on
    // WorkManager (spec section 7.1). Both AndroidX, Apache-2.0, no Play Services; home_widget
    // already brings these exact versions, they are named here because the app's own code uses them.
    implementation("androidx.glance:glance-appwidget:1.2.0")
    implementation("androidx.work:work-runtime-ktx:2.11.2")

    // JVM unit tests (src/test): the voice model unzip, the haptics, and the widget. EPL-1.0, tests only.
    testImplementation("junit:junit:4.13.2")
    // Tests only, never in the APK: Android on the JVM (MIT), Glance's rendering tests and
    // WorkManager's test helpers (Apache-2.0).
    testImplementation("org.robolectric:robolectric:4.16.1")
    testImplementation("androidx.test:core:1.7.0")
    testImplementation("androidx.glance:glance-appwidget-testing:1.2.0")
    testImplementation("androidx.work:work-testing:2.11.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.2")
}
