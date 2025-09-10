import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")           // ✅ gunakan id Kotlin untuk KTS
    id("com.google.gms.google-services")         // (boleh tetap jika pakai Firebase)
    id("dev.flutter.flutter-gradle-plugin")      // harus terakhir
}

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        load(FileInputStream(f))
    }
}

android {
    namespace = "com.odanfm.radio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.odanfm.radio"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // ✅ Aman: hanya set jika properti tersedia
            val alias = keystoreProperties.getProperty("keyAlias")
            val keyPass = keystoreProperties.getProperty("keyPassword")
            val storePath = keystoreProperties.getProperty("storeFile")
            val storePass = keystoreProperties.getProperty("storePassword")

            if (!alias.isNullOrBlank()
                && !keyPass.isNullOrBlank()
                && !storePath.isNullOrBlank()
                && !storePass.isNullOrBlank()
            ) {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = file(storePath)
                storePassword = storePass
            }
        }
    }

    buildTypes {
        // biarkan debug pakai default debug keystore
        getByName("debug") { }

        getByName("release") {
            // ✅ assign hanya jika credential ada
            val ready = sequenceOf(
                "keyAlias", "keyPassword", "storeFile", "storePassword"
            ).all { !keystoreProperties.getProperty(it).isNullOrBlank() }

            if (ready) {
                signingConfig = signingConfigs.getByName("release")
            }

            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
