#!/bin/sh
set -eu

# Install system packages required for headless emulator (alphanumerically sorted)
apk add --no-cache \
    libgcc \
    libx11
