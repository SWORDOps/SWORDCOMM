plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "im.molly.security"
    compileSdk = 34
ndkPath = "/opt/android-sdk-linux/ndk/27.0.12077973"
    // ndkVersion = "26.1.10909125"

    defaultConfig {
        minSdk = 29
        targetSdk = 34

        externalNativeBuild {
            cmake {
                // C++ flags
                cppFlags += listOf(
                    "-std=c++17",
                    "-fexceptions",
                    "-frtti",
                    "-O3",
                    "-ffast-math"
                )

                // C flags
                cFlags += listOf(
                    "-O3",
                    "-ffast-math"
                )

                // CMake arguments
        arguments(
            "-DANDROID_STL=c++_shared",
            "-DANDROID_ARM_NEON=TRUE",
            "-DPRODUCTION_CRYPTO=${findProperty("PRODUCTION_CRYPTO") ?: "OFF"}",
            "-DOQS_USE_OPENSSL=ON",
            "-DOQS_MINIMAL_BUILD=ON",
            "-DOQS_ENABLE_KEM_ml_kem_1024=ON",
            "-DOQS_ENABLE_SIG_ml_dsa_87=ON",
            "-DOQS_SPEED_USE_ARM_NEON=ON",
            "-DCMAKE_MODULE_PATH=${project.projectDir}/cmake"
        )
            }
        }

        // ABI filters (ARM64 only for now)
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
