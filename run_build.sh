#!/bin/bash
set -e

# Extract proxy credentials
FULL="${HTTP_PROXY#http://}"
export PROXY_AUTH_USER="${FULL%%:*}"
REST="${FULL#*:}"
export PROXY_AUTH_PASS="${REST%@*}"

echo "Proxy user: $PROXY_AUTH_USER"
echo "Proxy pass length: ${#PROXY_AUTH_PASS}"

# Set Android SDK
export ANDROID_HOME=~/android-sdk
export ANDROID_SDK_ROOT=~/android-sdk

# Use system proxy for ALL Java processes
export _JAVA_OPTIONS="-Djava.net.useSystemProxies=true"

# Run Gradle
./gradlew assembleProdGmsWebsiteDebug --no-daemon "$@"
