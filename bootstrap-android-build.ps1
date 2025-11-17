# SWORDCOMM Android Build Bootstrap Script for Windows (PowerShell)
#
# This script sets up a complete Android development environment on Windows
#
# Requirements:
#   - Windows 10 or later
#   - PowerShell 5.0 or later (included with Windows 10+)
#   - ~50GB free disk space
#   - 8GB RAM minimum (16GB recommended)
#
# Usage:
#   1. Open PowerShell as Administrator
#   2. Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   3. cd C:\path\to\SWORDCOMM
#   4. .\bootstrap-android-build.ps1 [OPTIONS]
#
# Options:
#   -Help              Show this help message
#   -JavaOnly          Install only Java (skip SDK)
#   -SdkOnly           Install only Android SDK (skip Java)
#   -Build             Automatically start build after setup
#   -Variant VARIANT   Build specific variant (e.g., prodGmsWebsiteRelease)
#   -SkipGradle        Skip Gradle build after setup
#   -CiMode            Setup for CI/CD environments

param(
    [switch]$Help,
    [switch]$JavaOnly,
    [switch]$SdkOnly,
    [switch]$Build,
    [string]$Variant = "prodGmsWebsiteDebug",
    [switch]$SkipGradle,
    [switch]$CiMode
)

# Configuration
$JAVA_VERSION = "17"
$ANDROID_SDK_VERSION = "35"
$ANDROID_BUILD_TOOLS = "35.0.0"
$ANDROID_NDK_VERSION = "28.0.13004108"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AndroidHome = "$env:USERPROFILE\Android\sdk"
$SdkRoot = $AndroidHome

# Color codes
function Write-Header {
    Write-Host "`n========================================================================" -ForegroundColor Cyan
    Write-Host $args -ForegroundColor Cyan
    Write-Host "========================================================================`n" -ForegroundColor Cyan
}

function Write-Success {
    Write-Host "✓ $args" -ForegroundColor Green
}

function Write-Info {
    Write-Host "ℹ $args" -ForegroundColor Blue
}

function Write-Warning {
    Write-Host "⚠ $args" -ForegroundColor Yellow
}

function Write-Error-Custom {
    Write-Host "✗ $args" -ForegroundColor Red
}

function Write-Step {
    Write-Host "`n→ $args" -ForegroundColor Yellow
}

function Show-Help {
    Write-Host @"
SWORDCOMM Android Build Bootstrap for Windows

Usage:
  .\bootstrap-android-build.ps1 [OPTIONS]

Options:
  -Help              Show this help message
  -JavaOnly          Install only Java (skip SDK)
  -SdkOnly           Install only Android SDK (skip Java)
  -Build             Automatically start build after setup
  -Variant VARIANT   Build specific variant (e.g., prodGmsWebsiteRelease)
  -SkipGradle        Skip Gradle build after setup
  -CiMode            Setup for CI/CD environments

Requirements:
  - Windows 10 or later
  - PowerShell 5.0 or later
  - ~50GB free disk space
  - Administrator privileges recommended

Examples:
  .\bootstrap-android-build.ps1
  .\bootstrap-android-build.ps1 -Build
  .\bootstrap-android-build.ps1 -Variant prodGmsWebsiteRelease -Build
"@
}

function Check-DiskSpace {
    Write-Step "Checking disk space..."

    $drive = ([System.IO.Path]::GetPathRoot($ScriptDir))
    $diskInfo = Get-Volume | Where-Object { $_.DriveLetter -eq $drive.Substring(0, 1) }

    if ($diskInfo) {
        $availableGB = $diskInfo.SizeRemaining / 1GB
        $requiredGB = 50

        if ($availableGB -lt $requiredGB) {
            Write-Warning "Low disk space: $([Math]::Round($availableGB))GB available ($requiredGB`GB recommended)"
            return $false
        }

        Write-Success "Disk space check: $([Math]::Round($availableGB))GB available"
        return $true
    }

    return $true
}

