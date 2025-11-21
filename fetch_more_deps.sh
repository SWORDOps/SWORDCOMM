#!/bin/bash
set -e

MAVEN="https://repo1.maven.org/maven2"
LOCAL_REPO=~/.m2/repository

fetch() {
    local g="$1" a="$2" v="$3"
    local path="${g//.//}/${a}/${v}"
    local dest="${LOCAL_REPO}/${path}"

    mkdir -p "$dest"
    for ext in pom jar module; do
        local file="${a}-${v}.${ext}"
        if curl -sfL -o "${dest}/${file}" "${MAVEN}/${path}/${file}"; then
            echo "OK: ${g}:${a}:${v} (${ext})"
        fi
    done
}

# More Kotlin deps
fetch "org.jetbrains.kotlin" "abi-tools-api" "2.2.20"
fetch "org.jetbrains.kotlin" "kotlin-util-klib" "2.2.20"
fetch "org.jetbrains.kotlin" "kotlin-jps-plugin" "2.2.20"

# Gson
fetch "com.google.code.gson" "gson" "2.11.0"

# Coroutines
fetch "org.jetbrains.kotlinx" "kotlinx-coroutines-core-jvm" "1.8.0"
fetch "org.jetbrains.kotlinx" "kotlinx-coroutines-core" "1.8.0"

# More commonly needed
fetch "org.jetbrains" "annotations" "24.0.0"
fetch "org.jetbrains" "annotations" "23.0.0"
fetch "org.jetbrains" "annotations" "13.0"
fetch "org.jetbrains.intellij.deps" "trove4j" "1.0.20200330"

echo "Done"
