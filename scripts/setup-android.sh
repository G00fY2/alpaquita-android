#!/usr/bin/env bash
set -euo pipefail

cmdline_tools_version=$1
platform_tools_version=$2
build_tools_version=$3
platform_version=$4

# Prepare Android SDK directories and configuration
mkdir -p "${ANDROID_HOME}/cmdline-tools"
mkdir -p "${ANDROID_USER_HOME}"
touch "${ANDROID_USER_HOME}/repositories.cfg"

# Install Android CLI
curl -fsSL --retry 5 --retry-all-errors "https://dl.google.com/android/cli/latest/linux_x86_64/android" \
    -o /usr/local/bin \
    -w "Downloaded: %{url_effective}\n"
chmod +x /usr/local/bin/android

# Install required packages
android --sdk="${ANDROID_HOME}" sdk install \
    "cmdline-tools/latest@${cmdline_tools_version}" \
    "platform-tools@${platform_tools_version}" \
    "build-tools@${build_tools_version}" \
    "platforms/android-${platform_version}"
