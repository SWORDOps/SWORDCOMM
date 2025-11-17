#!/bin/bash

################################################################################
# SWORDCOMM Android Build Bootstrap Script
#
# This script sets up a complete Android development environment and builds
# the SWORDCOMM Android application (Molly).
#
# Supported Platforms:
#   - macOS (Intel/Apple Silicon)
#   - Linux (Ubuntu, Debian, Fedora, etc.)
#   - Windows (WSL 2 recommended)
#
# Requirements:
#   - ~50GB free disk space
#   - 8GB RAM minimum (16GB recommended)
#   - Good internet connection
#
# Usage:
#   chmod +x bootstrap-android-build.sh
#   ./bootstrap-android-build.sh [OPTIONS]
#
# Options:
#   --help              Show this help message
#   --java-only         Install only Java (skip SDK)
#   --sdk-only          Install only Android SDK (skip Java)
#   --build             Automatically start build after setup
#   --variant VARIANT   Build specific variant (e.g., prodGmsWebsiteRelease)
#   --skip-gradle       Skip Gradle build after setup
#   --ci-mode           Setup for CI/CD environments
#
################################################################################

set -o pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/bootstrap-build.log"
JAVA_VERSION="17"
JAVA_BUILD_VERSION="17.0.13_11"
ANDROID_SDK_VERSION="35"
ANDROID_BUILD_TOOLS="35.0.0"
ANDROID_NDK_VERSION="28.0.13004108"
GRADLE_VERSION="8.9"
GRADLE_WRAPPER_VERSION="8.9.0"
MAX_RETRIES=4
RETRY_DELAY=2

# Error tracking
ERRORS=()
EXIT_CODE=0

# Determine OS
OS="unknown"
ARCH="unknown"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    if [[ "$(uname -m)" == "x86_64" ]]; then
        ARCH="x86_64"
    elif [[ "$(uname -m)" == "aarch64" ]]; then
        ARCH="aarch64"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    if [[ "$(uname -m)" == "arm64" ]]; then
        ARCH="arm64"
    else
        ARCH="x86_64"
    fi
