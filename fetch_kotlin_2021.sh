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

# All Kotlin 2.0.21 deps needed
for art in kotlin-stdlib kotlin-stdlib-common kotlin-gradle-plugin kotlin-gradle-plugin-api kotlin-gradle-plugin-model kotlin-sam-with-receiver kotlin-assignment kotlin-native-utils kotlin-util-klib kotlin-compiler-embeddable kotlin-gradle-plugin-annotations kotlin-tooling-core kotlin-util-io kotlin-daemon-client kotlin-build-statistics kotlin-build-tools-api kotlin-reflect kotlin-script-runtime kotlin-scripting-common kotlin-scripting-compiler-embeddable kotlin-scripting-jvm kotlin-daemon-embeddable kotlin-gradle-plugin-idea kotlin-gradle-plugin-idea-proto kotlin-compiler-runner kotlin-klib-commonizer-api kotlin-util-klib-metadata kotlin-scripting-compiler-impl-embeddable kotlin-gradle-plugins-bom fus-statistics-gradle-plugin; do
    fetch "org.jetbrains.kotlin" "$art" "2.0.21"
done

# Classifier variants for gradle813 and gradle85
for art in kotlin-gradle-plugin kotlin-gradle-plugin-api kotlin-gradle-plugin-model kotlin-sam-with-receiver kotlin-assignment fus-statistics-gradle-plugin; do
    dest="${LOCAL_REPO}/org/jetbrains/kotlin/${art}/2.0.21"
    mkdir -p "$dest"
    for classifier in gradle813 gradle811 gradle85; do
        curl -sfL -o "${dest}/${art}-2.0.21-${classifier}.jar" "${MAVEN}/org/jetbrains/kotlin/${art}/2.0.21/${art}-2.0.21-${classifier}.jar" && echo "OK: ${art}-${classifier}.jar" || true
    done
done

echo "Done"
