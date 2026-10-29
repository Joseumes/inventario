plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.inventario"
    // SDK 36: requerido por flutter_plugin_android_lifecycle, image_picker
    // y shared_preferences (son retrocompatibles).
    compileSdk = 36

    // NDK más alto requerido por los plugins (jni pide 28.2).
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.inventario"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    // 👇 Opcional pero evita problemas con AndroidX recientes
    implementation("androidx.activity:activity:1.10.1")
    implementation("androidx.activity:activity-ktx:1.10.1")
}