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
        curl -sfL -o "${dest}/${a}-${v}.${ext}" "${MAVEN}/${path}/${a}-${v}.${ext}" && echo "OK: ${a}-${v}.${ext}" || true
    done
}

# Kotlin 2.0.20 deps needed by gradle-kotlin-dsl-plugins
fetch "org.jetbrains.kotlin" "kotlin-stdlib" "2.0.20"
fetch "org.jetbrains.kotlin" "kotlin-gradle-plugin" "2.0.20"
fetch "org.jetbrains.kotlin" "kotlin-gradle-plugin-api" "2.0.20"
fetch "org.jetbrains.kotlin" "kotlin-sam-with-receiver" "2.0.20"
fetch "org.jetbrains.kotlin" "kotlin-assignment" "2.0.20"
fetch "org.jetbrains.kotlin" "kotlin-gradle-plugin-model" "2.0.20"
fetch "org.jetbrains.kotlin" "kotlin-native-utils" "2.0.20"

echo "Done"
