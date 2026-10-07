plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.crm.business"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.crm.business"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            val storeFilePath = System.getenv("ANDROID_KEYSTORE_PATH")
            val storePasswordEnv = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            val keyAliasEnv = System.getenv("ANDROID_KEY_ALIAS")
            val keyPasswordEnv = System.getenv("ANDROID_KEY_PASSWORD")

            if (
                !storeFilePath.isNullOrBlank() &&
                !storePasswordEnv.isNullOrBlank() &&
                !keyAliasEnv.isNullOrBlank() &&
                !keyPasswordEnv.isNullOrBlank()
            ) {
                storeFile = file(storeFilePath)
                storePassword = storePasswordEnv
                keyAlias = keyAliasEnv
                keyPassword = keyPasswordEnv
            }
        }
    }

    androidResources {
        noCompress += listOf()
    }

    // ✅ إزالة debug symbols من المكتبات الأصلية
    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
            keepDebugSymbols += listOf()
        }
        resources {
            excludes += listOf("META-INF/**", "DebugProbesKt.bin", "kotlin-tooling-metadata.json")
        }
    }

    buildTypes {
        debug {
            // ✅ تصغير debug
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                debugSymbolLevel = "none"
            }
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ حذف debug symbols من المكتبات الأصلية
    packagingOptions {
        jniLibs {
            keepDebugSymbols += listOf()
        }
    }
}

flutter {
    source = "../.."
}