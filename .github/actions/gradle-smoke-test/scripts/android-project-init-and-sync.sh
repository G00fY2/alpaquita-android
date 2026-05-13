#!/usr/bin/env bash
set -euo pipefail

target_dir=$1
expected_install_dir="${ANDROID_SDK_HOME:-/opt/android/user}/.local/bin"

echo "--- Container: Environment Check ---"
echo "--- User UID: $(id -u) ---"
echo "--- Working Directory: $(pwd) ---"
echo "--- Target Project Directory: $target_dir ---"

echo "--- Container: Installing Android CLI ---"
HOME="${ANDROID_SDK_HOME:-/opt/android/user}" curl -fsSL https://dl.google.com/android/cli/latest/linux_x86_64/install.sh | bash -s -- --yes >/dev/null

export PATH="$PATH:$expected_install_dir"

if [[ -d "${ANDROID_SDK_HOME:-/opt/android/user}/.android/cli/bin" ]]; then
    export PATH="$PATH:${ANDROID_SDK_HOME:-/opt/android/user}/.android/cli/bin"
fi

if ! command -v android &>/dev/null; then
    echo "ERROR: 'android' command still not found after installation and PATH update."
    exit 1
fi

echo "--- Container: Android CLI Version ---"
android --version

echo "--- Container:  Initialize a new project ---"
android create --name="SmokeTestApp" --output="$target_dir"

cd "$target_dir"

echo "--- Container: Verifying with generated gradlew wrapper ---"
./gradlew --version --no-daemon
./gradlew tasks --no-daemon

echo "--- Container: Smoke test completed successfully ---"
