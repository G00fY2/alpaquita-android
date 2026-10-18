#!/usr/bin/env bash
set -euo pipefail

android_cli_version=$1
cmdline_tools_version=$2
platform_tools_version=$3
emulator_version=$4
android_version=$5
image_revision=$6
image_variant=$7
image_arch=$8

# Prepare Android SDK directories and configuration
mkdir -p "${ANDROID_HOME}/cmdline-tools"
mkdir -p "${ANDROID_USER_HOME}"
touch "${ANDROID_USER_HOME}/repositories.cfg"

# Install Android CLI
curl -fsSL --retry 5 --retry-all-errors "https://dl.google.com/android/cli/${android_cli_version}/linux_x86_64/android" \
    -o /usr/local/bin/android \
    -w "Downloaded: %{url_effective}\n"
chmod +x /usr/local/bin/android

# Install required packages
for i in {1..5}; do
    android --sdk="${ANDROID_HOME}" --no-metrics sdk install \
        "cmdline-tools/latest@${cmdline_tools_version}" \
        "platform-tools@${platform_tools_version}" \
        "emulator@${emulator_version}" \
        "system-images/android-${android_version}/${image_variant}/${image_arch}@${image_revision}" && break

    if [ "$i" -eq 5 ]; then
        echo "ERROR: SDK download failed after 5 attempts." >&2
        exit 1
    fi

    wait_time=$((i * 5))
    echo "WARNING: Download failed. Attempt $i of 5... Retrying in ${wait_time}s." >&2
    sleep "$wait_time"
done
