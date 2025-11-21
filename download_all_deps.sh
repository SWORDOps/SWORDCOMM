#!/bin/bash
set -e

# Simple dependency downloader using curl
MAVEN="https://repo1.maven.org/maven2"
GOOGLE="https://dl.google.com/dl/android/maven2"
PLUGINS="https://plugins.gradle.org/m2"
LOCAL_REPO=~/.m2/repository

download() {
    local url="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    echo "Downloading: $url"
    if curl -sfL -o "$dest" "$url"; then
        echo "  -> OK: $dest"
        return 0
    else
        echo "  -> FAILED"
        return 1
    fi
}

download_maven() {
    local repo="$1" group="$2" artifact="$3" version="$4"
    local path="${group//.//}/${artifact}/${version}"
    local base="${artifact}-${version}"

    for ext in pom jar module; do
        download "${repo}/${path}/${base}.${ext}" "${LOCAL_REPO}/${path}/${base}.${ext}" || true
    done
}

download_plugin_marker() {
    local id="$1" version="$2"
    local path="${id//.//}/${id}.gradle.plugin/${version}"
    local base="${id}.gradle.plugin-${version}"

    download "${PLUGINS}/${path}/${base}.pom" "${LOCAL_REPO}/${path}/${base}.pom"
}

echo "=== Downloading Kotlin dependencies ==="
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-gradle-plugin" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-gradle-plugin-api" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-gradle-plugin-model" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-stdlib" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-stdlib-jdk8" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-stdlib-jdk7" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-reflect" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-script-runtime" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-compiler-embeddable" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-scripting-compiler-embeddable" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-build-tools-api" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-tooling-core" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-native-utils" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-util-klib" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-klib-commonizer-api" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-project-model" "2.2.20"
download_maven "$MAVEN" "org.jetbrains.kotlin" "kotlin-gradle-plugins-bom" "2.2.20"

echo "=== Downloading plugin markers ==="
download_plugin_marker "org.jetbrains.kotlin.jvm" "2.2.20"
download_plugin_marker "org.jetbrains.kotlin.android" "2.2.20"
download_plugin_marker "org.jetbrains.kotlin.plugin.compose" "2.2.20"
download_plugin_marker "org.jetbrains.kotlin.plugin.serialization" "2.2.20"

echo "=== Downloading Android Gradle Plugin ==="
download_maven "$GOOGLE" "com.android.tools.build" "gradle" "8.10.0"
download_maven "$GOOGLE" "com.android.tools.build" "gradle-api" "8.10.0"
download_maven "$GOOGLE" "com.android.tools" "common" "31.10.0"
download_maven "$GOOGLE" "com.android.tools" "sdk-common" "31.10.0"

echo "=== Done ==="
