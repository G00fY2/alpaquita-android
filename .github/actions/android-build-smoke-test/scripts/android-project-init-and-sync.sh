#!/usr/bin/env bash
set -euo pipefail

target_dir=$1

if [[ -z "${ANDROID_SDK_HOME:-}" ]]; then
    echo "ERROR: The environment variable ANDROID_SDK_HOME is not set or empty."
    exit 1
fi

export HOME="$ANDROID_SDK_HOME"

echo "--- Container: Environment Check ---"
echo "--- User UID: $(id -u) ---"
echo "--- HOME Directory: $HOME ---"
echo "--- Working Directory: $(pwd) ---"
echo "--- Target Project Directory: $target_dir ---"

echo "--- Container: Disabling Android Metrics via android-tools ---"
if command -v android-tools &>/dev/null; then
    android-tools disable-metrics
else
    echo "ERROR: 'android-tools' command not found in PATH." >&2
    exit 1
fi

if ! command -v android &>/dev/null; then
    echo "ERROR: 'android' command not found." >&2
    exit 1
fi

echo "--- Container: Android CLI Version ---"
android --version

echo "--- Container: Android CLI Info ---"
android info

echo "--- Container: Android CLI Installed SDK packages ---"
android sdk list

echo "--- Container: Initialize a new default Android Gradle project ---"
android create --name="SmokeTestApp" --output="$target_dir"

cd "$target_dir"

echo "--- Container: Initialize the Gradle wrapper & verify mimalloc execution ---"
GRADLE_VERSION_OUTPUT=$(MIMALLOC_VERBOSE=1 ./gradlew --version --no-daemon 2>&1)
echo "$GRADLE_VERSION_OUTPUT"
if grep -q "mimalloc: process init" <<< "$GRADLE_VERSION_OUTPUT"; then
    echo "SUCCESS: Gradle JVM successfully loaded and initialized mimalloc!"
else
    echo "ERROR: Gradle JVM started, but mimalloc initialization was NOT detected!" >&2
    exit 1
fi

echo "--- Container: Actually build the Android project using gradlew wrapper ---"
./gradlew assembleDebug --no-daemon

echo "--- Container: Android CLI Installed SDK packages after build ---"
android sdk list

echo "--- Container: Smoke test completed successfully ---"
