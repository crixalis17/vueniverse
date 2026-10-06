import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val vueniverseModelDownloadUrl = providers.gradleProperty("VUENIVERSE_MODEL_DOWNLOAD_URL")
    .orElse("")
    .get()

val vueniverseModelVariant = providers.gradleProperty("VUENIVERSE_MODEL_VARIANT")
    .orElse("vanilla")
    .get()
require(vueniverseModelVariant in setOf("vanilla", "lora-v7")) {
    "VUENIVERSE_MODEL_VARIANT must be vanilla or lora-v7"
}

val vueniverseNativeOptimization = providers.gradleProperty("VUENIVERSE_NATIVE_OPTIMIZATION")
    .orElse("standard")
    .get()
require(vueniverseNativeOptimization in setOf("standard", "release-style")) {
    "VUENIVERSE_NATIVE_OPTIMIZATION must be standard or release-style"
}

val vueniverseContractDiagnostics = providers.gradleProperty("VUENIVERSE_CONTRACT_DIAGNOSTICS")
    .orElse("off").get()
require(vueniverseContractDiagnostics in setOf("off", "fixture")) {
    "VUENIVERSE_CONTRACT_DIAGNOSTICS must be off or fixture"
}
// Exact, synthetic-only integration entry points. Never a production activation.
val approvedModelFixtureTargets = setOf(
    "integration_test/phone_lora_contract_test.dart",
    "integration_test/emulator_semantic_replay_test.dart",
)
if (vueniverseContractDiagnostics == "fixture") {
    val target = providers.gradleProperty("target").orElse("").get()
    val repoRoot = rootProject.projectDir.parentFile
    val selectedTarget = if (File(target).isAbsolute) File(target) else File(repoRoot, target)
    require(approvedModelFixtureTargets.any { selectedTarget.canonicalFile == File(repoRoot, it).canonicalFile }) {
        "Fixture diagnostics require an exact approved synthetic integration target"
    }
    require(gradle.startParameter.taskNames.isNotEmpty() && gradle.startParameter.taskNames.all { it.contains("Debug") }) {
        "Fixture diagnostics are restricted to explicit Debug tasks"
    }
}

// This is a fixture-evaluation capability, not a production activation switch.
val vueniverseCandidateEvaluation = providers.gradleProperty("VUENIVERSE_CANDIDATE_EVALUATION")
    .orElse("off").get()
require(vueniverseCandidateEvaluation in setOf("off", "fixture")) {
    "VUENIVERSE_CANDIDATE_EVALUATION must be off or fixture"
}
if (vueniverseCandidateEvaluation == "fixture") {
    val target = providers.gradleProperty("target").orElse("").get()
    val repoRoot = rootProject.projectDir.parentFile
    val selectedTarget = if (File(target).isAbsolute) File(target) else File(repoRoot, target)
    require(approvedModelFixtureTargets.any { selectedTarget.canonicalFile == File(repoRoot, it).canonicalFile }) {
        "Candidate evaluation requires an exact approved synthetic integration target"
    }
    val allowedTasks = setOf("assembleDebug", "assembleDebugAndroidTest", "connectedDebugAndroidTest", "testDebugUnitTest", "compileDebugKotlin", "compileDebugUnitTestKotlin", "installDebug", "compileFlutterBuildDebug")
    require(gradle.startParameter.taskNames.isNotEmpty() && gradle.startParameter.taskNames.all { it.substringAfterLast(':') in allowedTasks }) {
        "Candidate evaluation is restricted to explicit approved Debug tasks"
    }
    require(vueniverseModelVariant == "lora-v7") { "Candidate evaluation requires the lora-v7 artifact" }
}

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
                if (vueniverseNativeOptimization == "release-style") {
                    // Keep the debuggable fixture APK while optimizing CPU math.
                    // Do not enable fast-math or change production guard/bounds.
                    arguments += listOf(
                        "-DCMAKE_C_FLAGS_DEBUG=-O3",
                        "-DCMAKE_CXX_FLAGS_DEBUG=-O3",
                    )
                }
                arguments += listOf("-DVUENIVERSE_CONTRACT_DIAGNOSTICS=" + if (vueniverseContractDiagnostics == "fixture") "ON" else "OFF")
            }
        }
        buildConfigField(
            "String",
            "VUENIVERSE_MODEL_DOWNLOAD_URL",
            quotedBuildConfigValue(vueniverseModelDownloadUrl),
        )
        buildConfigField("String", "VUENIVERSE_MODEL_VARIANT", quotedBuildConfigValue(vueniverseModelVariant))
        buildConfigField("boolean", "VUENIVERSE_CONTRACT_DIAGNOSTICS", (vueniverseContractDiagnostics == "fixture").toString())
        buildConfigField("boolean", "VUENIVERSE_CANDIDATE_EVALUATION", "false")
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
        debug {
            buildConfigField("boolean", "VUENIVERSE_CANDIDATE_EVALUATION", (vueniverseCandidateEvaluation == "fixture").toString())
        }
        release {
            buildConfigField("boolean", "VUENIVERSE_CANDIDATE_EVALUATION", "false")
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
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
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
