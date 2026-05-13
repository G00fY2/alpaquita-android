#!/usr/bin/env bash
set -euo pipefail

image=$1
config=$2

echo "Starting dive analysis for image: ${image}"
echo "Using config file: ${config}"
export CI=true

dive --ci-config "$config" "$image"
