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

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAVA_VERSION="17"
JAVA_BUILD_VERSION="17.0.13_11"
ANDROID_SDK_VERSION="35"
ANDROID_BUILD_TOOLS="35.0.0"
ANDROID_NDK_VERSION="28.0.13004108"
GRADLE_VERSION="8.9"
GRADLE_WRAPPER_VERSION="8.9.0"

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

    if [[ "$OS" == "macos" ]]; then
        available_gb=$(($(df "$SCRIPT_DIR" | awk 'NR==2 {print $4}') / 1024 / 1024))
    else
        available_gb=$(($(df "$SCRIPT_DIR" | awk 'NR==2 {print $4}') / 1024 / 1024))
    fi

    if [ "$available_gb" -lt "$required_gb" ]; then
        print_warning "Low disk space: ${available_gb}GB available (${required_gb}GB recommended)"
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

    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is required for macOS. Install from https://brew.sh"
        return 1
    fi

    brew install openjdk@17 || true

    # Link java
    sudo ln -sfn "$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home" /Library/Java/JavaVirtualMachines/openjdk-17.jdk

    print_success "Java 17 installed"
}

install_java_linux() {
    print_step "Installing Java 17..."
    local distro
    distro=$(detect_linux_distro)

    case "$distro" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y openjdk-17-jdk openjdk-17-source
            ;;
        fedora|rhel|centos)
            sudo dnf install -y java-17-openjdk java-17-openjdk-devel
            ;;
        arch)
            sudo pacman -S jdk17-openjdk
            ;;
        *)
            print_error "Unsupported Linux distribution: $distro"
            print_info "Please install OpenJDK 17 manually and run this script again"
            return 1
            ;;
    esac

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
    mkdir -p "$sdk_root"
    mkdir -p "$cmdline_tools"

    print_info "SDK root: $sdk_root"

    # Download and setup cmdline-tools
    local download_url
    case "$OS:$ARCH" in
        linux:x86_64)
            download_url="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
            ;;
        linux:aarch64)
            download_url="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
            ;;
        macos:x86_64)
            download_url="https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip"
            ;;
        macos:arm64)
            download_url="https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip"
            ;;
        *)
            print_error "Unsupported platform: $OS:$ARCH"
            return 1
            ;;
    esac

    print_info "Downloading Android SDK command-line tools..."
    local tmpfile
    tmpfile=$(mktemp)
    curl -L "$download_url" -o "$tmpfile" --progress-bar

    print_info "Extracting..."
    unzip -q "$tmpfile" -d "$cmdline_tools"
    rm "$tmpfile"

    print_success "Android SDK command-line tools installed"
}

install_sdk_packages() {
    print_step "Installing Android SDK platforms and tools..."

    local sdk_root="$HOME/Android/sdk"
    local sdkmanager="$sdk_root/cmdline-tools/latest/bin/sdkmanager"

    # Accept all licenses
    yes | "$sdkmanager" --licenses || true

    # Install required packages
    print_info "Installing platforms..."
    "$sdkmanager" "platforms;android-$ANDROID_SDK_VERSION"

    print_info "Installing build tools..."
    "$sdkmanager" "build-tools;$ANDROID_BUILD_TOOLS"

    print_info "Installing NDK..."
    "$sdkmanager" "ndk;$ANDROID_NDK_VERSION"

    print_info "Installing platform tools..."
    "$sdkmanager" "platform-tools"

    print_info "Installing system images..."
    "$sdkmanager" "system-images;android-$ANDROID_SDK_VERSION;google_apis;x86_64" || true

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

    if [ "$major_version" -ge 17 ]; then
        print_success "Java version: $java_version (compatible)"
        return 0
    else
        print_error "Java version: $java_version (require 17 or higher)"
        return 1
    fi
}

check_gradle() {
    print_step "Checking Gradle..."

    if [ -f "$SCRIPT_DIR/gradlew" ]; then
        print_success "Gradle wrapper found"
        return 0
    else
        print_error "Gradle wrapper not found at $SCRIPT_DIR/gradlew"
        return 1
    fi
}

build_project() {
    print_header "Building SWORDCOMM ($BUILD_VARIANT)"

    cd "$SCRIPT_DIR"

    print_step "Running Gradle build..."

    local gradle_flags="-PCI=true"
    if [ "$CI_MODE" = true ]; then
        gradle_flags="$gradle_flags -x lint"
    fi

    if ! ./gradlew $gradle_flags ":app:assemble$BUILD_VARIANT"; then
        print_error "Build failed"
        return 1
    fi

    print_success "Build completed successfully!"

    # Find the output APK
    local apk_path="$SCRIPT_DIR/app/build/outputs/apk/*/release/app-*-release.apk"
    local apk_path_debug="$SCRIPT_DIR/app/build/outputs/apk/*/debug/app-*-debug.apk"

    if compgen -G "$apk_path" > /dev/null 2>&1; then
        print_success "APK generated: $(ls -lh $apk_path | awk '{print $9, "(" $5 ")"}')"
    elif compgen -G "$apk_path_debug" > /dev/null 2>&1; then
        print_success "APK generated: $(ls -lh $apk_path_debug | awk '{print $9, "(" $5 ")"}')"
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
    print_header "SWORDCOMM Android Build Bootstrap"
    print_info "Bootstrapping Android development environment..."

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

    # Initial checks
    check_disk_space || print_warning "Insufficient disk space - continue with caution"

    print_info "Detected OS: $OS ($ARCH)"

    # Java installation
    if [ "$INSTALL_JAVA" = true ]; then
        print_header "Java Installation"

        if check_java_version; then
            print_info "Java already installed, skipping installation"
        else
            case "$OS" in
                linux)
                    install_java_linux || { print_error "Java installation failed"; exit 1; }
                    ;;
                macos)
                    install_java_macos || { print_error "Java installation failed"; exit 1; }
                    ;;
                windows)
                    install_java_windows || { print_error "Java installation failed"; exit 1; }
                    ;;
                *)
                    print_error "Unsupported OS: $OS"
                    exit 1
                    ;;
            esac
        fi

        # Verify java installation
        check_java_version || exit 1
    fi

    # Android SDK installation
    if [ "$INSTALL_SDK" = true ]; then
        print_header "Android SDK Installation"

        if [ ! -d "$HOME/Android/sdk" ]; then
            setup_android_sdk || { print_error "SDK setup failed"; exit 1; }
            install_sdk_packages || { print_error "SDK package installation failed"; exit 1; }
        else
            print_info "Android SDK already installed at $HOME/Android/sdk"
        fi

        setup_environment
    fi

    # Gradle check
    check_gradle || exit 1

    # Build project if requested
    if [ "$AUTO_BUILD" = true ] && [ "$RUN_BUILD" = true ]; then
        build_project || exit 1
    fi

    # Show summary
    show_summary
}

# Run main function
main "$@"
