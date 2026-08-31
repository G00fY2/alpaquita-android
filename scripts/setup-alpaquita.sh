#!/bin/sh
set -eu

mimalloc_path=$1

# Install system packages (alphanumerically sorted)
apk add --no-cache \
    bash \
    coreutils \
    curl \
    git \
    libstdc++ \
    mimalloc-global \
    openssh-client-default \
    unzip

# Create symlink to replace default busybox shell with bash
ln -sf /bin/bash /bin/sh

if ! /bin/sh -c '[[ -n "${BASH_VERSION:-}" ]]' 2>/dev/null; then
    echo "Error: /bin/sh validation failed! It is not executing bash." >&2
    exit 1
else
    echo "Success: /bin/sh is correctly mapped to bash!"
fi

# Create symlink for mimalloc shared library
mimalloc_real_path=$(apk info -L mimalloc | grep -m1 'libmimalloc\.so\.[0-9]$')

if [ -z "$mimalloc_real_path" ]; then
    echo "Error: Could not find libmimalloc shared library." >&2
    exit 1
fi

ln -s "/${mimalloc_real_path#/}" "$mimalloc_path"

# Validate mimalloc
if LD_PRELOAD="$mimalloc_path" MIMALLOC_VERBOSE=1 sh -c true 2>&1 | grep -q "mimalloc: process init"; then
    echo "Success: mimalloc is active and working!"
else
    echo "Error: mimalloc validation failed! The library was found but not initialized." >&2
    exit 1
fi
