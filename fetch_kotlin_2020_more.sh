#!/bin/bash
MAVEN="https://repo1.maven.org/maven2"
LOCAL_REPO=~/.m2/repository

fetch() {
    local g="$1" a="$2" v="$3"
    local path="${g//.//}/${a}/${v}"
    local dest="${LOCAL_REPO}/${path}"
    mkdir -p "$dest"
    for ext in pom jar module; do
        curl -sfL -o "${dest}/${a}-${v}.${ext}" "${MAVEN}/${path}/${a}-${v}.${ext}" && echo "OK: ${a}-${v}.${ext}" || true
    done
}

# All missing Kotlin 2.0.20 deps
for art in kotlin-util-klib kotlin-compiler-embeddable kotlin-gradle-plugin-annotations kotlin-tooling-core kotlin-util-io kotlin-stdlib-common kotlin-reflect kotlin-script-runtime kotlin-scripting-common kotlin-scripting-compiler-embeddable kotlin-scripting-jvm kotlin-scripting-compiler-impl-embeddable kotlin-daemon-client kotlin-daemon-embeddable kotlin-build-statistics fus-statistics-gradle-plugin kotlin-gradle-plugin-idea kotlin-gradle-plugin-idea-proto kotlin-compiler-runner kotlin-klib-commonizer-api kotlin-util-klib-metadata; do
    fetch "org.jetbrains.kotlin" "$art" "2.0.20"
done

echo "Done"