elif [[ "$OS_NAME" == "Windows_NT" || "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
    ARCH="x86_64"
fi

# Flags
INSTALL_JAVA=true
INSTALL_SDK=true
AUTO_BUILD=false
BUILD_VARIANT="prodGmsWebsiteDebug"
RUN_BUILD=true
CI_MODE=false

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}================================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_step() {
    echo -e "\n${YELLOW}→ $1${NC}"
}

log_message() {
    local level="$1"
    shift
    local message="$@"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

add_error() {
    local error="$1"
    ERRORS+=("$error")
    log_message "ERROR" "$error"
}

cleanup_on_error() {
    print_error "Script failed with errors"
    echo ""
    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo "Errors encountered:"
        printf '%s\n' "${ERRORS[@]}" | sed 's/^/  ✗ /'
    fi
    echo ""
    print_info "Full log saved to: $LOG_FILE"
    echo "  Run: tail -f $LOG_FILE"
    exit 1
}

trap cleanup_on_error ERR

retry_with_backoff() {
    local max_attempts="$MAX_RETRIES"
    local delay="$RETRY_DELAY"
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            print_warning "Attempt $attempt failed, retrying in ${delay}s... (attempt $((attempt+1))/$max_attempts)"
            sleep "$delay"
            delay=$((delay * 2))
        fi
        attempt=$((attempt + 1))
    done

    print_error "Command failed after $max_attempts attempts: $@"
    return 1
}

download_with_retry() {
    local url="$1"
    local output="$2"

    retry_with_backoff curl -L "$url" -o "$output" --progress-bar --retry 3 --retry-delay 1 -f
}

validate_executable() {
    local cmd="$1"
    local friendly_name="${2:-$cmd}"

    if ! command -v "$cmd" &> /dev/null; then
        add_error "$friendly_name not found in PATH"
        return 1
    fi
    return 0
}

validate_file() {
    local filepath="$1"
    local friendly_name="${2:-$filepath}"

    if [ ! -f "$filepath" ]; then
        add_error "File not found: $friendly_name ($filepath)"
        return 1
    fi
    return 0
}

validate_directory() {
    local dirpath="$1"
    local friendly_name="${2:-$dirpath}"

    if [ ! -d "$dirpath" ]; then
        add_error "Directory not found: $friendly_name ($dirpath)"
        return 1
    fi
    return 0
}

verify_java_installation() {
    print_step "Verifying Java installation..."

    if ! validate_executable "java" "Java executable"; then
        return 1
    fi

    if ! validate_executable "javac" "Java compiler"; then
        add_error "Java compiler not found, installation may be incomplete"
        return 1
    fi

    print_success "Java installation verified"
    return 0
}

verify_sdk_installation() {
    print_step "Verifying Android SDK installation..."

    local sdk_root="$HOME/Android/sdk"

    validate_directory "$sdk_root" "Android SDK" || return 1
    validate_directory "$sdk_root/platforms" "SDK platforms" || return 1
    validate_directory "$sdk_root/build-tools" "Build tools" || return 1
    validate_directory "$sdk_root/ndk" "NDK" || return 1

    # Check adb binary directly instead of via PATH (PATH not updated yet during first install)
    if [ ! -f "$sdk_root/platform-tools/adb" ]; then
        add_error "ADB tool not found at $sdk_root/platform-tools/adb"
        return 1
    fi

    print_success "Android SDK installation verified"
    return 0
}

show_help() {
    head -n 40 "$0" | tail -n +2 | sed 's/^# //'
}

detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

check_disk_space() {
    local required_gb=50
    local available_gb

    if ! available_gb=$(($(df "$SCRIPT_DIR" 2>/dev/null | awk 'NR==2 {print $4}') / 1024 / 1024)); then
        add_error "Failed to check disk space"
        return 1
    fi

    if [ "$available_gb" -lt "$required_gb" ]; then
        print_warning "Low disk space: ${available_gb}GB available (${required_gb}GB recommended)"
        print_warning "Build may fail due to insufficient space"
        print_warning "Please free up at least $((required_gb - available_gb))GB more"
        return 1
    fi
    print_success "Disk space check: ${available_gb}GB available"
    return 0
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_info "$1 is not installed"
        return 1
    fi
}

install_java_macos() {
    print_step "Installing Java 17 via Homebrew..."

    if ! validate_executable "brew" "Homebrew"; then
        add_error "Homebrew is required for macOS. Install from https://brew.sh"
        return 1
    fi

    if ! brew install openjdk@17; then
        add_error "Failed to install openjdk@17 via Homebrew"
        return 1
    fi

    local brew_path
    if ! brew_path=$(brew --prefix openjdk@17 2>/dev/null); then
        add_error "Failed to determine Homebrew openjdk@17 installation path"
        return 1
    fi

    # Link java
    if ! sudo ln -sfn "$brew_path/libexec/openjdk.jdk/Contents/Home" /Library/Java/JavaVirtualMachines/openjdk-17.jdk; then
        add_error "Failed to create Java symlink"
        return 1
    fi

    if ! verify_java_installation; then
        return 1
    fi

    print_success "Java 17 installed"
}

install_java_linux() {
    print_step "Installing Java 17..."
    local distro
    distro=$(detect_linux_distro)

    case "$distro" in
        ubuntu|debian)
            if ! sudo apt-get update; then
                add_error "Failed to update package lists"
                return 1
            fi
            if ! sudo apt-get install -y openjdk-17-jdk openjdk-17-source; then
                add_error "Failed to install Java 17 via apt-get"
                return 1
            fi
            ;;
        fedora|rhel|centos)
            if ! sudo dnf install -y java-17-openjdk java-17-openjdk-devel; then
                add_error "Failed to install Java 17 via dnf"
                return 1
            fi
            ;;
        arch)
            if ! sudo pacman -S --noconfirm jdk17-openjdk; then
                add_error "Failed to install Java 17 via pacman"
                return 1
            fi
            ;;
        *)
            add_error "Unsupported Linux distribution: $distro"
            print_info "Please install OpenJDK 17 manually and run this script again"
            print_info "See: https://adoptium.net/ or https://openjdk.org/"
            return 1
            ;;
    esac

    if ! verify_java_installation; then
        return 1
    fi

    print_success "Java 17 installed"
}

