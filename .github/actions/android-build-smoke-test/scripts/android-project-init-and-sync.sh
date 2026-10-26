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

echo "--- Workaround: set compileSdk to android-37.0 (AGP platform hash bug) ---" # TODO remove step once fixed https://issuetracker.google.com/issues/578109577
sed -i -E 's/^(\s*)compileSdk\s*=\s*37\s*$/\1compileSdk {\n\1    version = release(37) { minorApiLevel = 0 }\n\1}/' app/build.gradle.kts
grep -q 'minorApiLevel = 0' app/build.gradle.kts || echo "INFO: compileSdk workaround not applied"

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
