#!/bin/bash
set -e

# Function to download dependency to gradle cache
download_to_gradle() {
    local group=$1
    local artifact=$2
    local version=$3
    local repo_url=$4
    local extension=${5:-pom}

    local path="${group//.//}/${artifact}/${version}"
    local filename="${artifact}-${version}.${extension}"
    local cache_path=~/.gradle/caches/modules-2/files-2.1/${group}/${artifact}/${version}

    mkdir -p "${cache_path}"

    echo "Downloading: $repo_url/$path/$filename"
    curl -sL -o "/tmp/$filename" "$repo_url/$path/$filename"

    # Calculate SHA1 and create proper cache structure
    local sha1=$(sha1sum "/tmp/$filename" | cut -d' ' -f1)
    mkdir -p "${cache_path}/${sha1}"
    mv "/tmp/$filename" "${cache_path}/${sha1}/"
    echo "  -> Cached at ${cache_path}/${sha1}/$filename"
}

# Plugin repos
PLUGINS="https://plugins.gradle.org/m2"
MAVEN="https://repo1.maven.org/maven2"
GOOGLE="https://dl.google.com/dl/android/maven2"

echo "Downloading Kotlin JVM plugin..."
download_to_gradle "org.jetbrains.kotlin.jvm" "org.jetbrains.kotlin.jvm.gradle.plugin" "2.2.20" "$PLUGINS" "pom"

# Download the actual kotlin-gradle-plugin jar
download_to_gradle "org.jetbrains.kotlin" "kotlin-gradle-plugin" "2.2.20" "$MAVEN" "pom"
download_to_gradle "org.jetbrains.kotlin" "kotlin-gradle-plugin" "2.2.20" "$MAVEN" "jar"
download_to_gradle "org.jetbrains.kotlin" "kotlin-gradle-plugin" "2.2.20" "$MAVEN" "module"

echo "Done downloading base dependencies"