install_java_windows() {
    print_error "Windows detected. Please install Java manually:"
    echo "  1. Download from: https://adoptium.net/ (select Java 17)"
    echo "  2. Run the installer and follow the instructions"
    echo "  3. Run this script again"
    return 1
}

setup_android_sdk() {
    print_step "Setting up Android SDK..."

    local sdk_root="$HOME/Android/sdk"
    local cmdline_tools="$sdk_root/cmdline-tools"

    # Create directories
    if ! mkdir -p "$sdk_root"; then
        add_error "Failed to create SDK root directory: $sdk_root"
        return 1
    fi

    print_info "SDK root: $sdk_root"

    # Download and setup cmdline-tools
    local download_url
    case "$OS:$ARCH" in
        linux:x86_64|linux:aarch64)
            download_url="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
            ;;
        macos:x86_64|macos:arm64)
            download_url="https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip"
            ;;
        *)
            add_error "Unsupported platform: $OS:$ARCH"
            return 1
            ;;
    esac

    print_info "Downloading Android SDK command-line tools from Google..."
    print_info "This may take 5-15 minutes depending on connection speed"

    local tmpfile
    tmpfile=$(mktemp) || { add_error "Failed to create temporary file"; return 1; }

    if ! download_with_retry "$download_url" "$tmpfile"; then
        add_error "Failed to download Android SDK command-line tools"
        rm -f "$tmpfile"
        return 1
    fi

    # Create temp extraction directory
    local tmpextract
    tmpextract=$(mktemp -d) || { add_error "Failed to create temp directory"; return 1; }

    print_info "Extracting Android SDK command-line tools..."
    if ! unzip -q "$tmpfile" -d "$tmpextract"; then
        add_error "Failed to extract SDK tools zip file"
        rm -f "$tmpfile" "$tmpextract"
        return 1
    fi

    # The zip contains a top-level 'cmdline-tools' directory
    # We need to move it to the right location: $sdk_root/cmdline-tools/latest
    if [ ! -d "$tmpextract/cmdline-tools" ]; then
        add_error "Unexpected SDK structure: cmdline-tools directory not found in extraction"
        rm -rf "$tmpextract" "$tmpfile"
        return 1
    fi

    # Remove old cmdline-tools if it exists
    if [ -d "$cmdline_tools" ]; then
        print_info "Removing old cmdline-tools directory..."
        rm -rf "$cmdline_tools"
    fi

    # Create the cmdline-tools directory and move the extracted one to 'latest'
    mkdir -p "$cmdline_tools"
    if ! mv "$tmpextract/cmdline-tools" "$cmdline_tools/latest"; then
        add_error "Failed to move cmdline-tools to sdk location"
        rm -rf "$tmpextract" "$tmpfile"
        return 1
    fi

    # Verify the extraction worked
    if [ ! -f "$cmdline_tools/latest/bin/sdkmanager" ]; then
        add_error "SDK Manager not found at expected location: $cmdline_tools/latest/bin/sdkmanager"
        rm -rf "$tmpextract" "$tmpfile"
        return 1
    fi

    rm -rf "$tmpextract" "$tmpfile"
    print_success "Android SDK command-line tools installed"
    return 0
}

