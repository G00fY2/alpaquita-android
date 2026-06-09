#!/usr/bin/env bash
set -euo pipefail

target_dir=$1

if [[ -z "${ANDROID_SDK_HOME:-}" ]]; then
    echo "ERROR: The environment variable ANDROID_SDK_HOME is not set or empty."
    exit 1
fi

export HOME="$ANDROID_SDK_HOME"
expected_install_dir="$HOME/.local/bin"

echo "--- Container: Environment Check ---"
echo "--- User UID: $(id -u) ---"
echo "--- HOME Directory: $HOME ---"
echo "--- Working Directory: $(pwd) ---"
echo "--- Target Project Directory: $target_dir ---"

echo "--- Container: Installing Android CLI ---"
curl -fsSL https://dl.google.com/android/cli/latest/linux_x86_64/install.sh | bash -s -- --yes >/dev/null

export PATH="$PATH:$expected_install_dir"

if ! command -v android &>/dev/null; then
    echo "ERROR: 'android' command still not found after installation and PATH update."
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

echo "--- Container: Initialize the Gradle wrapper ---"
./gradlew --version --no-daemon

echo "--- Container: Actually build the Android project using gradlew wrapper ---"
./gradlew assembleDebug --no-daemon --no-build-cache --no-configuration-cache --no-watch-fs

echo "--- Container: Android CLI Installed SDK packages after build ---"
android sdk list

echo "--- Container: Smoke test completed successfully ---"
