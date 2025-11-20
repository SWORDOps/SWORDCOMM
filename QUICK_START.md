# SWORDCOMM Android Build - Quick Start

## Can't Compile on This Machine

The Android SDK is not installed on the current system. Use the bootstrap scripts below to set up your PC.

---

## 🚀 Quick Setup

### For Linux/macOS:
```bash
chmod +x bootstrap-android-build.sh
./bootstrap-android-build.sh --build
```

### For Windows (PowerShell as Admin):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\bootstrap-android-build.ps1 -Build
```

---

## 📋 What These Scripts Do

- **Install Java 17** (if needed)
- **Download Android SDK** (API 35, Build Tools 35.0.0, NDK 28.0.13004108)
- **Configure environment variables** (ANDROID_HOME, PATH)
- **Verify installation**
- **Build the APK** (optional)

---

## 🛠️ Manual Build (After Setup)

```bash
# Debug build
./gradlew assembleDebug

# Release build
./gradlew assembleRelease

# Specific variant
./gradlew assembleProdGmsWebsiteDebug
./gradlew assembleProdFossWebsiteRelease
```

---

## 📦 Build Variants

**Format:** `[environment][license][distribution][buildType]`

| Variant | Meaning |
|---------|---------|
| `prodGmsWebsiteDebug` | Production, Google Services, Website, Debug |
| `prodGmsWebsiteRelease` | Production, Google Services, Website, Release |
| `prodFossWebsiteRelease` | Production, Open Source, Website, Release |
| `stagingGmsWebsiteDebug` | Staging, Google Services, Website, Debug |

---

## ✅ System Requirements

- **50GB** disk space
- **8GB** RAM (16GB recommended)
- Stable internet connection
- Linux, macOS, or Windows 10/11

---

## 📍 Find Your APK

After build completes, APK is at:
```
app/build/outputs/apk/[variant]/[buildType]/app-*.apk
```

Example:
```
app/build/outputs/apk/prodGmsWebsite/debug/app-prodGmsWebsite-debug.apk
```

---

## 🔧 Advanced Options

```bash
# Linux/macOS
./bootstrap-android-build.sh --help
./bootstrap-android-build.sh --java-only
./bootstrap-android-build.sh --sdk-only
./bootstrap-android-build.sh --variant prodGmsWebsiteRelease --build

# Windows (PowerShell)
.\bootstrap-android-build.ps1 -Help
.\bootstrap-android-build.ps1 -JavaOnly
.\bootstrap-android-build.ps1 -SdkOnly
.\bootstrap-android-build.ps1 -Variant prodGmsWebsiteRelease -Build
```

---

## 📚 Full Documentation

See `ANDROID_BUILD_SETUP.md` for:
- Detailed setup instructions
- Manual installation steps
- Troubleshooting guide
- Docker build info
- CI/CD integration

---

## ⚠️ Troubleshooting Quick Links

**"JDK 17 or later required"**
→ Install Java 17 via bootstrap script

**"ANDROID_HOME not found"**
→ Run bootstrap script again and reload terminal

**"Insufficient disk space"**
→ Free up 50GB or move SDK to larger drive

**Build fails**
→ Run `./gradlew clean` then try again

---

## 💡 Tips

- First build takes 10-15 minutes (downloads dependencies)
- Subsequent builds are much faster (1-5 minutes)
- Run `./gradlew` without arguments to see all available tasks
- Use `./build.sh --help` to see project-specific build commands

---

## 📖 Project Info

- **App Name:** Molly (SWORDCOMM)
- **Base:** Signal Protocol + Security enhancements
- **Build System:** Gradle 8.9 with Kotlin DSL
- **Java:** 17+
- **Android SDK:** API 35, Build Tools 35.0.0
- **NDK:** 28.0.13004108

---

**Ready to build?** Run the bootstrap script for your OS above! 🎉