install_sdk_packages() {
    print_step "Installing Android SDK platforms and tools..."
    print_info "This may take 20-40 minutes (large downloads)"

    local sdk_root="$HOME/Android/sdk"
    local sdkmanager="$sdk_root/cmdline-tools/latest/bin/sdkmanager"

    if ! validate_file "$sdkmanager" "SDK Manager"; then
        add_error "SDK Manager not found, SDK setup may have failed"
        return 1
    fi

    # Accept all licenses
    print_info "Accepting Android SDK licenses..."
    if ! yes | "$sdkmanager" --licenses 2>/dev/null; then
        print_warning "License acceptance may have failed, continuing..."
    fi

    # Install required packages with retry
    print_info "Installing Android SDK API 35..."
    if ! retry_with_backoff "$sdkmanager" "platforms;android-$ANDROID_SDK_VERSION"; then
        add_error "Failed to install Android SDK platforms"
        return 1
    fi

    print_info "Installing Build Tools $ANDROID_BUILD_TOOLS..."
    if ! retry_with_backoff "$sdkmanager" "build-tools;$ANDROID_BUILD_TOOLS"; then
        add_error "Failed to install Build Tools"
        return 1
    fi

    print_info "Installing NDK $ANDROID_NDK_VERSION..."
    if ! retry_with_backoff "$sdkmanager" "ndk;$ANDROID_NDK_VERSION"; then
        add_error "Failed to install NDK"
        return 1
    fi

    print_info "Installing platform tools..."
    if ! retry_with_backoff "$sdkmanager" "platform-tools"; then
        add_error "Failed to install platform tools"
        return 1
    fi

    print_info "Installing system images (optional)..."
    if ! "$sdkmanager" "system-images;android-$ANDROID_SDK_VERSION;google_apis;x86_64" 2>/dev/null; then
        print_warning "System images installation failed (non-critical), continuing..."
    fi

    if ! verify_sdk_installation; then
        return 1
    fi

    print_success "SDK packages installed"
}

setup_environment() {
    print_step "Setting up environment variables..."

    local sdk_root="$HOME/Android/sdk"
    local profile_file

    # Determine shell profile
    if [[ "$SHELL" == *"zsh"* ]]; then
        profile_file="$HOME/.zshrc"
    else
        profile_file="$HOME/.bashrc"
    fi

    # Add environment variables if not already present
    if ! grep -q "ANDROID_HOME" "$profile_file"; then
        {
            echo ""
            echo "# Android SDK Configuration (added by SWORDCOMM bootstrap)"
            echo "export ANDROID_HOME=\"$sdk_root\""
            echo "export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION:\$PATH\""
            echo "export JAVA_HOME=\"\$(dirname \$(dirname \$(readlink -f \$(which java))))\""
        } >> "$profile_file"

        print_success "Environment variables added to $profile_file"
        print_info "Run: source $profile_file"
    else
        print_info "Environment variables already configured"
    fi

    # Set for current session
    export ANDROID_HOME="$sdk_root"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION:$PATH"
}

check_java_version() {
    print_step "Checking Java version..."

    if ! check_command java; then
        print_error "Java is not installed"
        return 1
    fi

    local java_version
    java_version=$(java -version 2>&1 | grep -oP 'version "\K[\d.]+' | head -1)
    local major_version
    major_version=$(echo "$java_version" | cut -d. -f1)

    # Gradle build requires Java 17 specifically
    if [ "$major_version" -eq 17 ]; then
        print_success "Java version: $java_version (compatible)"
        return 0
    else
        print_warning "Java version: $java_version (found), but Gradle requires Java 17 specifically"
        return 1
    fi
}

check_gradle() {
    print_step "Checking Gradle..."

    if [ -f "$SCRIPT_DIR/gradlew" ]; then
        print_success "Gradle wrapper found"
        chmod +x "$SCRIPT_DIR/gradlew" 2>/dev/null || true
        return 0
    else
        add_error "Gradle wrapper not found at $SCRIPT_DIR/gradlew"
        return 1
    fi
}

