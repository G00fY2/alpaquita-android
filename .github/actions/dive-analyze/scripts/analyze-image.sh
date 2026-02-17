#!/bin/bash
set -e
set -o pipefail

image=$1

echo "Starting dive analysis for image: ${image}"
export CI=true

dive "$image"
