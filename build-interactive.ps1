#Requires -Version 5.0
################################################################################
# SWORDCOMM Android Build - Interactive Full Build Script (Windows/PowerShell)
#
# Complete build system with interactive option selection for Windows.
# Supports full builds with all testing, linting, and optimization.
#
# Usage:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   .\build-interactive.ps1
#
################################################################################

param(
    [switch]$Help,
    [switch]$NoInteractive,
    [string]$Variant = "",
    [switch]$SkipTests,
    [switch]$SkipLint,
    [switch]$Clean,
    [switch]$Verbose,
    [switch]$NoDaemon
)

# Colors
$ColorHeader = "Cyan"
$ColorSuccess = "Green"
$ColorInfo = "Blue"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildLog = Join-Path $ScriptDir "build-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$GradleCmd = Join-Path $ScriptDir "gradlew.bat"

# Build options
$BuildType = "debug"
$BuildVariant = "prodGmsWebsiteDebug"
$RunTests = $true
$RunLint = $true
$RunBenchmarks = $false
$ParallelBuild = $true
$BuildCache = $true
$VerboseOutput = $false
$DaemonMode = $true
$CleanBuild = $false

################################################################################
# Functions
################################################################################

function Write-Header {
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $ColorHeader
    Write-Host $args -ForegroundColor $ColorHeader
    Write-Host ("=" * 80) -ForegroundColor $ColorHeader
    Write-Host ""
}

function Write-Success {
    Write-Host "✓ $args" -ForegroundColor $ColorSuccess
}

function Write-Info {
    Write-Host "ℹ $args" -ForegroundColor $ColorInfo
}

function Write-Warning {
    Write-Host "⚠ $args" -ForegroundColor $ColorWarning
}

function Write-Error-Custom {
    Write-Host "✗ $args" -ForegroundColor $ColorError
}

function Write-Step {
    Write-Host ""
    Write-Host "→ $args" -ForegroundColor $ColorWarning
}

function Log-Message {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Add-Content -Path $BuildLog
}

function Select-Option {
    param(
        [string]$Prompt,
        [string[]]$Options
    )

    while ($true) {
        Write-Host ""
        Write-Host $Prompt -ForegroundColor $ColorInfo
        for ($i = 0; $i -lt $Options.Count; $i++) {
            Write-Host "  $($i+1))) $($Options[$i])"
        }

        $choice = Read-Host "Select option (1-$($Options.Count))"

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
            $selected = [int]$choice - 1
            Write-Success "Selected: $($Options[$selected])"
            return $Options[$selected]
        }
        else {
            Write-Error-Custom "Invalid selection. Please try again."
        }
    }
}

function Get-YesNo {
    param([string]$Prompt)

    while ($true) {
        $response = Read-Host "$Prompt (y/n)"
        if ($response -match '^[Yy]$') { return $true }
        if ($response -match '^[Nn]$') { return $false }
        Write-Host "Please answer y or n."
    }
}

function Verify-Prerequisites {
    Write-Step "Verifying prerequisites..."

    $missing = 0

    # Check Java
    try {
        $javaVersion = java -version 2>&1 | Out-String
        if ($javaVersion -match 'openjdk version "(\d+)') {
            $major = [int]$matches[1]
            if ($major -eq 17) {
                Write-Success "Java 17 found"
            }
            else {
                Write-Error-Custom "Java 17 required, found version $major"
                $missing++
            }
        }
    }
    catch {
        Write-Error-Custom "Java not found"
        $missing++
    }

    # Check Gradle
    if (Test-Path $GradleCmd) {
        Write-Success "Gradle wrapper found"
    }
    else {
        Write-Error-Custom "Gradle wrapper not found at $GradleCmd"
        $missing++
    }

    # Check Android SDK
    $AndroidHome = "$env:USERPROFILE\Android\sdk"
    if (Test-Path $AndroidHome) {
        Write-Success "Android SDK found"
    }
    else {
        Write-Error-Custom "Android SDK not found at $AndroidHome"
        Write-Info "Run: .\bootstrap-android-build.ps1"
        $missing++
    }

    # Check project structure
    if (Test-Path "$ScriptDir\app") {
        Write-Success "Project structure valid"
    }
    else {
        Write-Error-Custom "App directory not found"
        $missing++
    }

    if ($missing -gt 0) {
        Write-Error-Custom "Missing $missing prerequisite(s). Cannot proceed."
        return $false
    }

    Write-Success "All prerequisites met"
    return $true
}