run_preflight_checks() {
    print_header "Pre-flight Checks"

    local checks_passed=0
    local checks_total=0

    # Check disk space
    checks_total=$((checks_total + 1))
    if check_disk_space; then
        checks_passed=$((checks_passed + 1))
    else
        print_warning "Disk space check failed"
    fi

    # Check curl
    checks_total=$((checks_total + 1))
    if validate_executable "curl" "curl"; then
        checks_passed=$((checks_passed + 1))
    fi

    # Check unzip
    checks_total=$((checks_total + 1))
    if validate_executable "unzip" "unzip"; then
        checks_passed=$((checks_passed + 1))
    fi

    # Check git
    checks_total=$((checks_total + 1))
    if validate_executable "git" "git"; then
        checks_passed=$((checks_passed + 1))
    fi

    # Check sudo
    checks_total=$((checks_total + 1))
    if [ "$OS" != "windows" ]; then
        if validate_executable "sudo" "sudo"; then
            checks_passed=$((checks_passed + 1))
        fi
    else
        checks_passed=$((checks_passed + 1))
    fi

    print_info "Pre-flight checks: $checks_passed/$checks_total passed"

    if [ $checks_passed -lt $((checks_total - 1)) ]; then
        print_error "Critical tools missing"
        return 1
    fi

    return 0
}

