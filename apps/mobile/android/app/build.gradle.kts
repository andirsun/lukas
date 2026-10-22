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
