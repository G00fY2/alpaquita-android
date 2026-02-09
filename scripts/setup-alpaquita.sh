#!/bin/bash
set -e

filter_apk_cache_warning() {
    grep -v "WARNING: opening from cache" >&2
}

MIMALLOC_PATH=$1

# Install system packages
apk add --no-cache \
    bash \
    curl \
    unzip \
    git \
    coreutils \
    openssh-client-default \
    libstdc++ \
    mimalloc-global \
    2> >(filter_apk_cache_warning)

# Create symlink for mimalloc shared library
MIMALLOC_REAL_PATH="/$(apk info -L mimalloc 2> >(filter_apk_cache_warning) | grep -m1 'libmimalloc\.so\.[0-9]$')"
ln -s "$MIMALLOC_REAL_PATH" "$MIMALLOC_PATH"

# Validate mimalloc
if LD_PRELOAD="$MIMALLOC_PATH" MIMALLOC_VERBOSE=1 sh -c true 2>&1 | grep -q "mimalloc: process init"; then
    echo "Success: mimalloc is active and working!"
else
    echo "Error: mimalloc validation failed! The library was found but not initialized." >&2
    exit 1
fi

# Summary
echo "---BEGIN_APK_PACKAGES---"
apk info -v 2> >(filter_apk_cache_warning) | sort
echo "---END_APK_PACKAGES---"
