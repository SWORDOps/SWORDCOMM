#!/bin/bash
set -e

# Configuration
export ANDROID_HOME=/root/android-sdk
export ANDROID_SDK_ROOT=/root/android-sdk
export JAVA_HOME=/root/.gradle/jdks/jdk-17
export PATH=$JAVA_HOME/bin:$PATH
GRADLE=/root/.gradle/wrapper/dists/gradle-8.11.1-all/gradle-8.11.1/bin/gradle
LOCAL_REPO=/root/.m2/repository
MAX_ROUNDS=20

echo "=========================================="
echo "SWORDCOMM Android Build Script"
echo "=========================================="
echo "ANDROID_HOME: $ANDROID_HOME"
echo "JAVA_HOME: $JAVA_HOME"
echo "=========================================="
echo ""

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
        echo "APK location:"
        find /home/user/SWORDCOMM -name "*.apk" -type f 2>/dev/null | grep -v "unaligned" | head -5
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
        echo "Full build log saved to: /tmp/build_failed.log"
        echo "$build_output" > /tmp/build_failed.log
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
