#!/usr/bin/env bash
set -euo pipefail

emulator_version=$1
android_version=$2
image_revision=$3
image_variant=$4
image_arch=$5
device_profile=$6

# Install emulator and system image
for i in {1..5}; do
    echo "system-images/android-${android_version}/${image_variant}/${image_arch}@${image_revision}"
    android --sdk="${ANDROID_HOME}" --no-metrics sdk install \
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

# Set up virtual device
avdmanager create avd --name "${device_profile}" \
    --package "system-images;android-${android_version};${image_variant};${image_arch}" \
    --device "${device_profile}"
