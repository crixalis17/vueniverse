plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keep local and CI builds working until this Firebase project's config is added.
// Once android/app/google-services.json exists, Remote Config is initialized normally.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val defaultVueniverseModelDownloadUrl =
    "https://storage.googleapis.com/mvp_mobile_app/models/medgemma/medgemma-1.5-4b-it-Q4_K_M.gguf"
val vueniverseModelDownloadUrl = providers.gradleProperty("VUENIVERSE_MODEL_DOWNLOAD_URL")
    .orElse(defaultVueniverseModelDownloadUrl)
    .get()

fun quotedBuildConfigValue(value: String): String =
    "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

android {
    namespace = "com.vueniverse.vueniverse"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vueniverse.vueniverse"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 28
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_STL=c++_shared")
            }
        }
        buildConfigField(
            "String",
            "VUENIVERSE_MODEL_DOWNLOAD_URL",
            quotedBuildConfigValue(vueniverseModelDownloadUrl),
        )
    }

    buildFeatures {
        buildConfig = true
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
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

dependencies {
    implementation("androidx.health.connect:connect-client:1.1.0")
    implementation("androidx.work:work-runtime:2.11.2")
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
    implementation("com.google.firebase:firebase-config")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    testImplementation("junit:junit:4.13.2")
    testImplementation("androidx.work:work-testing:2.11.2")
    testImplementation("org.json:json:20240303")
    androidTestImplementation("androidx.test.ext:junit:1.1.2")
    androidTestImplementation("androidx.test:runner:1.3.0")
    androidTestImplementation("androidx.work:work-testing:2.11.2")
}

val validateReleaseModelDownloadUrl by tasks.registering {
    doLast {
        check(vueniverseModelDownloadUrl.startsWith("https://")) {
            "Release builds require -PVUENIVERSE_MODEL_DOWNLOAD_URL=https://..."
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseModelDownloadUrl)
}
