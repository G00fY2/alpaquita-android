#!/bin/sh
set -e

MIMALLOC_PATH="$1"

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

# Create symlink for mimalloc shared library
MIMALLOC_REAL_PATH=$(apk info -L mimalloc | grep -m1 'libmimalloc\.so\.[0-9]$')
ln -s "/${MIMALLOC_REAL_PATH#/}" "$MIMALLOC_PATH"

# Validate mimalloc
if LD_PRELOAD="$MIMALLOC_PATH" MIMALLOC_VERBOSE=1 sh -c true 2>&1 | grep -q "mimalloc: process init"; then
    echo "Success: mimalloc is active and working!"
else
    echo "Error: mimalloc validation failed! The library was found but not initialized." >&2
    exit 1
fi

# Summary
echo "---BEGIN_APK_PACKAGES---"
apk info -v | sort
echo "---END_APK_PACKAGES---"
