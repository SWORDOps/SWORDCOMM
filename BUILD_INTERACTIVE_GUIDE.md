# SWORDCOMM Interactive Build System

Complete, production-ready build scripts with full control over every build option.

## Quick Start

### Linux/macOS
```bash
chmod +x build-interactive.sh
./build-interactive.sh
```

### Windows (PowerShell)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\build-interactive.ps1
```

---

## Features

✅ **Full Interactive Configuration**
- Choose build type (Debug/Release)
- Select build variant
- Toggle tests, linting, benchmarks
- Control parallelization and caching
- Enable/disable Gradle daemon
- Option for clean builds

✅ **No Skips by Default**
- Runs ALL tests
- Runs ALL linting
- Runs benchmarks (optional)
- Full validation and checks
- Can selectively disable individual features

✅ **Real-time Monitoring**
- Live build output (optional verbose mode)
- Build time tracking
- APK size reporting
- Detailed error messages
- Timestamped logging

✅ **Post-Build Actions**
- APK verification
- Installation options:
  - Install on connected device via ADB
  - Copy to Desktop
  - Open in file manager
- Build statistics and summary

✅ **Flexible Configuration**
- Interactive menu (default)
- Non-interactive mode with flags
- Customizable build variants
- Environmental awareness

---

## Build Variants

All combinations available:

| Variant | Environment | License | Distribution |
|---------|-------------|---------|--------------|
| `prodGmsWebsiteDebug` | Production | Google Services | Website |
| `prodGmsWebsiteRelease` | Production | Google Services | Website |
| `prodFossWebsiteDebug` | Production | Open Source | Website |
| `prodFossWebsiteRelease` | Production | Open Source | Website |
| `stagingGmsWebsiteDebug` | Staging | Google Services | Website |
| `stagingGmsWebsiteRelease` | Staging | Google Services | Website |

---

## Usage Examples

### Interactive Mode (Recommended)
```bash
# macOS/Linux
./build-interactive.sh

# Windows
.\build-interactive.ps1
```
**What happens:**
1. Prerequisites verification
2. Interactive menu for all options
3. Configuration summary
4. Full build with selected options
5. APK verification and installation options
6. Build statistics

### Non-Interactive Mode
```bash
# macOS/Linux
./build-interactive.sh --no-interactive --variant prodGmsWebsiteRelease --clean

# Windows
.\build-interactive.ps1 -NoInteractive -Variant prodGmsWebsiteRelease -Clean
```

### With Specific Options
```bash
# macOS/Linux
./build-interactive.sh --variant prodFossWebsiteDebug --skip-tests --skip-lint --verbose

# Windows
.\build-interactive.ps1 -Variant prodFossWebsiteDebug -SkipTests -SkipLint -Verbose
```

### Clean Release Build
```bash
# macOS/Linux
./build-interactive.sh --clean --variant prodGmsWebsiteRelease

# Windows
.\build-interactive.ps1 -Clean -Variant prodGmsWebsiteRelease
```

### Fast Incremental Build
```bash
# macOS/Linux
./build-interactive.sh --no-interactive

