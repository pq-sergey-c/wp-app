import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    kotlin("plugin.serialization")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.8.1")
    implementation("androidx.media:media:1.7.0")
    implementation("androidx.core:core-ktx:1.16.0")
}

android {
    namespace = "com.wavepaths.player"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Was: flutter.ndkVersion // TODO: fix flutter.ndkVersion error

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.wavepaths.player"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    externalNativeBuild {
        cmake {
            path = file("../../native_library/CMakeLists.txt")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64", "x86")
            }
        }
    }
}

flutter {
    source = "../.."
}