function Test-Command {
    param([string]$Command)

    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Install-Java {
    Write-Step "Installing Java 17..."

    # Check if Java is already installed
    if (Test-Command java) {
        $javaVersion = java -version 2>&1 | Select-String 'version' | Select-Object -First 1
        Write-Info "Java is already installed: $javaVersion"

        # Check version
        $version = java -version 2>&1 | Select-String 'version' | Select-Object -First 1 -ExpandProperty Line
        if ($version -match '"(\d+)') {
            $majorVersion = [int]$matches[1]
            if ($majorVersion -ge 17) {
                Write-Success "Java version is compatible"
                return $true
            }
        }
    }

    Write-Info "Downloading Java 17..."

    # Download from Adoptium
    $downloadUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_11.msi"
    $outputPath = "$env:TEMP\java17-installer.msi"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing
        Write-Success "Java 17 installer downloaded"

        Write-Info "Installing Java 17... (this may take a few minutes)"
        $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$outputPath`" /qb" -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Success "Java 17 installed successfully"
            Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
            return $true
        }
        else {
            Write-Error-Custom "Java installation failed with exit code: $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Failed to install Java: $_"
        return $false
    }
}

function Setup-AndroidSdk {
    Write-Step "Setting up Android SDK..."

    Write-Info "SDK root: $SdkRoot"

    # Create directories
    New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null
    New-Item -ItemType Directory -Path "$SdkRoot\cmdline-tools" -Force | Out-Null

    Write-Info "Downloading Android SDK command-line tools..."

    $downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
    $zipPath = "$env:TEMP\android-cmdline-tools.zip"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
        Write-Success "Downloaded Android SDK command-line tools"

        Write-Info "Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath "$SdkRoot\cmdline-tools" -Force
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        Write-Success "Android SDK command-line tools installed"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to setup Android SDK: $_"
        return $false
    }
}

function Install-SdkPackages {
    Write-Step "Installing Android SDK platforms and tools..."

    $sdkmanager = "$SdkRoot\cmdline-tools\cmdline-tools\bin\sdkmanager.bat"

    if (-not (Test-Path $sdkmanager)) {
        Write-Error-Custom "sdkmanager not found at $sdkmanager"
        return $false
    }

    try {
        Write-Info "Accepting licenses..."
        & $sdkmanager --licenses | Out-Null

        Write-Info "Installing platforms..."
        & $sdkmanager "platforms;android-$ANDROID_SDK_VERSION"

        Write-Info "Installing build tools..."
        & $sdkmanager "build-tools;$ANDROID_BUILD_TOOLS"

        Write-Info "Installing NDK..."
        & $sdkmanager "ndk;$ANDROID_NDK_VERSION"

        Write-Info "Installing platform tools..."
        & $sdkmanager "platform-tools"

        Write-Success "SDK packages installed"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to install SDK packages: $_"
        return $false
    }
}

function Setup-Environment {
    Write-Step "Setting up environment variables..."

    # Set environment variables
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $AndroidHome, "User")
    [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $AndroidHome, "User")

    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$AndroidHome*") {
        $newPath = "$AndroidHome\cmdline-tools\cmdline-tools\bin;$AndroidHome\platform-tools;$AndroidHome\ndk\$ANDROID_NDK_VERSION;$userPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    }

    # Set for current session
    $env:ANDROID_HOME = $AndroidHome
    $env:ANDROID_SDK_ROOT = $AndroidHome
    $env:PATH = "$AndroidHome\cmdline-tools\cmdline-tools\bin;$AndroidHome\platform-tools;$AndroidHome\ndk\$ANDROID_NDK_VERSION;$env:PATH"

    Write-Success "Environment variables configured"
    Write-Info "ANDROID_HOME: $AndroidHome"
}

function Check-JavaVersion {
    Write-Step "Checking Java version..."

    if (-not (Test-Command java)) {
        Write-Error-Custom "Java is not installed"
        return $false
    }

    $javaVersion = java -version 2>&1 | Select-String 'version' | Select-Object -First 1
    Write-Success "Java version: $javaVersion"
    return $true
}

function Check-Gradle {
    Write-Step "Checking Gradle..."

    if (Test-Path "$ScriptDir\gradlew.bat") {
        Write-Success "Gradle wrapper found"
        return $true
    }
    elseif (Test-Path "$ScriptDir\gradlew") {
        Write-Success "Gradle wrapper found"
        return $true
    }
    else {
        Write-Error-Custom "Gradle wrapper not found at $ScriptDir\gradlew"
        return $false
    }
}

function Build-Project {
    Write-Header "Building SWORDCOMM ($Variant)"

    Set-Location $ScriptDir

    Write-Step "Running Gradle build..."

    $gradleFlags = "-PCI=true"

    $gradleWrapper = ".\gradlew.bat"
    if (-not (Test-Path $gradleWrapper)) {
        $gradleWrapper = ".\gradlew"
    }

    $arguments = $gradleFlags.Split(" ") + @(":app:assemble$Variant")

    try {
        & $gradleWrapper $arguments
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Build completed successfully!"
            return $true
        }
        else {
            Write-Error-Custom "Build failed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Build failed: $_"
        return $false
    }
}

function Show-Summary {
    Write-Header "Setup Summary"

    Write-Host "Environment Configuration:" -ForegroundColor Cyan
    Write-Host "  OS: Windows"
    Write-Host "  Processor: $env:PROCESSOR_ARCHITECTURE"
    Write-Host "  Java: $(if (Test-Command java) { java -version 2>&1 | Select-Object -First 1 } else { 'Not installed' })"
    Write-Host "  ANDROID_HOME: $env:ANDROID_HOME"

    if (Test-Path $AndroidHome) {
        Write-Host ""
        Write-Host "Android SDK Components:" -ForegroundColor Cyan
        Write-Host "  Build Tools: $ANDROID_BUILD_TOOLS"
        Write-Host "  Platform: android-$ANDROID_SDK_VERSION"
        Write-Host "  NDK: $ANDROID_NDK_VERSION"
    }

    Write-Host ""
    Write-Host "Project Configuration:" -ForegroundColor Cyan
    Write-Host "  Project Directory: $ScriptDir"
    Write-Host "  Gradle Wrapper: $(if (Test-Path "$ScriptDir\gradlew.bat") { 'Present' } else { 'Not Found' })"
    Write-Host "  Build Variant: $Variant"

    Write-Host ""
    Write-Success "Bootstrap setup complete!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Restart PowerShell or run: `$profile | % { . `$_ }" -ForegroundColor Cyan
    Write-Host "  2. Start building: .\gradlew.bat assembleDebug" -ForegroundColor Cyan
    Write-Host "  3. Or use: .\build.sh (if available)" -ForegroundColor Cyan
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

# Check admin privileges (recommended)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "This script is recommended to be run as Administrator"
    Write-Info "Some features may not work without elevated privileges"
}

Write-Header "SWORDCOMM Android Build Bootstrap for Windows"

Check-DiskSpace | Out-Null

# Java installation
if (-not $SdkOnly) {
    Write-Header "Java Installation"

    if (-not (Install-Java)) {
        exit 1
    }

    # Verify installation
    if (-not (Check-JavaVersion)) {
        exit 1
    }
}

# Android SDK installation
if (-not $JavaOnly) {
    Write-Header "Android SDK Installation"

    if (-not (Test-Path $AndroidHome)) {
        if (-not (Setup-AndroidSdk)) {
            exit 1
        }

        if (-not (Install-SdkPackages)) {
            exit 1
        }
    }
    else {
        Write-Info "Android SDK already installed at $AndroidHome"
    }

    Setup-Environment
}

# Gradle check
if (-not (Check-Gradle)) {
    exit 1
}

# Build project if requested
if ($Build -and -not $SkipGradle) {
    if (-not (Build-Project)) {
        exit 1
    }
}

# Show summary
Show-Summary
