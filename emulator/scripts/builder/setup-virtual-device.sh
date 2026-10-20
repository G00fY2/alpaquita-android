#!/usr/bin/env bash
set -euo pipefail

device_profile=$1
android_version=$2
image_variant=$3
image_arch=$4

# Set up virtual device
avdmanager create avd --name "${device_profile}" \
    --package "system-images;android-${android_version};${image_variant};${image_arch}" \
    --device "${device_profile}"
