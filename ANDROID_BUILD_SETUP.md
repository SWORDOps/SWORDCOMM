# SWORDCOMM Android Build Setup Guide

This guide will help you set up a complete Android development environment and build the SWORDCOMM application (Molly).

## Quick Start

### For Linux/macOS Users

```bash
chmod +x bootstrap-android-build.sh
./bootstrap-android-build.sh --build
```

### For Windows Users

```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\bootstrap-android-build.ps1 -Build
```

## System Requirements

### Disk Space & RAM
- **Disk Space**: ~50GB free (for SDK, NDK, and build artifacts)
- **RAM**: 8GB minimum (16GB recommended)
- **Internet**: Stable connection (downloads ~20GB)

### Supported Operating Systems
- **Linux**: Ubuntu 22.04+, Debian 12+, Fedora 38+, or compatible distributions
- **macOS**: macOS 11+ (Intel or Apple Silicon)
- **Windows**: Windows 10/11 (WSL 2 recommended for Windows)

## Detailed Setup Instructions

### Option 1: Automatic Setup (Recommended)

The bootstrap scripts automate the entire setup process.

#### Linux/macOS

```bash
# Make script executable
chmod +x bootstrap-android-build.sh

# Run with automatic build
./bootstrap-android-build.sh --build

# Or run setup only (without building)
./bootstrap-android-build.sh

# For specific build variant
./bootstrap-android-build.sh --build --variant prodGmsWebsiteRelease
```

**Available Options:**
```
--help              Show help message
--java-only         Install only Java (skip SDK)
--sdk-only          Install only Android SDK (skip Java)
--build             Automatically start build after setup
--variant VARIANT   Build specific variant (e.g., prodGmsWebsiteRelease)
--skip-gradle       Skip Gradle build after setup
--ci-mode           Setup for CI/CD environments
```

#### Windows (PowerShell)

```powershell
# Open PowerShell as Administrator, then:

# Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run with automatic build
.\bootstrap-android-build.ps1 -Build

# Or run setup only (without building)
.\bootstrap-android-build.ps1

# For specific build variant
.\bootstrap-android-build.ps1 -Build -Variant prodGmsWebsiteRelease
```

**Available Options:**
```
-Help              Show help message
-JavaOnly          Install only Java (skip SDK)
-SdkOnly           Install only Android SDK (skip Java)
-Build             Automatically start build after setup
-Variant VARIANT   Build specific variant (e.g., prodGmsWebsiteRelease)
-SkipGradle        Skip Gradle build after setup
-CiMode            Setup for CI/CD environments
```

### Option 2: Manual Setup

If you prefer to install components manually:

#### Linux