function Interactive-Menu {
    Write-Header "SWORDCOMM Android Build - Interactive Configuration"

    # Build Type
    Write-Step "Select build type:"
    $BuildType = Select-Option "Build Type:" @("Debug", "Release")
    $script:BuildType = $BuildType.ToLower()

    # Build Variant
    Write-Step "Select build variant:"
    $script:BuildVariant = Select-Option "Build Variant:" @(
        "prodGmsWebsiteDebug",
        "prodGmsWebsiteRelease",
        "prodFossWebsiteDebug",
        "prodFossWebsiteRelease",
        "stagingGmsWebsiteDebug",
        "stagingGmsWebsiteRelease"
    )

    # Testing
    Write-Step "Run unit tests?"
    if (Get-YesNo "Include unit tests in build?") {
        $script:RunTests = $true
    }
    else {
        $script:RunTests = $false
        Write-Warning "Unit tests will be skipped"
    }

    # Linting
    Write-Step "Run linting?"
    if (Get-YesNo "Include code linting?") {
        $script:RunLint = $true
    }
    else {
        $script:RunLint = $false
        Write-Warning "Linting will be skipped"
    }

    # Benchmarks
    Write-Step "Run benchmarks?"
    if (Get-YesNo "Include benchmark tests?") {
        $script:RunBenchmarks = $true
    }
    else {
        $script:RunBenchmarks = $false
    }

    # Parallel builds
    Write-Step "Build configuration:"
    if (Get-YesNo "Enable parallel compilation?") {
        $script:ParallelBuild = $true
    }
    else {
        $script:ParallelBuild = $false
    }

    if (Get-YesNo "Enable build cache?") {
        $script:BuildCache = $true
    }
    else {
        $script:BuildCache = $false
    }

    if (Get-YesNo "Enable Gradle daemon?") {
        $script:DaemonMode = $true
    }
    else {
        $script:DaemonMode = $false
    }

    # Clean build
    Write-Step "Build type:"
    if (Get-YesNo "Perform clean build (slow, but removes all artifacts)?") {
        $script:CleanBuild = $true
    }
    else {
        $script:CleanBuild = $false
    }

    # Verbose
    Write-Step "Build verbosity:"
    if (Get-YesNo "Enable verbose output?") {
        $script:VerboseOutput = $true
    }
    else {
        $script:VerboseOutput = $false
    }

    # Summary
    Write-Header "Build Configuration Summary"
    Write-Host "Build Type:           $BuildType"
    Write-Host "Build Variant:        $script:BuildVariant"
    Write-Host "Run Tests:            $script:RunTests"
    Write-Host "Run Lint:             $script:RunLint"
    Write-Host "Run Benchmarks:       $script:RunBenchmarks"
    Write-Host "Parallel Build:       $script:ParallelBuild"
    Write-Host "Build Cache:          $script:BuildCache"
    Write-Host "Gradle Daemon:        $script:DaemonMode"
    Write-Host "Clean Build:          $script:CleanBuild"
    Write-Host "Verbose Output:       $script:VerboseOutput"
    Write-Host "Log File:             $BuildLog"
    Write-Host ""

    if (-not (Get-YesNo "Start build with these settings?")) {
        Write-Warning "Build cancelled"
        return $false
    }

    return $true
}

function Build-Project {
    Write-Header "Building SWORDCOMM - $script:BuildVariant"

    Set-Location $ScriptDir

    # Construct Gradle flags
    $gradleFlags = @()

    # Daemon mode
    if (-not $script:DaemonMode) {
        $gradleFlags += "--no-daemon"
    }
    else {
        $gradleFlags += "--daemon"
    }

    # Parallel
    if ($script:ParallelBuild) {
        $gradleFlags += "--parallel"
        $gradleFlags += "--max-workers=8"
    }

    # Build cache
    if ($script:BuildCache) {
        $gradleFlags += "--build-cache"
    }

    # Verbose
    if ($script:VerboseOutput) {
        $gradleFlags += "--info"
    }
    else {
        $gradleFlags += "--quiet"
    }

    # Clean
    if ($script:CleanBuild) {
        Write-Info "Running clean..."
        Log-Message "INFO" "Running clean"
        & $GradleCmd $gradleFlags clean 2>&1 | Tee-Object -FilePath $BuildLog -Append | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Clean failed"
            return $false
        }
    }

    # Build
    $task = ":app:assemble$($script:BuildVariant)"

    # Add exclusions if needed
    if (-not $script:RunTests) {
        $gradleFlags += "-x"
        $gradleFlags += "test"
    }

    if (-not $script:RunLint) {
        $gradleFlags += "-x"
        $gradleFlags += "lint"
    }

    if (-not $script:RunBenchmarks) {
        $gradleFlags += "-x"
        $gradleFlags += "benchmark"
    }

    Write-Info "Running Gradle build..."
    Write-Info "Command: $GradleCmd $($gradleFlags -join ' ') $task"
    Log-Message "INFO" "Starting build: $GradleCmd $($gradleFlags -join ' ') $task"

    $startTime = Get-Date

    & $GradleCmd $gradleFlags $task 2>&1 | Tee-Object -FilePath $BuildLog -Append

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Build failed"
        Log-Message "ERROR" "Build failed with exit code $LASTEXITCODE"
        return $false
    }

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    Write-Success "Build completed successfully!"
    Write-Info "Build duration: $([Math]::Floor($duration/60))m $([Math]::Floor($duration%60))s"
    Log-Message "INFO" "Build completed successfully in $($duration)s"

    return $true
}

