#!/usr/bin/env bash
set -euo pipefail

cmdline_tools_id=$1
platform_tools_version=$2
build_tools_version=$3
platform_version=$4

# Prepare Android SDK directories and configuration
mkdir -p "${ANDROID_HOME}/cmdline-tools"
mkdir -p "${ANDROID_USER_HOME}"
touch "${ANDROID_USER_HOME}/repositories.cfg"

# Install Android SDK Platform-Tools with specified version
curl -fsSL "https://dl.google.com/android/repository/platform-tools_r${platform_tools_version}-linux.zip" \
    -o /tmp/platform-tools.zip \
    -w "Downloaded: %{url_effective}\n"
unzip -q /tmp/platform-tools.zip -d "${ANDROID_HOME}"
rm /tmp/platform-tools.zip

# Install Android SDK Command-line Tools with specified version
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${cmdline_tools_id}_latest.zip" \
    -o /tmp/commandline-tools.zip \
    -w "Downloaded: %{url_effective}\n"
unzip -q /tmp/commandline-tools.zip -d "${ANDROID_HOME}/cmdline-tools"
mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
rm /tmp/commandline-tools.zip

# Create package.xml based on source.properties to make cmdline-tools visible to sdkmanager
full_version=$(grep "Pkg.Revision" "${ANDROID_HOME}/cmdline-tools/latest/source.properties" | cut -d'=' -f2)
major=$(echo "$full_version" | cut -d'.' -f1)
minor=$(echo "$full_version" | cut -d'.' -s -f2)
minor=${minor:-0}
cat <<EOF >"${ANDROID_HOME}/cmdline-tools/latest/package.xml"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns2:repository xmlns:ns2="http://schemas.android.com/repository/android/common/02" xmlns:ns5="http://schemas.android.com/repository/android/generic/02">
    <localPackage path="cmdline-tools;latest" obsolete="false">
        <type-details xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns5:genericDetailsType"/>
        <revision>
            <major>$major</major>
            <minor>$minor</minor>
        </revision>
        <display-name>Android SDK Command-line Tools (latest)</display-name>
    </localPackage>
</ns2:repository>
EOF

# Accept all Android SDK licenses
(yes || true) | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses >/dev/null

# Install Android SDK Build-Tools with specified version
sdkmanager --sdk_root="${ANDROID_HOME}" --install "build-tools;${build_tools_version}"

# Install Android SDK Platform with specified version
sdkmanager --sdk_root="${ANDROID_HOME}" --install "platforms;android-${platform_version}"

# Cleanup
rm -rf \
    "${ANDROID_HOME}/.downloadIntermediates" \
    "${ANDROID_HOME}/.patches" \
    "${ANDROID_HOME}/.temp" \
    "${ANDROID_USER_HOME}/build-cache" \
    "${ANDROID_USER_HOME}/cache"
