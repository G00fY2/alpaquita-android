#!/usr/bin/env bash
set -euo pipefail

android_cli_version=$1
cmdline_tools_version=$2
platform_tools_version=$3
build_tools_version=$4
platform_version=$5

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
android --sdk="${ANDROID_HOME}" --no-metrics sdk install \
    "cmdline-tools/latest@${cmdline_tools_version}" \
    "platform-tools@${platform_tools_version}" \
    "build-tools/${build_tools_version}" \
    "platforms/android-${platform_version}"
