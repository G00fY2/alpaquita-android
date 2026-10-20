#!/bin/sh
set -eu

# Install system packages required for android sdk (alphanumerically sorted)
apk add --no-cache \
    bash \
    coreutils \
    curl \
    libgcc \
    unzip
