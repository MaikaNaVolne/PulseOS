plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pulseos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // В Kotlin DSL свойство называется isCoreLibraryDesugaringEnabled
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Старый синтаксис jvmTarget работает, но лучше так, чтобы без варнингов:
        jvmTarget = "1.8" 
    }

    defaultConfig {
        applicationId = "com.example.pulseos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // В Kotlin DSL обязательно использовать двойные кавычки и скобки
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}