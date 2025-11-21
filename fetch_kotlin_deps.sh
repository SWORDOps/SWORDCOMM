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
            echo "OK: ${file}"
        fi
    done
}

# Kotlin deps
ARTIFACTS="
fus-statistics-gradle-plugin
kotlin-gradle-plugin-idea
kotlin-gradle-plugin-idea-proto
kotlin-build-statistics
kotlin-util-klib-metadata
kotlin-tooling-core
kotlin-util-io
kotlin-daemon-client
kotlin-compiler-runner
kotlin-assignment-compiler-plugin-gradle
kotlin-sam-with-receiver-compiler-plugin
kotlin-allopen-compiler-plugin
kotlin-noarg-compiler-plugin
kotlin-lombok-compiler-plugin
kotlin-power-assert-compiler-plugin
kotlin-serialization-compiler-plugin
kotlin-scripting-common
kotlin-scripting-jvm
kotlin-scripting-jvm-host
kotlin-annotation-processing-gradle
kotlin-compose-compiler-plugin
kotlin-compose-compiler-plugin-embeddable
kotlin-android-extensions
kotlin-parcelize-runtime
kotlin-parcelize-compiler
"

for art in $ARTIFACTS; do
    echo "Fetching $art..."
    fetch "org.jetbrains.kotlin" "$art" "2.2.20" || true
done

echo "Done"