build_project() {
    print_header "Building SWORDCOMM ($BUILD_VARIANT)"

    cd "$SCRIPT_DIR" || { add_error "Failed to change to project directory"; return 1; }

    if ! validate_file "$SCRIPT_DIR/gradlew" "Gradle wrapper"; then
        return 1
    fi

    if ! validate_directory "$SCRIPT_DIR/app" "App directory"; then
        return 1
    fi

    print_info "Build variant: $BUILD_VARIANT"
    print_info "This is a full build and may take 10-30 minutes on first run"
    print_info "Logs: watch with 'tail -f $LOG_FILE'"

    local gradle_flags="-PCI=true"
    if [ "$CI_MODE" = true ]; then
        gradle_flags="$gradle_flags -x lint"
    fi

    # Run the build with detailed error handling
    if ! ./gradlew $gradle_flags ":app:assemble$BUILD_VARIANT" 2>&1 | tee -a "$LOG_FILE"; then
        add_error "Gradle build failed for variant: $BUILD_VARIANT"
        print_error "Check the logs above for detailed error information"
        return 1
    fi

    print_success "Build completed successfully!"

    # Find and verify the output APK
    local apk_found=false
    local apk_file=""

    # Try to find release APK
    for apk in "$SCRIPT_DIR/app/build/outputs/apk"/*"/release/"*.apk; do
        if [ -f "$apk" ]; then
            apk_file="$apk"
            apk_found=true
            break
        fi
    done

    # If no release APK, try debug
    if [ "$apk_found" = false ]; then
        for apk in "$SCRIPT_DIR/app/build/outputs/apk"/*"/debug/"*.apk; do
            if [ -f "$apk" ]; then
                apk_file="$apk"
                apk_found=true
                break
            fi
        done
    fi

    if [ "$apk_found" = true ]; then
        local apk_size
        apk_size=$(ls -lh "$apk_file" | awk '{print $5}')
        print_success "APK generated: $apk_file"
        print_info "APK size: $apk_size"
        echo ""
        print_info "Next steps:"
        echo "  1. Install on device: adb install \"$apk_file\""
        echo "  2. Or push to device for sideloading"
    else
        add_error "APK file not found after successful build"
        return 1
    fi
}

show_summary() {
    print_header "Setup Summary"

    echo "Environment Configuration:"
    echo "  OS: $OS ($ARCH)"
    echo "  Java: $(java -version 2>&1 | grep 'openjdk version' | cut -d'"' -f2)"
    echo "  ANDROID_HOME: ${ANDROID_HOME:-Not set}"

    if [ -n "${ANDROID_HOME:-}" ]; then
        echo ""
        echo "Android SDK Components:"
        echo "  Build Tools: $ANDROID_BUILD_TOOLS"
        echo "  Platform: android-$ANDROID_SDK_VERSION"
        echo "  NDK: $ANDROID_NDK_VERSION"
    fi

    echo ""
    echo "Project Configuration:"
    echo "  Project Directory: $SCRIPT_DIR"
    echo "  Gradle Wrapper: $([ -f $SCRIPT_DIR/gradlew ] && echo 'Present' || echo 'Not Found')"
    echo "  Build Variant: $BUILD_VARIANT"

    echo ""
    print_success "Bootstrap setup complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Source your shell profile: source ~/.bashrc (or ~/.zshrc)"
    echo "  2. Start building: ./gradlew assembleDebug"
    echo "  3. Or use: ./build.sh (if available)"
}

################################################################################
# Main Script
################################################################################

main() {
    # Initialize log file
    {
        echo "================================================================================"
        echo "SWORDCOMM Android Build Bootstrap - $(date)"
        echo "OS: $OS ($ARCH)"
        echo "================================================================================"
    } > "$LOG_FILE"

    log_message "INFO" "Starting SWORDCOMM Android Build Bootstrap"

    print_header "SWORDCOMM Android Build Bootstrap"
    print_info "Bootstrapping Android development environment..."
    print_info "Log file: $LOG_FILE"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --java-only)
                INSTALL_SDK=false
                shift
                ;;
            --sdk-only)
                INSTALL_JAVA=false
                shift
                ;;
            --build)
                AUTO_BUILD=true
                shift
                ;;
            --variant)
                BUILD_VARIANT="$2"
                shift 2
                ;;
            --skip-gradle)
                RUN_BUILD=false
                shift
                ;;
            --ci-mode)
                CI_MODE=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    log_message "INFO" "Options: INSTALL_JAVA=$INSTALL_JAVA INSTALL_SDK=$INSTALL_SDK AUTO_BUILD=$AUTO_BUILD VARIANT=$BUILD_VARIANT"

    # Run pre-flight checks
    if ! run_preflight_checks; then
        add_error "Pre-flight checks failed"
        cleanup_on_error
    fi

    print_info "Detected OS: $OS ($ARCH)"

    # Java installation
    if [ "$INSTALL_JAVA" = true ]; then
        print_header "Java Installation"

        if check_java_version; then
            print_info "Java already installed, skipping installation"
        else
            case "$OS" in
                linux)
                    log_message "INFO" "Installing Java 17 on Linux"
                    install_java_linux || cleanup_on_error
                    ;;
                macos)
                    log_message "INFO" "Installing Java 17 on macOS"
                    install_java_macos || cleanup_on_error
                    ;;
                windows)
                    log_message "INFO" "Windows detected, Java installation required via installer"
                    install_java_windows || cleanup_on_error
                    ;;
                *)
                    add_error "Unsupported OS: $OS"
                    cleanup_on_error
                    ;;
            esac
        fi

        # Verify java installation
        if ! check_java_version; then
            cleanup_on_error
        fi
    fi

    # Android SDK installation
    if [ "$INSTALL_SDK" = true ]; then
        print_header "Android SDK Installation"

        if [ ! -d "$HOME/Android/sdk" ]; then
            log_message "INFO" "Installing Android SDK"
            setup_android_sdk || cleanup_on_error
            install_sdk_packages || cleanup_on_error
        else
            print_info "Android SDK already installed at $HOME/Android/sdk"
            log_message "INFO" "SDK already present, verifying installation"
            verify_sdk_installation || cleanup_on_error
        fi

        setup_environment
        log_message "INFO" "Environment variables configured"
    fi

    # Gradle check
    if ! check_gradle; then
        cleanup_on_error
    fi

    # Build project if requested
    if [ "$AUTO_BUILD" = true ] && [ "$RUN_BUILD" = true ]; then
        log_message "INFO" "Starting Gradle build for variant: $BUILD_VARIANT"
        build_project || cleanup_on_error
    fi

    # Show summary
    show_summary

    log_message "INFO" "Bootstrap script completed successfully"
    print_success "All tasks completed!"
}

# Run main function
main "$@"
