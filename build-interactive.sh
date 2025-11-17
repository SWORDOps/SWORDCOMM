#!/bin/bash

################################################################################
# SWORDCOMM Android Build - Interactive Full Build Script
#
# Complete build system with interactive option selection.
# Supports full builds with all testing, linting, and optimization.
#
# Usage:
#   chmod +x build-interactive.sh
#   ./build-interactive.sh
#
################################################################################

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_LOG="$SCRIPT_DIR/build-$(date +%Y%m%d-%H%M%S).log"
GRADLE_CMD="$SCRIPT_DIR/gradlew"

# Build options
BUILD_TYPE="debug"
BUILD_VARIANT="prodGmsWebsiteDebug"
RUN_TESTS="true"
RUN_LINT="true"
RUN_BENCHMARKS="false"
PARALLEL_BUILD="true"
BUILD_CACHE="true"
VERBOSE="false"
DAEMON_MODE="true"
CLEAN_BUILD="false"

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
    echo -e "${CYAN}ℹ $1${NC}"
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
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$BUILD_LOG"
}

pause_for_input() {
    # Only pause if in interactive mode
    if [ "${INTERACTIVE_MODE:-true}" = true ]; then
        read -p "Press Enter to continue..."
    fi
}

select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0

    while true; do
        echo -e "\n${CYAN}$prompt${NC}"
        for i in "${!options[@]}"; do
            echo "  $((i+1))) ${options[$i]}"
        done
        read -p "Select option (1-${#options[@]}): " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            selected=$((choice-1))
            echo -e "${GREEN}Selected: ${options[$selected]}${NC}"
            break
        else
            print_error "Invalid selection. Please try again."
        fi
    done

    echo "${options[$selected]}"
}

