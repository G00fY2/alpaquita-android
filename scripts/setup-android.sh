#!/bin/bash
set -e

USER_UID=$1
CMDLINE_TOOLS_VERSION=$2
PLATFORM_TOOLS_VERSION=$3
BUILD_TOOLS_VERSION=$4
PLATFORM_VERSION=$4


# Install system packages
apk add --no-cache \
    bash \
    curl \
    unzip \
    git \
    coreutils \
    openssh-client-default \
    libstdc++ \
    mimalloc-global

# Create stable symlink for mimalloc shared library
MIMALLOC_PATH=$(find /usr/lib -name "libmimalloc.so.[0-9]" | head -n 1)
ln -s "$MIMALLOC_PATH" /usr/lib/libmimalloc_stable.so

# Install Android SDK Platform-Tools with explicit version
mkdir -p "${ANDROID_HOME}/cmdline-tools"
mkdir -p "${ANDROID_USER_HOME}"
touch "${ANDROID_USER_HOME}/repositories.cfg"
curl -fsSL "https://dl.google.com/android/repository/platform-tools_r${PLATFORM_TOOLS_VERSION}-linux.zip" -o /tmp/platform-tools.zip
unzip -q /tmp/platform-tools.zip -d "${ANDROID_HOME}"
rm /tmp/platform-tools.zip

# Install Android SDK Command-line Tools including
curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" -o /tmp/commandline-tools.zip
unzip -q /tmp/commandline-tools.zip -d "${ANDROID_HOME}/cmdline-tools"
mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
rm /tmp/commandline-tools.zip

# Add package.xml to allow sdkmanager self detection
FULL_VERSION=$(grep "Pkg.Revision" "${ANDROID_HOME}/cmdline-tools/latest/source.properties" | cut -d'=' -f2)
MAJOR=$(echo "$FULL_VERSION" | cut -d'.' -f1)
MINOR=$(echo "$FULL_VERSION" | cut -d'.' -s -f2)
[ -z "$MINOR" ] && MINOR=0
cat <<EOF > "${ANDROID_HOME}/cmdline-tools/latest/package.xml"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns2:repository xmlns:ns2="http://schemas.android.com/repository/android/common/02" xmlns:ns5="http://schemas.android.com/repository/android/generic/02">
    <localPackage path="cmdline-tools;latest" obsolete="false">
        <type-details xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns5:genericDetailsType"/>
        <revision>
            <major>$MAJOR</major>
            <minor>$MINOR</minor>
        </revision>
        <display-name>Android SDK Command-line Tools (latest)</display-name>
    </localPackage>
</ns2:repository>
EOF

# Setup and accept licenses
yes | sdkmanager --sdk_root="${ANDROID_HOME}" --licenses > /dev/null

# Install Android SDK Build-Tools
sdkmanager --sdk_root="${ANDROID_HOME}" --install "build-tools;${BUILD_TOOLS_VERSION}"

# Install Android SDK Platform
sdkmanager --sdk_root="${ANDROID_HOME}" --install "platforms;android-${PLATFORM_VERSION}"

# Summary
echo "---BEGIN_APK_PACKAGES---"
apk info -v 2>/dev/null | sort
echo "---END_APK_PACKAGES---"

echo "---BEGIN_SDK_PACKAGES---"
sdkmanager --list_installed --verbose
echo "---END_SDK_PACKAGES---"

# Cleanup
rm -rf "${ANDROID_HOME}/.temp"
rm -rf "${ANDROID_HOME}/.patches"
rm -rf "${ANDROID_HOME}/.downloadIntermediates"
rm -rf "${ANDROID_USER_HOME}/cache"
rm -rf "${ANDROID_USER_HOME}/build-cache"

# Set ownership of ANDROID_HOME including ANDROID_USER_HOME to target user
chown -R "${USER_UID}:${USER_UID}" "${ANDROID_HOME}"
