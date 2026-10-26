plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.messmax.net.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.messmax.net.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // CI (GitHub Actions) provides these via env vars.
            // Local builds fall back to android/key.properties.
            val envStoreFile = System.getenv("KEYSTORE_FILE")
                ?: System.getenv("ANDROID_KEYSTORE_FILE")
            keyAlias = System.getenv("KEY_ALIAS")
                ?: keystoreProperties["keyAlias"] as String?
            keyPassword = System.getenv("KEY_PASSWORD")
                ?: keystoreProperties["keyPassword"] as String?
            storePassword = System.getenv("KEYSTORE_PASSWORD")
                ?: System.getenv("STORE_PASSWORD")
                ?: keystoreProperties["storePassword"] as String?
            storeFile = when {
                !envStoreFile.isNullOrBlank() -> file(envStoreFile)
                keystoreProperties["storeFile"] != null ->
                    file(keystoreProperties["storeFile"] as String)
                else -> null
            }
        }
    }

    buildTypes {
        release {
            // Use release signing when a key is available via CI env vars
            // or local key.properties; otherwise fall back to debug so
            // local debug builds don't break.
            val hasReleaseKey = keystorePropertiesFile.exists() ||
                !System.getenv("KEYSTORE_FILE").isNullOrBlank() ||
                !System.getenv("ANDROID_KEYSTORE_FILE").isNullOrBlank()
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
