plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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

        ndk {
            // Phones only: 64- and 32-bit ARM. The Flutter Gradle plugin, applied above, has just
            // set its own list (x86_64 included), so it is replaced rather than added to.
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
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

dependencies {
    // Passkeys through the platform's Credential Manager (Android 14+), never through the
    // library's Play Services bridge, which scripts/check-no-google.sh refuses.
    implementation("androidx.credentials:credentials:1.6.0")
    // Quick capture's speech engine, on the phone with no network (the voice spike's choice,
    // docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md). Apache-2.0; it brings JNA 5.18.1
    // (Apache-2.0 / LGPL-2.1). Never Android's SpeechRecognizer, which hands the audio to the
    // phone's recognition service (Google's, mostly).
    implementation("com.alphacephei:vosk-android:0.3.75")
    // JVM unit tests of plain Kotlin (src/test): the voice model unzip. EPL-1.0, tests only.
    testImplementation("junit:junit:4.13.2")
}
