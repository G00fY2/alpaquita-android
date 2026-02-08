#!/bin/bash
set -e

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
    mimalloc-global

# Create symlink for mimalloc shared library
MIMALLOC_REAL_PATH=$(find /usr/lib -name "libmimalloc.so.[0-9]" | head -n 1)
ln -s "$MIMALLOC_REAL_PATH" "$MIMALLOC_PATH"

# Summary
echo "---BEGIN_APK_PACKAGES---"
apk info -v 2>/dev/null | sort
echo "---END_APK_PACKAGES---"
