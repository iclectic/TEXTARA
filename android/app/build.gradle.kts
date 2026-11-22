plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.textara.textara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.textara.textara"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Store release builds must use a release keystore (see
            // docs/release/release-signing.md). Debug signing remains only so
            // local `flutter run --release` works before a keystore is configured.
            // CI / Play upload: set TEXTARA_UPLOAD_STORE_FILE and related env vars.
            val uploadStoreFile = System.getenv("TEXTARA_UPLOAD_STORE_FILE")
            if (uploadStoreFile != null) {
                signingConfigs.create("release") {
                    storeFile = file(uploadStoreFile)
                    storePassword = System.getenv("TEXTARA_UPLOAD_STORE_PASSWORD")
                    keyAlias = System.getenv("TEXTARA_UPLOAD_KEY_ALIAS")
                    keyPassword = System.getenv("TEXTARA_UPLOAD_KEY_PASSWORD")
                }
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
