import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "de.joancode.schnell_verkauf"
    // Updated to satisfy plugin requirements (camera_android & google_mobile_ads)
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "de.joancode.schnell_verkauf" // Ensure you control this reverse domain before first release
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // Explicit target for Play compliance (update when policy changes)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Load keystore properties (if present) before defining signingConfigs
    val keystoreProps = Properties()
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        keystoreFile.inputStream().use { keystoreProps.load(it) }
    }

    signingConfigs {
        // Create release config only when key.properties exists
        if (keystoreFile.exists()) {
            create("release") {
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use real release key if available; fall back to debug for local convenience only.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            // Keep Flutter + plugin entry points; default rules usually suffice. Add custom rules if reflection-heavy code breaks.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Faster builds; keep defaults.
        }
    }
}

flutter {
    source = "../.."
}
