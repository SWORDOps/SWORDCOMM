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
$LogFile = Join-Path $ScriptDir "bootstrap-build.log"

# Configuration
$MaxRetries = 4
$RetryDelay = 2

# Error tracking
$Errors = @()

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

function Log-Message {
    param([string]$Level, [string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
}

function Add-Error {
    param([string]$Error)

    $Errors += $Error
    Log-Message "ERROR" $Error
    Write-Error-Custom $Error
}

function Cleanup-OnError {
    Write-Error-Custom "Script failed with errors"
    Write-Host ""

    if ($Errors.Count -gt 0) {
        Write-Host "Errors encountered:" -ForegroundColor Red
        foreach ($error in $Errors) {
            Write-Host "  ✗ $error"
        }
    }

    Write-Host ""
    Write-Info "Full log saved to: $LogFile"
    Write-Info "  Run: Get-Content $LogFile -Tail 50"

    exit 1
}

function Invoke-RetryWithBackoff {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Description = "Operation"
    )

    $attempt = 1
    $delay = $RetryDelay

    while ($attempt -le $MaxRetries) {
        try {
            & $ScriptBlock
            return $true
        }
        catch {
            if ($attempt -lt $MaxRetries) {
                Write-Warning "Attempt $attempt failed: $_"
                Write-Warning "Retrying in ${delay}s... (attempt $($attempt + 1)/$MaxRetries)"
                Start-Sleep -Seconds $delay
                $delay = $delay * 2
            }
            else {
                Add-Error "Command failed after $MaxRetries attempts: $Description - $_"
                return $false
            }
            $attempt++
        }
    }

    return $false
}

function Validate-FileExists {
    param([string]$Path, [string]$FriendlyName = $Path)

    if (-not (Test-Path -PathType Leaf $Path)) {
        Add-Error "File not found: $FriendlyName ($Path)"
        return $false
    }
    return $true
}

function Validate-DirectoryExists {
    param([string]$Path, [string]$FriendlyName = $Path)

    if (-not (Test-Path -PathType Container $Path)) {
        Add-Error "Directory not found: $FriendlyName ($Path)"
        return $false
    }
    return $true
}

function Verify-JavaInstallation {
    Write-Step "Verifying Java installation..."

    if (-not (Test-Command java)) {
        Add-Error "Java executable not found in PATH"
        return $false
    }

    try {
        $javaVersion = java -version 2>&1 | Out-String
        Write-Success "Java installation verified"
        Write-Info "Java: $($javaVersion.Split([Environment]::NewLine)[0])"
        return $true
    }
    catch {
        Add-Error "Failed to verify Java installation: $_"
        return $false
    }
}

function Verify-SdkInstallation {
    Write-Step "Verifying Android SDK installation..."

    if (-not (Validate-DirectoryExists $AndroidHome "Android SDK")) {
        return $false
    }

    if (-not (Validate-DirectoryExists "$AndroidHome\platforms" "SDK platforms")) {
        return $false
    }

    if (-not (Validate-DirectoryExists "$AndroidHome\build-tools" "Build tools")) {
        return $false
    }

    if (-not (Validate-DirectoryExists "$AndroidHome\ndk" "NDK")) {
        return $false
    }

    # Check adb binary directly instead of via PATH (PATH not updated yet during first install)
    if (-not (Test-Path "$AndroidHome\platform-tools\adb.exe")) {
        Add-Error "ADB tool not found at $AndroidHome\platform-tools\adb.exe"
        return $false
    }

    Write-Success "Android SDK installation verified"
    return $true
}

function Run-PreflightChecks {
    Write-Header "Pre-flight Checks"

    $checksTotal = 0
    $checksPassed = 0

    # Check disk space
    $checksTotal++
    if (Check-DiskSpace) {
        $checksPassed++
    }
    else {
        Write-Warning "Disk space check failed"
    }

    # Check for required tools
    $checksTotal++
    if (Get-Command -Name curl -ErrorAction SilentlyContinue) {
        Write-Success "curl is available"
        $checksPassed++
    }
    else {
        Write-Warning "curl not found (using PowerShell's Invoke-WebRequest instead)"
        $checksPassed++
    }

    Write-Info "Pre-flight checks: $checksPassed/$checksTotal passed"

    if ($checksPassed -lt ($checksTotal - 1)) {
        Add-Error "Critical checks failed"
        return $false
    }

    return $true
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
        try {
            $version = java -version 2>&1 | Select-String 'version' | Select-Object -First 1 -ExpandProperty Line
            Write-Info "Java is already installed: $version"

            if ($version -match '"(\d+)') {
                $majorVersion = [int]$matches[1]
                if ($majorVersion -ge 17) {
                    Write-Success "Java version is compatible"
                    if (Verify-JavaInstallation) {
                        return $true
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to check Java version: $_"
        }
    }

    Write-Info "Downloading Java 17 from Adoptium..."
    Write-Info "This may take 3-10 minutes depending on connection speed"

    # Download from Adoptium
    $downloadUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_11.msi"
    $outputPath = "$env:TEMP\java17-installer.msi"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Use retry logic for download
        $downloaded = $false
        for ($i = 1; $i -le $MaxRetries; $i++) {
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing -ErrorAction Stop
                $downloaded = $true
                break
            }
            catch {
                if ($i -lt $MaxRetries) {
                    Write-Warning "Download attempt $i failed, retrying in $($RetryDelay * ($i - 1))s..."
                    Start-Sleep -Seconds ($RetryDelay * ($i - 1))
                }
                else {
                    Add-Error "Failed to download Java 17 installer after $MaxRetries attempts: $_"
                    return $false
                }
            }
        }

        if (-not $downloaded) {
            return $false
        }

        Write-Success "Java 17 installer downloaded"

        if (-not (Validate-FileExists $outputPath "Java 17 MSI")) {
            return $false
        }

        Write-Info "Installing Java 17... (this may take 5-10 minutes)"
        Log-Message "INFO" "Starting Java 17 MSI installation"

        $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$outputPath`" /qb" -Wait -PassThru
        Log-Message "INFO" "Java 17 installation completed with exit code: $($process.ExitCode)"

        if ($process.ExitCode -eq 0) {
            Write-Success "Java 17 installed successfully"
            Remove-Item $outputPath -Force -ErrorAction SilentlyContinue

            if (Verify-JavaInstallation) {
                return $true
            }
            else {
                Add-Error "Java verification failed after installation"
                return $false
            }
        }
        else {
            Add-Error "Java installation failed with exit code: $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Add-Error "Failed to install Java: $_"
        return $false
    }
}

function Setup-AndroidSdk {
    Write-Step "Setting up Android SDK..."

    Write-Info "SDK root: $SdkRoot"
    Write-Info "This may take 5-15 minutes depending on connection speed"

    # Create directories
    try {
        if (-not (Test-Path $SdkRoot)) {
            New-Item -ItemType Directory -Path $SdkRoot -Force | Out-Null
            Write-Info "Created SDK directory: $SdkRoot"
        }

        $cmdlineToolsPath = "$SdkRoot\cmdline-tools"
        if (-not (Test-Path $cmdlineToolsPath)) {
            New-Item -ItemType Directory -Path $cmdlineToolsPath -Force | Out-Null
        }
    }
    catch {
        Add-Error "Failed to create SDK directories: $_"
        return $false
    }

    Write-Info "Downloading Android SDK command-line tools from Google..."

    $downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip"
    $zipPath = "$env:TEMP\android-cmdline-tools.zip"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Download with retry logic
        $downloaded = $false
        for ($i = 1; $i -le $MaxRetries; $i++) {
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
                $downloaded = $true
                break
            }
            catch {
                if ($i -lt $MaxRetries) {
                    Write-Warning "Download attempt $i failed, retrying in $($RetryDelay * ($i - 1))s..."
                    Start-Sleep -Seconds ($RetryDelay * ($i - 1))
                }
                else {
                    Add-Error "Failed to download SDK command-line tools after $MaxRetries attempts: $_"
                    return $false
                }
            }
        }

        if (-not $downloaded) {
            return $false
        }

        Write-Success "Downloaded Android SDK command-line tools"

        if (-not (Validate-FileExists $zipPath "SDK ZIP")) {
            return $false
        }

        Write-Info "Extracting Android SDK command-line tools..."
        Expand-Archive -Path $zipPath -DestinationPath "$SdkRoot\cmdline-tools" -Force
        Log-Message "INFO" "Extracted SDK tools to $SdkRoot\cmdline-tools"

        # Verify extraction
        if (-not (Test-Path "$SdkRoot\cmdline-tools\cmdline-tools\bin")) {
            Add-Error "SDK extraction failed - cmdline-tools/bin directory not found"
            return $false
        }

        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

        Write-Success "Android SDK command-line tools installed"
        return $true
    }
    catch {
        Add-Error "Failed to setup Android SDK: $_"
        return $false
    }
}

function Install-SdkPackages {
    Write-Step "Installing Android SDK platforms and tools..."
    Write-Info "This may take 20-40 minutes (large downloads)"

    $sdkmanager = "$SdkRoot\cmdline-tools\cmdline-tools\bin\sdkmanager.bat"

    if (-not (Validate-FileExists $sdkmanager "SDK Manager")) {
        Add-Error "SDK Manager not found, SDK setup may have failed"
        return $false
    }

    try {
        Write-Info "Accepting Android SDK licenses..."
        try {
            & $sdkmanager --licenses 2>$null | Out-Null
        }
        catch {
            Write-Warning "License acceptance may have failed, continuing..."
        }

        Write-Info "Installing Android SDK API $ANDROID_SDK_VERSION..."
        Log-Message "INFO" "Starting SDK API $ANDROID_SDK_VERSION installation"
        if (($LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            Add-Error "Failed to install Android SDK platforms"
            return $false
        }
        & $sdkmanager "platforms;android-$ANDROID_SDK_VERSION"

        Write-Info "Installing Build Tools $ANDROID_BUILD_TOOLS..."
        Log-Message "INFO" "Starting Build Tools installation"
        & $sdkmanager "build-tools;$ANDROID_BUILD_TOOLS"
        if (($LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            Add-Error "Failed to install Build Tools"
            return $false
        }

        Write-Info "Installing NDK $ANDROID_NDK_VERSION..."
        Log-Message "INFO" "Starting NDK installation"
        & $sdkmanager "ndk;$ANDROID_NDK_VERSION"
        if (($LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            Add-Error "Failed to install NDK"
            return $false
        }

        Write-Info "Installing platform tools..."
        Log-Message "INFO" "Starting platform-tools installation"
        & $sdkmanager "platform-tools"
        if (($LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            Add-Error "Failed to install platform tools"
            return $false
        }

        Write-Info "Installing system images (optional)..."
        try {
            & $sdkmanager "system-images;android-$ANDROID_SDK_VERSION;google_apis;x86_64" 2>$null | Out-Null
        }
        catch {
            Write-Warning "System images installation failed (non-critical), continuing..."
        }

        Log-Message "INFO" "Verifying SDK installation"
        if (Verify-SdkInstallation) {
            Write-Success "SDK packages installed"
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Add-Error "Failed to install SDK packages: $_"
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

    try {
        Set-Location $ScriptDir
    }
    catch {
        Add-Error "Failed to change to project directory: $_"
        return $false
    }

    if (-not (Validate-FileExists ".\gradlew.bat" "Gradle wrapper")) {
        if (-not (Validate-FileExists ".\gradlew" "Gradle wrapper")) {
            return $false
        }
    }

    if (-not (Validate-DirectoryExists ".\app" "App directory")) {
        return $false
    }

    Write-Info "Build variant: $Variant"
    Write-Info "This is a full build and may take 10-30 minutes on first run"
    Write-Info "Logs: Get-Content $LogFile -Tail 50"

    $gradleFlags = "-PCI=true"
    if ($CiMode) {
        $gradleFlags = "$gradleFlags -x lint"
    }

    $gradleWrapper = ".\gradlew.bat"
    if (-not (Test-Path $gradleWrapper)) {
        $gradleWrapper = ".\gradlew"
    }

    $arguments = $gradleFlags.Split(" ") + @(":app:assemble$Variant")

    try {
        Log-Message "INFO" "Starting Gradle build with variant: $Variant"
        Write-Info "Running Gradle build..."

        & $gradleWrapper $arguments 2>&1 | Tee-Object -FilePath $LogFile -Append
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Success "Build completed successfully!"
            Log-Message "INFO" "Gradle build completed successfully"

            # Verify APK was created
            $apkFound = $false
            $apkPath = ""

            # Try to find release APK
            $releaseApks = Get-ChildItem -Path ".\app\build\outputs\apk" -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*release*" }
            if ($releaseApks) {
                $apkPath = $releaseApks[0].FullName
                $apkFound = $true
            }

            # If no release APK, try debug
            if (-not $apkFound) {
                $debugApks = Get-ChildItem -Path ".\app\build\outputs\apk" -Filter "*.apk" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*debug*" }
                if ($debugApks) {
                    $apkPath = $debugApks[0].FullName
                    $apkFound = $true
                }
            }

            if ($apkFound) {
                $apkSize = ((Get-Item $apkPath).Length / 1MB)
                Write-Success "APK generated: $apkPath"
                Write-Info "APK size: $([Math]::Round($apkSize, 2))MB"
                Write-Host ""
                Write-Info "Next steps:"
                Write-Host "  1. Install on device: adb install `"$apkPath`""
                Write-Host "  2. Or push to device for sideloading"
                Log-Message "INFO" "APK successfully created: $apkPath ($apkSize MB)"
                return $true
            }
            else {
                Add-Error "APK file not found after successful build"
                return $false
            }
        }
        else {
            Add-Error "Gradle build failed for variant: $Variant (exit code: $exitCode)"
            Write-Host ""
            Write-Error-Custom "Check the logs above for detailed error information"
            Log-Message "ERROR" "Gradle build failed with exit code: $exitCode"
            return $false
        }
    }
    catch {
        Add-Error "Build failed: $_"
        Log-Message "ERROR" "Build exception: $_"
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

# Initialize log file
@"
================================================================================
SWORDCOMM Android Build Bootstrap - $(Get-Date)
OS: Windows $([System.Environment]::OSVersion.VersionString)
PowerShell: $($PSVersionTable.PSVersion)
================================================================================
"@ | Out-File -FilePath $LogFile -Force

Log-Message "INFO" "Starting SWORDCOMM Android Build Bootstrap"
Log-Message "INFO" "Help=$Help JavaOnly=$JavaOnly SdkOnly=$SdkOnly Build=$Build Variant=$Variant SkipGradle=$SkipGradle CiMode=$CiMode"

if ($Help) {
    Show-Help
    exit 0
}

Write-Header "SWORDCOMM Android Build Bootstrap for Windows"
Write-Info "Log file: $LogFile"

# Check admin privileges (recommended)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Warning "This script is recommended to be run as Administrator"
    Write-Info "Some features may not work without elevated privileges"
    Log-Message "WARNING" "Script not running with Administrator privileges"
}

