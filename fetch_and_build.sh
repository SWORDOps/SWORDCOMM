#!/bin/bash
set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration - auto-detect or use environment variables
if [ -z "$ANDROID_HOME" ]; then
    # Try to detect from local.properties
    if [ -f "local.properties" ]; then
        ANDROID_HOME=$(grep "sdk.dir=" local.properties | cut -d'=' -f2)
    elif [ -d "$HOME/Android/Sdk" ]; then
        ANDROID_HOME="$HOME/Android/Sdk"
    elif [ -d "$HOME/android-sdk" ]; then
        ANDROID_HOME="$HOME/android-sdk"
    else
        echo "ERROR: ANDROID_HOME not set and could not auto-detect Android SDK"
        echo "Please either:"
        echo "  1. Set ANDROID_HOME environment variable, or"
        echo "  2. Create local.properties with: sdk.dir=/path/to/android-sdk"
        exit 1
    fi
fi

export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# Detect or use JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
    # Try to find Java 17
    if command -v java >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" = "17" ] || [ "$JAVA_VERSION" = "21" ]; then
            JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        fi
    fi

    if [ -z "$JAVA_HOME" ]; then
        echo "ERROR: JAVA_HOME not set and Java 17/21 not found in PATH"
        echo "Please install Java 17 or set JAVA_HOME"
        exit 1
    fi
fi

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

# Use project's Gradle wrapper
GRADLE="./gradlew"
if [ ! -f "$GRADLE" ]; then
    echo "ERROR: gradlew not found in $SCRIPT_DIR"
    exit 1
fi
chmod +x "$GRADLE"

# Use user's Maven local repo
LOCAL_REPO="${HOME}/.m2/repository"
MAX_ROUNDS=20

echo "=========================================="
echo "SWORDCOMM Android Build Script"
echo "=========================================="
echo "ANDROID_HOME: $ANDROID_HOME"
echo "JAVA_HOME: $JAVA_HOME"
echo "LOCAL_REPO: $LOCAL_REPO"
echo "PWD: $(pwd)"
echo "=========================================="
echo ""

# Check prerequisites
if [ ! -d "$ANDROID_HOME" ]; then
    echo "ERROR: Android SDK not found at: $ANDROID_HOME"
    exit 1
fi

if [ ! -x "$JAVA_HOME/bin/java" ]; then
    echo "ERROR: Java not found at: $JAVA_HOME/bin/java"
    exit 1
fi

# Create local.properties if it doesn't exist
if [ ! -f "local.properties" ]; then
    echo "Creating local.properties..."
    echo "sdk.dir=$ANDROID_HOME" > local.properties
fi

# Function to fetch a dependency
fetch_dependency() {
    local coords="$1"
    IFS=: read -r group artifact version <<< "$coords"

    [ -z "$group" ] && return

    local path="${group//.//}/${artifact}/${version}"
    local dest="${LOCAL_REPO}/${path}"

    mkdir -p "$dest" 2>/dev/null

    # Try Maven Central first, then Google Maven
    for repo in "https://repo1.maven.org/maven2" "https://dl.google.com/dl/android/maven2"; do
        # Download POM
        if [ ! -f "${dest}/${artifact}-${version}.pom" ]; then
            curl -sfL -o "${dest}/${artifact}-${version}.pom" "${repo}/${path}/${artifact}-${version}.pom" 2>/dev/null && break
        fi
    done

    # Download JAR/AAR
    for repo in "https://repo1.maven.org/maven2" "https://dl.google.com/dl/android/maven2"; do
        if [ ! -f "${dest}/${artifact}-${version}.jar" ] && [ ! -f "${dest}/${artifact}-${version}.aar" ]; then
            curl -sfL -o "${dest}/${artifact}-${version}.jar" "${repo}/${path}/${artifact}-${version}.jar" 2>/dev/null && break
            curl -sfL -o "${dest}/${artifact}-${version}.aar" "${repo}/${path}/${artifact}-${version}.aar" 2>/dev/null && break
        fi
    done

    # Download .module file if it exists
    for repo in "https://repo1.maven.org/maven2" "https://dl.google.com/dl/android/maven2"; do
        if [ ! -f "${dest}/${artifact}-${version}.module" ]; then
            curl -sfL -o "${dest}/${artifact}-${version}.module" "${repo}/${path}/${artifact}-${version}.module" 2>/dev/null && break || true
        fi
    done
}

echo "Starting iterative dependency resolution..."
echo ""

for round in $(seq 1 $MAX_ROUNDS); do
    echo "=========================================="
    echo "Round $round: Running Gradle build..."
    echo "=========================================="

    # Run build and capture output
    build_output=$($GRADLE assembleProdGmsWebsiteDebug --offline -Dorg.gradle.dependency.verification=off 2>&1 || true)

    # Check if build succeeded
    if echo "$build_output" | grep -q "BUILD SUCCESSFUL"; then
        echo ""
        echo "=========================================="
        echo "✅ BUILD SUCCESSFUL!"
        echo "=========================================="
        echo ""
        echo "APK location(s):"
        find "$SCRIPT_DIR" -path "*/build/outputs/apk/*" -name "*.apk" -type f 2>/dev/null | grep -v "unaligned" | head -5
        echo ""
        exit 0
    fi

    # Extract missing dependencies
    missing=$(echo "$build_output" | grep -oP "No cached version of [^ ]+" | sed 's/No cached version of //' | sort -u)

    if [ -z "$missing" ]; then
        echo ""
        echo "No more missing dependencies detected, but build failed."
        echo "Last 50 lines of build output:"
        echo "$build_output" | tail -50
        echo ""

        # Save full log
        log_file="/tmp/build_failed_$(date +%s).log"
        echo "$build_output" > "$log_file" 2>/dev/null || log_file="./build_failed.log" && echo "$build_output" > "$log_file"
        echo "Full build log saved to: $log_file"
        exit 1
    fi

    count=$(echo "$missing" | wc -l)
    echo "Found $count missing dependencies"
    echo ""

    # Show first 10 missing deps
    echo "Sample of missing dependencies:"
    echo "$missing" | head -10
    echo ""

    echo "Downloading dependencies..."

    # Download each missing dependency
    downloaded=0
    echo "$missing" | while read -r dep; do
        fetch_dependency "$dep"
        downloaded=$((downloaded + 1))
        if [ $((downloaded % 10)) -eq 0 ]; then
            echo "  Downloaded $downloaded/$count dependencies..."
        fi
    done

    echo "✓ Completed downloading round $round dependencies"
    echo ""
done

echo ""
echo "=========================================="
echo "⚠️  Maximum rounds ($MAX_ROUNDS) reached"
echo "=========================================="
echo "The build still has unresolved dependencies."
echo "This may require manual intervention."
echo ""

exit 1