yes_no_prompt() {
    local prompt="$1"
    while true; do
        read -p "$prompt (y/n): " choice
        case "$choice" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

verify_prerequisites() {
    print_step "Verifying prerequisites..."

    local missing=0

    # Check Java
    if ! command -v java &>/dev/null; then
        print_error "Java not found. Please install Java 17."
        missing=$((missing+1))
    else
        local java_version
        java_version=$(java -version 2>&1 | grep -oP 'version "\K[\d.]+' | head -1 | cut -d. -f1)
        if [ "$java_version" -eq 17 ]; then
            print_success "Java 17 found"
        else
            print_error "Java 17 required, found version $java_version"
            missing=$((missing+1))
        fi
    fi

    # Check Gradle
    if [ ! -f "$GRADLE_CMD" ]; then
        print_error "Gradle wrapper not found at $GRADLE_CMD"
        missing=$((missing+1))
    else
        print_success "Gradle wrapper found"
    fi

    # Check Android SDK
    if [ ! -d "$HOME/Android/sdk" ]; then
        print_error "Android SDK not found at $HOME/Android/sdk"
        print_info "Run: ./bootstrap-android-build.sh"
        missing=$((missing+1))
    else
        print_success "Android SDK found"
    fi

    # Check project structure
    if [ ! -d "$SCRIPT_DIR/app" ]; then
        print_error "App directory not found"
        missing=$((missing+1))
    else
        print_success "Project structure valid"
    fi

    if [ $missing -gt 0 ]; then
        print_error "Missing $missing prerequisite(s). Cannot proceed."
        return 1
    fi

    print_success "All prerequisites met"
    return 0
}

interactive_menu() {
    print_header "SWORDCOMM Android Build - Interactive Configuration"

    # Build Type
    print_step "Select build type:"
    BUILD_TYPE=$(select_option "Build Type:" "Debug" "Release")
    BUILD_TYPE=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')

    # Build Variant
    print_step "Select build variant:"
    BUILD_VARIANT=$(select_option "Build Variant:" \
        "prodGmsWebsiteDebug" \
        "prodGmsWebsiteRelease" \
        "prodFossWebsiteDebug" \
        "prodFossWebsiteRelease" \
        "stagingGmsWebsiteDebug" \
        "stagingGmsWebsiteRelease")

    # Testing
    print_step "Run unit tests?"
    if yes_no_prompt "Include unit tests in build?"; then
        RUN_TESTS="true"
    else
        RUN_TESTS="false"
        print_warning "Unit tests will be skipped"
    fi

    # Linting
    print_step "Run linting?"
    if yes_no_prompt "Include code linting?"; then
        RUN_LINT="true"
    else
        RUN_LINT="false"
        print_warning "Linting will be skipped"
    fi

    # Benchmarks
    print_step "Run benchmarks?"
    if yes_no_prompt "Include benchmark tests?"; then
        RUN_BENCHMARKS="true"
    else
        RUN_BENCHMARKS="false"
    fi

    # Parallel builds
    print_step "Build configuration:"
    if yes_no_prompt "Enable parallel compilation?"; then
        PARALLEL_BUILD="true"
    else
        PARALLEL_BUILD="false"
    fi

    if yes_no_prompt "Enable build cache?"; then
        BUILD_CACHE="true"
    else
        BUILD_CACHE="false"
    fi

    if yes_no_prompt "Enable Gradle daemon?"; then
        DAEMON_MODE="true"
    else
        DAEMON_MODE="false"
    fi

    # Clean build
    print_step "Build type:"
    if yes_no_prompt "Perform clean build (slow, but removes all artifacts)?"; then
        CLEAN_BUILD="true"
    else
        CLEAN_BUILD="false"
    fi

    # Verbose
    print_step "Build verbosity:"
    if yes_no_prompt "Enable verbose output?"; then
        VERBOSE="true"
    else
        VERBOSE="false"
    fi

    # Summary
    print_header "Build Configuration Summary"
    echo "Build Type:           $BUILD_TYPE"
    echo "Build Variant:        $BUILD_VARIANT"
    echo "Run Tests:            $RUN_TESTS"
    echo "Run Lint:             $RUN_LINT"
    echo "Run Benchmarks:       $RUN_BENCHMARKS"
    echo "Parallel Build:       $PARALLEL_BUILD"
    echo "Build Cache:          $BUILD_CACHE"
    echo "Gradle Daemon:        $DAEMON_MODE"
    echo "Clean Build:          $CLEAN_BUILD"
    echo "Verbose Output:       $VERBOSE"
    echo "Log File:             $BUILD_LOG"
    echo ""

    if ! yes_no_prompt "Start build with these settings?"; then
        print_warning "Build cancelled"
        return 1
    fi

    return 0
}

build_project() {
    print_header "Building SWORDCOMM - $BUILD_VARIANT"

    cd "$SCRIPT_DIR" || { print_error "Failed to change directory"; return 1; }

    # Construct Gradle command
    local gradle_cmd="$GRADLE_CMD"
    local gradle_flags=()

    # Daemon mode
    if [ "$DAEMON_MODE" = "false" ]; then
        gradle_flags+=("--no-daemon")
    else
        gradle_flags+=("--daemon")
    fi

    # Parallel
    if [ "$PARALLEL_BUILD" = "true" ]; then
        gradle_flags+=("--parallel")
        gradle_flags+=("--max-workers=8")
    fi

    # Build cache
    if [ "$BUILD_CACHE" = "true" ]; then
        gradle_flags+=("--build-cache")
    fi

    # Verbose
    if [ "$VERBOSE" = "true" ]; then
        gradle_flags+=("--info")
    else
        gradle_flags+=("--quiet")
    fi

    # Clean
    if [ "$CLEAN_BUILD" = "true" ]; then
        print_info "Running clean..."
        if ! "$gradle_cmd" "${gradle_flags[@]}" clean 2>&1 | tee -a "$BUILD_LOG"; then
            print_error "Clean failed"
            return 1
        fi
    fi

    # Build
    local task=":app:assemble${BUILD_VARIANT}"

    # Add exclusions if needed
    if [ "$RUN_TESTS" = "false" ]; then
        gradle_flags+=("-x" "test")
    fi

    if [ "$RUN_LINT" = "false" ]; then
        gradle_flags+=("-x" "lint")
    fi

    if [ "$RUN_BENCHMARKS" = "false" ]; then
        gradle_flags+=("-x" "benchmark")
    fi

    print_info "Running Gradle build..."
    print_info "Command: $gradle_cmd ${gradle_flags[@]} $task"
    log_message "INFO" "Starting build: $gradle_cmd ${gradle_flags[@]} $task"

    local start_time
    start_time=$(date +%s)

    if ! "$gradle_cmd" "${gradle_flags[@]}" "$task" 2>&1 | tee -a "$BUILD_LOG"; then
        print_error "Build failed"
        log_message "ERROR" "Build failed"
        return 1
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    print_success "Build completed successfully!"
    print_info "Build duration: $((duration/60))m $((duration%60))s"
    log_message "INFO" "Build completed successfully in ${duration}s"

    return 0
}

verify_apk() {
    print_step "Verifying APK generation..."

    local apk_found=false
    local apk_file=""

    # Search for APK
    local variant_dir
    variant_dir=$(echo "$BUILD_VARIANT" | sed 's/Debug$//' | sed 's/Release$//')

    for apk in "$SCRIPT_DIR/app/build/outputs/apk"/*"/"*".apk"; do
        if [ -f "$apk" ]; then
            apk_file="$apk"
            apk_found=true
            break
        fi
    done

    if [ "$apk_found" = true ]; then
        local apk_size
        apk_size=$(ls -lh "$apk_file" | awk '{print $5}')
        print_success "APK found: $apk_file"
        print_info "APK size: $apk_size"

        echo ""
        print_info "Installation options:"
        echo "  1) Install on connected device (adb install)"
        echo "  2) Copy to desktop"
        echo "  3) Show in file manager"
        echo "  4) Skip"

        read -p "Select option: " choice
        case "$choice" in
            1)
                if command -v adb &>/dev/null; then
                    print_info "Installing on device..."
                    adb install "$apk_file"
                else
                    print_warning "ADB not found in PATH"
                fi
                ;;
            2)
                cp "$apk_file" ~/Desktop/
                print_success "Copied to ~/Desktop/"
                ;;
            3)
                print_info "APK location: $apk_file"
                ;;
            *)
                print_info "Skipped"
                ;;
        esac

        return 0
    else
        print_warning "APK not found after build"
        return 1
    fi
}

show_build_stats() {
    print_header "Build Statistics"

    echo "Build Log: $BUILD_LOG"
    echo ""

    # Extract info from log
    local compile_time
    compile_time=$(grep -oP 'elapsed time: \K[^(]+' "$BUILD_LOG" 2>/dev/null | tail -1)

    if [ -n "$compile_time" ]; then
        echo "Compilation Time: $compile_time"
    fi

    # APK size
    local apk_files
    apk_files=$(find "$SCRIPT_DIR/app/build/outputs/apk" -name "*.apk" -type f 2>/dev/null)

    if [ -n "$apk_files" ]; then
        echo ""
        echo "Generated APKs:"
        echo "$apk_files" | while read -r apk; do
            local size
            size=$(du -h "$apk" | awk '{print $1}')
            echo "  - $(basename "$apk") ($size)"
        done
    fi

    echo ""
    print_success "Build completed successfully!"
}

show_help() {
    cat << EOF
${BLUE}SWORDCOMM Android Build - Interactive Full Build Script${NC}

${CYAN}Usage:${NC}
  ./build-interactive.sh [OPTIONS]

${CYAN}Options:${NC}
  --help              Show this help message
  --no-interactive    Use default build settings
  --variant VARIANT   Specify build variant directly
  --skip-tests        Skip unit tests
  --skip-lint         Skip linting
  --clean             Force clean build
  --verbose           Enable verbose output

${CYAN}Build Variants:${NC}
  - prodGmsWebsiteDebug       (Production, GMS, Website, Debug)
  - prodGmsWebsiteRelease     (Production, GMS, Website, Release)
  - prodFossWebsiteDebug      (Production, FOSS, Website, Debug)
  - prodFossWebsiteRelease    (Production, FOSS, Website, Release)
  - stagingGmsWebsiteDebug    (Staging, GMS, Website, Debug)
  - stagingGmsWebsiteRelease  (Staging, GMS, Website, Release)

${CYAN}Examples:${NC}
  ./build-interactive.sh                          # Interactive menu
  ./build-interactive.sh --variant prodGmsWebsiteRelease --clean
  ./build-interactive.sh --no-interactive --skip-tests

${CYAN}Output:${NC}
  Build logs are saved to: build-YYYYMMDD-HHMMSS.log

EOF
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse command line arguments
    local interactive=true
    INTERACTIVE_MODE=true  # Global flag for pause_for_input

    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --no-interactive)
                interactive=false
                INTERACTIVE_MODE=false
                shift
                ;;
            --variant)
                BUILD_VARIANT="$2"
                shift 2
                ;;
            --skip-tests)
                RUN_TESTS="false"
                shift
                ;;
            --skip-lint)
                RUN_LINT="false"
                shift
                ;;
            --clean)
                CLEAN_BUILD="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    print_header "SWORDCOMM Android Build System"
    print_info "Build log: $BUILD_LOG"

    # Verify prerequisites
    if ! verify_prerequisites; then
        print_error "Prerequisites check failed"
        exit 1
    fi

    pause_for_input

    # Interactive menu
    if [ "$interactive" = true ]; then
        if ! interactive_menu; then
            exit 1
        fi
    else
        print_info "Using default/provided settings..."
        echo "Build Variant: $BUILD_VARIANT"
    fi

    # Run build
    if ! build_project; then
        print_error "Build failed. See $BUILD_LOG for details."
        exit 1
    fi

    # Verify APK
    verify_apk

    # Show statistics
    show_build_stats

    print_success "Build process completed!"
    print_info "Log saved to: $BUILD_LOG"
}

# Run main
main "$@"
