plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.track_site_pro_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.track_site_pro_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Disable minify/shrink for faster builds (APK will be larger)
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Avoid file-lock failures on Windows (lint cache) and speed up release builds
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

// Build only arm64 for much faster APK (runs after Flutter plugin sets defaults)
afterEvaluate {
    android.defaultConfig.ndk.abiFilters.clear()
    android.defaultConfig.ndk.abiFilters.addAll(listOf("arm64-v8a"))
}
