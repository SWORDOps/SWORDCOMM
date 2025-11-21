# SWORDCOMM Android Build Instructions

This document provides instructions for building the SWORDCOMM Android APK from source.

## Prerequisites

- **Java 17** (tested with Temurin 17.0.13)
- **Android SDK**:
  - Platform SDK 34 & 35
  - Build Tools 35.0.0
  - NDK 27.0.12077973
- **Gradle 8.11.1** (included via wrapper)
- **~8GB RAM minimum** (16GB recommended)
- **~20GB free disk space**

## Quick Start (Automated Build)

For environments **with internet access** (no proxy restrictions):

```bash
./fetch_and_build.sh
```

This script will:
1. Automatically detect missing dependencies
2. Download them from Maven Central / Google Maven
3. Build the APK iteratively until complete

## Manual Build Steps

### 1. Set up Environment

Create `local.properties` in the project root:
```properties
sdk.dir=/path/to/android-sdk
```

Set environment variables:
```bash
export ANDROID_HOME=/path/to/android-sdk
export ANDROID_SDK_ROOT=/path/to/android-sdk
export JAVA_HOME=/path/to/jdk-17
export PATH=$JAVA_HOME/bin:$PATH
```

### 2. Run Build

**With internet access:**
```bash
./gradlew assembleProdGmsWebsiteDebug
```

**Offline mode** (requires pre-downloaded dependencies):
```bash
./gradlew assembleProdGmsWebsiteDebug --offline -Dorg.gradle.dependency.verification=off
```

### 3. Locate APK

After successful build, the APK will be located at:
```
app/build/outputs/apk/prodGms/websiteDebug/Signal-Android-website-prod-universal-7.63.3-debug.apk
```

## Current Build Status

### ✅ Completed:
- Android SDK configuration (platforms, NDK, build-tools)
- Java 17 toolchain setup
- Gradle wrapper 8.11.1 configuration
- Build infrastructure dependencies (~200+ artifacts):
  - Kotlin 2.0.20, 2.0.21, 2.2.20
  - Android Gradle Plugin 8.10.1
  - gradle-kotlin-dsl-plugins 5.1.1
  - All parent POMs and build-time dependencies
- build-logic plugins compile successfully
- Configuration phase passes

### 🔄 In Progress:
- Runtime application dependencies (~100+ artifacts)
  - AndroidX libraries (compose, camera, biometric, etc.)
  - Signal-specific libraries (sqlcipher, libsignal, argon2, etc.)
  - Third-party libraries (OkHttp, RxJava, Jackson, Protobuf, etc.)

## Build Architecture

```
SWORDCOMM/
├── app/                    # Main Android application
├── build-logic/            # Gradle build plugins
│   └── plugins/            # Custom convention plugins
├── security-lib/           # Native security libraries (Kyber, ML-DSA)
├── translation-lib/        # Translation layer
├── libsignal-service/      # Signal protocol implementation
├── core-*/                 # Core utilities and UI
└── fetch_and_build.sh      # Automated build script
```

## Troubleshooting

### Issue: "SDK location not found"
**Solution:** Create `local.properties` with correct `sdk.dir` path.

### Issue: "NDK not configured"
**Solution:** Install NDK 27.0.12077973:
```bash
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "ndk;27.0.12077973"
```

### Issue: "No cached version of X available for offline mode"
**Solution:** Either:
1. Run without `--offline` flag (requires internet)
2. Use `fetch_and_build.sh` to auto-download dependencies
3. Manually download dependencies to `~/.m2/repository`

### Issue: "Cannot find Java 17"
**Solution:** Download Temurin 17 from:
https://github.com/adoptium/temurin17-binaries/releases/

### Issue: Proxy authentication failures
**Solution:** Run build in environment without HTTP proxy, or configure corporate proxy settings in `gradle.properties`:
```properties
systemProp.http.proxyHost=proxy.example.com
systemProp.http.proxyPort=8080
systemProp.http.proxyUser=username
systemProp.http.proxyPassword=password
```

## Online Build (GitHub Actions / CI)

For running in CI environments without proxy restrictions:

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Set up JDK 17
    uses: actions/setup-java@v4
    with:
      java-version: '17'
      distribution: 'temurin'

  - name: Set up Android SDK
    uses: android-actions/setup-android@v3
    with:
      api-level: 35
      build-tools: 35.0.0
      ndk: 27.0.12077973

  - name: Build APK
    run: ./fetch_and_build.sh

  - name: Upload APK
    uses: actions/upload-artifact@v4
    with:
      name: app-debug
      path: app/build/outputs/apk/**/*.apk
```

## Performance Notes

- **First build**: ~20-30 minutes (downloads ~2GB dependencies)
- **Incremental builds**: 2-5 minutes
- **Clean offline build**: 5-10 minutes

## Additional Resources

- **Molly (upstream):** https://github.com/mollyim/mollyim-android
- **Signal (original):** https://github.com/signalapp/Signal-Android
- **Gradle Build Scans:** Run with `--scan` flag for detailed build analysis

## License

This project inherits the license from Signal/Molly (GPLv3).
