#!/usr/bin/env bash
set -euo pipefail

target_dir=$1

print_installed_sdk_packages() {
    local exit_code=$?
    echo "--- Container: Android CLI Installed SDK packages after build (exit code: $exit_code) ---"
    android sdk list || echo "WARNING: 'android sdk list' failed." >&2
    exit "$exit_code"
}

if [[ -z "${ANDROID_USER_HOME:-}" ]]; then
    echo "ERROR: The environment variable ANDROID_USER_HOME is not set or empty."
    exit 1
fi

HOME="$(dirname "$ANDROID_USER_HOME")"
export HOME

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

echo "--- Install SDK Platform 37.0 ---" # TODO remove step once fixed https://issuetracker.google.com/issues/578109577
for i in {1..5}; do
    android sdk install platforms/android-37.0 && break

    if [ "$i" -eq 5 ]; then
        echo "ERROR: SDK download failed after 5 attempts." >&2
        exit 1
    fi

    wait_time=$((i * 5))
    echo "WARNING: Download failed. Attempt $i of 5... Retrying in ${wait_time}s." >&2
    sleep "$wait_time"
done


echo "--- Container: Android CLI Installed SDK packages ---"
android sdk list

trap print_installed_sdk_packages EXIT

echo "--- Container: Initialize a new default Android Gradle project ---"
android create --name="SmokeTestApp" --output="$target_dir"

cd "$target_dir"

echo "--- Container: Initialize the Gradle wrapper ---"
./gradlew --version --no-daemon

echo "--- Container: Verify mimalloc execution ---"
mimalloc_verbose_output=$(MIMALLOC_VERBOSE=1 ./gradlew --version --no-daemon 2>&1)
if grep -q "mimalloc: process init" <<<"$mimalloc_verbose_output"; then
    echo "SUCCESS: mimalloc was loaded and initialized!"
else
    echo "ERROR: mimalloc initialization was NOT detected!" >&2
    echo "$mimalloc_verbose_output" >&2
    exit 1
fi

echo "--- Container: Actually build the Android project using gradlew wrapper ---"
./gradlew assembleDebug --no-daemon

echo "--- Container: Smoke test completed successfully ---"