# Run pre-flight checks
if (-not (Run-PreflightChecks)) {
    Cleanup-OnError
}

# Java installation
if (-not $SdkOnly) {
    Write-Header "Java Installation"

    if (Install-Java) {
        # Verify installation
        if (-not (Check-JavaVersion)) {
            Cleanup-OnError
        }
    }
    else {
        Cleanup-OnError
    }
}

# Android SDK installation
if (-not $JavaOnly) {
    Write-Header "Android SDK Installation"

    if (-not (Test-Path $AndroidHome)) {
        Log-Message "INFO" "Installing Android SDK"

        if (-not (Setup-AndroidSdk)) {
            Cleanup-OnError
        }

        if (-not (Install-SdkPackages)) {
            Cleanup-OnError
        }
    }
    else {
        Write-Info "Android SDK already installed at $AndroidHome"
        Log-Message "INFO" "SDK already present, verifying installation"

        if (-not (Verify-SdkInstallation)) {
            Cleanup-OnError
        }
    }

    Setup-Environment
    Log-Message "INFO" "Environment variables configured"
}

# Gradle check
if (-not (Check-Gradle)) {
    Cleanup-OnError
}

# Build project if requested
if ($Build -and -not $SkipGradle) {
    Log-Message "INFO" "Starting Gradle build for variant: $Variant"

    if (-not (Build-Project)) {
        Cleanup-OnError
    }
}

# Show summary
Show-Summary

Log-Message "INFO" "Bootstrap script completed successfully"
Write-Success "All tasks completed!"