# Windows
.\build-interactive.ps1 -NoInteractive
```

---

## Command-Line Options

### Linux/macOS (`build-interactive.sh`)

```
--help              Show help message
--no-interactive    Skip interactive menu, use defaults
--variant VARIANT   Specify build variant directly
--skip-tests        Skip unit tests
--skip-lint         Skip code linting
--clean             Force clean build (removes artifacts)
--verbose           Enable verbose/info output
```

### Windows (`build-interactive.ps1`)

```
-Help              Show help message
-NoInteractive     Skip interactive menu, use defaults
-Variant VARIANT   Specify build variant directly
-SkipTests         Skip unit tests
-SkipLint          Skip code linting
-Clean             Force clean build
-Verbose           Enable verbose/info output
-NoDaemon          Disable Gradle daemon
```

---

## Full Build Process

### What Runs by Default

```
┌─────────────────────────────────────┐
│   Prerequisites Verification        │
│  ✓ Java 17 check                    │
│  ✓ Gradle wrapper                   │
│  ✓ Android SDK                      │
│  ✓ Project structure                │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Interactive Configuration         │
│  • Build type selection             │
│  • Variant selection                │
│  • Feature toggles                  │
│  • Optimization settings            │
│  • Configuration summary            │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Build Execution                   │
│  • Optional clean                   │
│  • Gradle compilation               │
│  ✓ Unit tests (default)             │
│  ✓ Lint checks (default)            │
│  ✓ Build benchmarks (optional)      │
│  • APK generation                   │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Post-Build Verification           │
│  • APK existence check              │
│  • APK size reporting               │
│  • Installation options             │
│  • Build statistics                 │
└─────────────────────────────────────┘
```

### Configuration Options Available

1. **Build Type**
   - Debug (faster, larger)
   - Release (optimized, signed)

2. **Build Variant**
   - 6 different combinations
   - Environment (prod/staging)
   - License type (GMS/FOSS)
   - Distribution target

3. **Testing**
   - ✓ Unit tests (default ON)
   - ✓ Linting (default ON)
   - Benchmarks (optional)

4. **Performance**
   - Parallel compilation
   - Build cache
   - Gradle daemon
   - Worker threads (max 8)

5. **Build Mode**
   - Clean build (slow, full rebuild)
   - Incremental build (fast, cached)

6. **Output**
   - Quiet (only essentials)
   - Verbose (detailed info)

---

## Build Logs

Each build creates a timestamped log file:

```
build-20241117-143022.log
```

Contains:
- Complete build timeline
- All warnings and errors
- Gradle output
- Build duration
- APK information

**View logs:**
```bash
# Last 50 lines
tail -50 build-*.log

# Follow in real-time
tail -f build-*.log

# Search for errors
grep ERROR build-*.log
```

---

## Example Interactive Session

```
================================================================================
SWORDCOMM Android Build System
================================================================================

ℹ Build log: build-20241117-143022.log

→ Verifying prerequisites...
✓ Java 17 found
✓ Gradle wrapper found
✓ Android SDK found
✓ Project structure valid
ℹ Pre-flight checks: 4/4 passed
✓ All prerequisites met

Press Enter to continue...

================================================================================
SWORDCOMM Android Build - Interactive Configuration
================================================================================

→ Select build type:
ℹ Build Type:
  1) Debug
  2) Release
Select option (1-2): 1
✓ Selected: Debug

→ Select build variant:
ℹ Build Variant:
  1) prodGmsWebsiteDebug
  2) prodGmsWebsiteRelease
  3) prodFossWebsiteDebug
  4) prodFossWebsiteRelease
  5) stagingGmsWebsiteDebug
  6) stagingGmsWebsiteRelease
Select option (1-6): 1
✓ Selected: prodGmsWebsiteDebug

→ Run unit tests?
Include unit tests in build? (y/n): y

→ Run linting?
Include code linting? (y/n): y

→ Run benchmarks?
Include benchmark tests? (y/n): n

→ Build configuration:
Enable parallel compilation? (y/n): y
Enable build cache? (y/n): y
Enable Gradle daemon? (y/n): y

→ Build type:
Perform clean build (slow, but removes all artifacts)? (y/n): n

→ Build verbosity:
Enable verbose output? (y/n): n

================================================================================
Build Configuration Summary
================================================================================
Build Type:           debug
Build Variant:        prodGmsWebsiteDebug
Run Tests:            true
Run Lint:             true
Run Benchmarks:       false
Parallel Build:       true
Build Cache:          true
Gradle Daemon:        true
Clean Build:          false
Verbose Output:       false
Log File:             build-20241117-143022.log

Start build with these settings? (y/n): y

================================================================================
Building SWORDCOMM - prodGmsWebsiteDebug
================================================================================

ℹ Running Gradle build...
ℹ Command: ./gradlew --daemon --parallel --max-workers=8 --build-cache --quiet :app:assembleProdGmsWebsiteDebug

[Gradle build output...]

✓ Build completed successfully!
ℹ Build duration: 4m 32s

→ Verifying APK generation...
✓ APK found: app/build/outputs/apk/prodGmsWebsite/debug/app-prodGmsWebsite-debug.apk
ℹ APK size: 47 MB