function Verify-APK {
    Write-Step "Verifying APK generation..."

    $apkPath = Get-ChildItem -Path "$ScriptDir\app\build\outputs\apk" -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($apkPath) {
        $apkSize = [Math]::Round(($apkPath.Length / 1MB), 2)
        Write-Success "APK found: $($apkPath.FullName)"
        Write-Info "APK size: $apkSize MB"

        Write-Host ""
        Write-Info "Installation options:"
        Write-Host "  1) Install on connected device (adb install)"
        Write-Host "  2) Copy to Desktop"
        Write-Host "  3) Show file location"
        Write-Host "  4) Skip"

        $choice = Read-Host "Select option (1-4)"
        switch ($choice) {
            "1" {
                if (Get-Command adb -ErrorAction SilentlyContinue) {
                    Write-Info "Installing on device..."
                    adb install "$($apkPath.FullName)"
                }
                else {
                    Write-Warning "ADB not found in PATH"
                }
            }
            "2" {
                Copy-Item -Path $apkPath.FullName -Destination "$env:USERPROFILE\Desktop\" -Force
                Write-Success "Copied to Desktop"
            }
            "3" {
                Write-Info "APK location: $($apkPath.FullName)"
                explorer.exe /select,$($apkPath.FullName)
            }
            default {
                Write-Info "Skipped"
            }
        }

        return $true
    }
    else {
        Write-Warning "APK not found after build"
        return $false
    }
}

function Show-BuildStats {
    Write-Header "Build Statistics"

    Write-Host "Build Log: $BuildLog"
    Write-Host ""

    $apkFiles = Get-ChildItem -Path "$ScriptDir\app\build\outputs\apk" -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue

    if ($apkFiles) {
        Write-Host "Generated APKs:"
        foreach ($apk in $apkFiles) {
            $size = [Math]::Round(($apk.Length / 1MB), 2)
            Write-Host "  - $($apk.Name) ($size MB)"
        }
    }

    Write-Host ""
    Write-Success "Build completed successfully!"
}

function Show-Help {
    $help = @"
SWORDCOMM Android Build - Interactive Full Build Script (Windows)

Usage:
  .\build-interactive.ps1 [OPTIONS]

Options:
  -Help              Show this help message
  -NoInteractive     Use default build settings
  -Variant VARIANT   Specify build variant directly
  -SkipTests         Skip unit tests
  -SkipLint          Skip linting
  -Clean             Force clean build
  -Verbose           Enable verbose output
  -NoDaemon          Disable Gradle daemon

Build Variants:
  - prodGmsWebsiteDebug       (Production, GMS, Website, Debug)
  - prodGmsWebsiteRelease     (Production, GMS, Website, Release)
  - prodFossWebsiteDebug      (Production, FOSS, Website, Debug)
  - prodFossWebsiteRelease    (Production, FOSS, Website, Release)
  - stagingGmsWebsiteDebug    (Staging, GMS, Website, Debug)
  - stagingGmsWebsiteRelease  (Staging, GMS, Website, Release)

Examples:
  .\build-interactive.ps1                                    # Interactive menu
  .\build-interactive.ps1 -Variant prodGmsWebsiteRelease -Clean
  .\build-interactive.ps1 -NoInteractive -SkipTests -Verbose

Output:
  Build logs are saved to: build-yyyyMMdd-HHmmss.log
"@

    Write-Host $help -ForegroundColor $ColorInfo
}

################################################################################
# Main Script
################################################################################

function Main {
    # Handle parameters
    if ($Help) {
        Show-Help
        exit 0
    }

    if ($Variant) {
        $script:BuildVariant = $Variant
    }

    if ($SkipTests) {
        $script:RunTests = $false
    }

    if ($SkipLint) {
        $script:RunLint = $false
    }

    if ($Clean) {
        $script:CleanBuild = $true
    }

    if ($Verbose) {
        $script:VerboseOutput = $true
    }

    if ($NoDaemon) {
        $script:DaemonMode = $false
    }

    Write-Header "SWORDCOMM Android Build System"
    Write-Info "Build log: $BuildLog"

    # Verify prerequisites
    if (-not (Verify-Prerequisites)) {
        Write-Error-Custom "Prerequisites check failed"
        exit 1
    }

    Read-Host "Press Enter to continue"

    # Interactive menu
    if (-not $NoInteractive) {
        if (-not (Interactive-Menu)) {
            exit 1
        }
    }
    else {
        Write-Info "Using default/provided settings..."
        Write-Host "Build Variant: $script:BuildVariant"
        Read-Host "Press Enter to start build"
    }

    # Run build
    if (-not (Build-Project)) {
        Write-Error-Custom "Build failed. See $BuildLog for details."
        exit 1
    }

    # Verify APK
    Verify-APK

    # Show statistics
    Show-BuildStats

    Write-Success "Build process completed!"
    Write-Info "Log saved to: $BuildLog"
}

# Run main
Main