```bash
# 1. Install Java 17
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk openjdk-17-source

# Fedora/RHEL
sudo dnf install -y java-17-openjdk java-17-openjdk-devel

# 2. Create SDK directory
mkdir -p ~/Android/sdk
cd ~/Android/sdk

# 3. Download Android SDK command-line tools
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip
rm commandlinetools-linux-9477386_latest.zip

# 4. Install Android components
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/

cmdline-tools/latest/bin/sdkmanager "platforms;android-35"
cmdline-tools/latest/bin/sdkmanager "build-tools;35.0.0"
cmdline-tools/latest/bin/sdkmanager "ndk;28.0.13004108"
cmdline-tools/latest/bin/sdkmanager "platform-tools"

# 5. Set environment variables
echo 'export ANDROID_HOME=$HOME/Android/sdk' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/ndk/28.0.13004108:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### macOS

```bash
# 1. Install Java 17 using Homebrew
brew install openjdk@17
sudo ln -sfn $(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# 2-5. Follow same steps as Linux above for Android SDK setup
```

#### Windows

1. **Download and Install Java 17:**
   - Visit https://adoptium.net/
   - Download Java 17 for Windows (x64)
   - Run the installer and complete installation

2. **Create SDK Directory:**
   ```powershell
   mkdir $env:USERPROFILE\Android\sdk
   cd $env:USERPROFILE\Android\sdk
   ```

3. **Download Android SDK Command-Line Tools:**
   - Visit https://developer.android.com/studio/command-line
   - Download the Windows version
   - Extract to `$env:USERPROFILE\Android\sdk\cmdline-tools\`

4. **Install Android Components:**
   ```powershell
   $env:ANDROID_HOME = "$env:USERPROFILE\Android\sdk"
   & "$env:ANDROID_HOME\cmdline-tools\cmdline-tools\bin\sdkmanager.bat" "platforms;android-35"
   & "$env:ANDROID_HOME\cmdline-tools\cmdline-tools\bin\sdkmanager.bat" "build-tools;35.0.0"
   & "$env:ANDROID_HOME\cmdline-tools\cmdline-tools\bin\sdkmanager.bat" "ndk;28.0.13004108"
   & "$env:ANDROID_HOME\cmdline-tools\cmdline-tools\bin\sdkmanager.bat" "platform-tools"
   ```

5. **Set Environment Variables:**
   - Open System Properties → Environment Variables
   - Add new User variable: `ANDROID_HOME` = `C:\Users\YourUsername\Android\sdk`
   - Edit PATH and add: `%ANDROID_HOME%\cmdline-tools\cmdline-tools\bin;%ANDROID_HOME%\platform-tools`
   - Restart terminal

## Building the Project

### After Setup is Complete

#### Using Gradle Directly

```bash
# Debug build
./gradlew assembleDebug

# Release build (requires signing configuration)
./gradlew assembleRelease

# Specific variant
./gradlew assemble<Variant>
# Examples:
./gradlew assembleProdGmsWebsiteDebug
./gradlew assembleProdFossWebsiteRelease
./gradlew stagingGmsWebsiteDebug
```

#### Using the Build Script

If `build.sh` is available:

```bash
./build.sh android debug    # Android debug build
./build.sh android release  # Android release build
./build.sh android clean    # Clean build
./build.sh android test     # Run tests
```

#### On Windows

```powershell
.\gradlew.bat assembleDebug
.\gradlew.bat assembleRelease
```

### Available Build Variants

The project supports multiple build variants based on three dimensions:

**1. Environment:**
- `prod` - Production environment
- `staging` - Staging/testing environment

**2. License Type:**
- `gms` - Google Mobile Services (with proprietary Google libs)
- `foss` - Free and Open Source (no Google dependencies)

**3. Distribution:**
- `website` - For distribution through website
- `store` - For app store distribution

**Common Variants:**
- `prodGmsWebsiteDebug` - Production, GMS, Website, Debug
- `prodGmsWebsiteRelease` - Production, GMS, Website, Release
- `prodFossWebsiteRelease` - Production, FOSS, Website, Release
- `stagingGmsWebsiteDebug` - Staging, GMS, Website, Debug

## Build Output

After a successful build, the APK files are located in:

```
app/build/outputs/apk/[variant]/[buildType]/
```

Example for `prodGmsWebsiteDebug`:
```
app/build/outputs/apk/prodGmsWebsite/debug/app-prodGmsWebsite-debug.apk
```

## Troubleshooting

### Java Version Error
```
ERROR: JDK 17 or later is required
```

**Solution:**
```bash
# Check current Java version
java -version

# If wrong version, update JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64  # Linux
# or
export JAVA_HOME=$(/usr/libexec/java_home -v 17)  # macOS
```

### Android SDK Not Found
```
ERROR: ANDROID_HOME environment variable not set
```

**Solution:**
```bash
# Set for current session
export ANDROID_HOME=~/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# Or add to ~/.bashrc or ~/.zshrc for permanent setup
```

### Insufficient Disk Space
```
ERROR: Insufficient disk space
```

**Solution:**
- Free up at least 50GB
- Or move SDK to a drive with more space:
  ```bash
  mv ~/Android/sdk /path/to/large/drive/Android/sdk
  export ANDROID_HOME=/path/to/large/drive/Android/sdk
  ```

### Build Fails with Gradle Error
```
ERROR: Could not download gradle dependencies
```

**Solution:**
```bash
# Clear Gradle cache
./gradlew clean

# Try with offline mode disabled
./gradlew --refresh-dependencies assemble<Variant>

# Or check internet connection and retry
```

### macOS M1/M2 Issues
```
ERROR: Architecture not found for arm64
```

**Solution:**
The project should support Apple Silicon. If issues persist:
```bash
# Try with Rosetta translation
arch -x86_64 ./gradlew assemble<Variant>
```

## Build Variants Explained

### Environment
- **prod**: Production configuration, recommended for release builds
- **staging**: Testing environment with additional debug features

### License Type
- **gms**: Uses Google Mobile Services
  - Smaller download
  - Requires Google Play Services
  - Use for Google Play Store distribution
- **foss**: Free and Open Source variant
  - No Google dependencies
  - Larger download
  - Can be distributed freely without app store

### Distribution
- **website**: Optimized for website distribution
- **store**: Optimized for app store distribution

## CI/CD Integration

For automated builds in CI/CD pipelines:

```bash
# Linux/macOS
./bootstrap-android-build.sh --ci-mode --build --variant prodGmsWebsiteRelease

# Windows (PowerShell)
.\bootstrap-android-build.ps1 -CiMode -Build -Variant prodGmsWebsiteRelease
```

## Advanced Options

### Gradle Properties for Custom Builds

You can pass additional Gradle properties:

```bash
./gradlew assemble<Variant> \
  -PCI=true \
  -Dorg.gradle.parallel=true \
  -Dorg.gradle.workers.max=4
```

### Building Without Tests

```bash
./gradlew assemble<Variant> -x test
```

### Building with Debug Output

```bash
./gradlew assemble<Variant> --debug
```

## Project Configuration Files

Key build configuration files:

| File | Purpose |
|------|---------|
| `build.gradle.kts` | Root Gradle configuration |
| `settings.gradle.kts` | Module configuration |
| `gradle.properties` | Gradle JVM settings |
| `constants.gradle.kts` | SDK/Build tool versions |
| `app/build.gradle.kts` | App-specific build configuration |
| `gradle/libs.versions.toml` | Dependency version catalog |

## Additional Resources

- **Build Documentation**: See `BUILDING.md` for build and self-signing guide
- **Build System Summary**: See `BUILD_SYSTEM_SUMMARY.md` for Docker/CI/CD info
- **Docker Building**: See `DOCKER_BUILD.md` for containerized builds
- **Project Structure**: See `README.md` for project overview

## Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review build logs for specific error messages
3. Check `BUILDING.md` for common build issues
4. For Android-specific issues, visit https://developer.android.com/docs
5. For project-specific issues, check the project's issue tracker

## Environment Variables Summary

| Variable | Value | Purpose |
|----------|-------|---------|
| `ANDROID_HOME` | `~/Android/sdk` or `%USERPROFILE%\Android\sdk` | Android SDK location |
| `PATH` | Includes SDK tools | Command-line tool access |
| `JAVA_HOME` | Java installation path | Java compiler location |

## Next Steps

1. ✅ Run the bootstrap script
2. ✅ Verify Java and Android SDK installation
3. ✅ Build the project: `./gradlew assembleDebug`
4. ✅ Find APK in `app/build/outputs/apk/`
5. ✅ Install on device/emulator: `adb install app.apk`

Enjoy building SWORDCOMM!