ℹ Installation options:
  1) Install on connected device (adb install)
  2) Copy to Desktop
  3) Show in file manager
  4) Skip
Select option: 1

ℹ Installing on device...
Success

================================================================================
Build Statistics
================================================================================
Build Log: build-20241117-143022.log

Generated APKs:
  - app-prodGmsWebsite-debug.apk (47 MB)

✓ Build completed successfully!
ℹ Log saved to: build-20241117-143022.log
```

---

## Troubleshooting

### "Java 17 required, found version X"
```bash
# Install Java 17
./bootstrap-android-build.sh  # This will handle it

# Or manually
sudo apt-get install openjdk-17-jdk  # Linux
brew install openjdk@17              # macOS
```

### "Gradle wrapper not found"
You're not in the SWORDCOMM root directory. Make sure to run from the project root:
```bash
cd /path/to/SWORDCOMM
./build-interactive.sh
```

### "Android SDK not found"
```bash
# Run the bootstrap script first
./bootstrap-android-build.sh
```

### Build fails with "Out of memory"
Gradle is running out of heap space. Try:
```bash
# Linux/macOS
export _JAVA_OPTIONS="-Xmx4g"
./build-interactive.sh --no-interactive

# Windows - Set environment variable first
$env:_JAVA_OPTIONS="-Xmx4g"
.\build-interactive.ps1 -NoInteractive
```

### Slow builds
Try these options:
```bash
# Disable certain checks
./build-interactive.sh --skip-lint --skip-tests --no-interactive

# Or use non-interactive with daemon
./build-interactive.sh --no-interactive
```

---

## Best Practices

### For Development
```bash
# Fast debug builds with caching
./build-interactive.sh --no-interactive --skip-lint
```

### For Release
```bash
# Full clean release build
./build-interactive.sh --clean --variant prodGmsWebsiteRelease
```

### For CI/CD
```bash
# Non-interactive, full validation
./build-interactive.sh --no-interactive --verbose
```

### For Testing
```bash
# Run everything including benchmarks
# Use interactive mode and select all options
./build-interactive.sh
```

---

## Build Variant Selection Guide

**For Testing:** `prodGmsWebsiteDebug`
- Development builds
- Includes all Google services
- Faster compilation

**For Distribution:** `prodGmsWebsiteRelease`
- Optimized production build
- Signed and obfuscated
- Requires signing configuration

**For Open Source:** `prodFossWebsiteRelease`
- No Google dependencies
- Free and open source
- Can distribute freely

**For Staging:** `stagingGmsWebsiteDebug`
- Testing environment
- Additional debug features
- Not for production

---

## Advanced Usage

### Continuous Integration
```bash
./build-interactive.sh --no-interactive --clean --variant prodGmsWebsiteRelease --verbose
```

### Building All Variants
```bash
for variant in prodGmsWebsiteDebug prodFossWebsiteDebug stagingGmsWebsiteDebug; do
    ./build-interactive.sh --no-interactive --variant $variant
done
```

### Parallel Builds
Both scripts use `--max-workers=8` for maximum parallelization by default.

### Custom Gradle Properties
Edit `~/.gradle/gradle.properties`:
```properties
org.gradle.parallel=true
org.gradle.workers.max=8
org.gradle.caching=true
org.gradle.vfs.watch=true
```

---

## System Requirements

- **Disk Space:** 50GB+ (for full SDK + build artifacts)
- **RAM:** 8GB minimum (16GB recommended)
- **Java:** Java 17 (checked automatically)
- **Network:** Stable for first-time setup
- **Time:** 5-30 minutes depending on options

---

## Getting Help

**View help:**
```bash
./build-interactive.sh --help      # Linux/macOS
.\build-interactive.ps1 -Help      # Windows
```

**Check logs:**
```bash
tail -f build-*.log
```

**Verbose mode:**
```bash
./build-interactive.sh --verbose --no-interactive
.\build-interactive.ps1 -Verbose -NoInteractive
```

---

**Ready to build? Run the script for your platform!** 🚀
