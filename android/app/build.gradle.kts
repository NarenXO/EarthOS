plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.naren.earthos"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.naren.earthos"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

afterEvaluate {
    tasks.register("copyApkToFlutterOutput") {
        dependsOn("assembleDebug")
        doLast {
            val sourceFile = file("$buildDir/outputs/apk/debug/app-debug.apk")
            val targetDir = file("$projectDir/../../build/app/outputs/flutter-apk")
            targetDir.mkdirs()
            val targetFile = file("$targetDir/app-debug.apk")
            sourceFile.copyTo(targetFile, overwrite = true)
        }
    }

    tasks.named("assembleDebug") {
        finalizedBy("copyApkToFlutterOutput")
    }
}