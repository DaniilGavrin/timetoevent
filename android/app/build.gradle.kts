import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bytewizard.timetoevent"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.bytewizard.timetoevent"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        getByName("debug") {
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            storeFile = file("debug.keystore")
            storePassword = "android"
        }

        create("release") {
            keyAlias = "ByteWizard"
            keyPassword = "090807Dan4ik@"
            storeFile = file("key.jks")
            storePassword = "090807Dan4ik@"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("release") // или "release", если хочешь использовать релизный
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.22"))
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}

flutter {
    source = "../.."
}
