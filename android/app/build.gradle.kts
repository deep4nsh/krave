plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services") // ✅ Firebase config
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.krave"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ Needed for newer Java APIs
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.krave"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // ✅ For Firebase & large dependency support
    }

    buildTypes {
        getByName("release") {
            // For now, use debug signing (you can replace with your release key)
            signingConfig = signingConfigs.getByName("debug")
            // Explicitly disable resource shrinking unless code shrinking is enabled
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/NOTICE",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔹 Core Kotlin and Android
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // 🔹 Firebase BOM (Bill of Materials) — keeps all Firebase libs in sync
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // 🔹 Firebase SDKs
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // 🔹 Optional: Messaging (if you plan to use push notifications)
    implementation("com.google.firebase:firebase-messaging")

    // 🔹 Optional: Analytics (recommended)
    implementation("com.google.firebase:firebase-analytics")

    // 🔹 Flutter dependencies handled by Flutter itself
}