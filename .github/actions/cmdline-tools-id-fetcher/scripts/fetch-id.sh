#!/bin/bash
set -e
set -o pipefail

TARGET_VERSION=$1
XML_URL="https://dl.google.com/android/repository/repository2-3.xml"

raw_output=$(curl -fsSL "$XML_URL")

cmdline_id=$(echo "$raw_output" | awk -v ver="$TARGET_VERSION" '
    $0 ~ "remotePackage path=\"cmdline-tools;" ver "\"" { in_block=1 }
    in_block && /commandlinetools-linux-/ {
        match($0, /linux-([0-9]+)_latest/, arr)
        print arr[1]
        exit
    }
    /<\/remotePackage>/ { in_block=0 }
')

# Validate result
if [[ -z "$cmdline_id" ]]; then
    echo "ERROR: Could not find cmdline-tools ID for version $TARGET_VERSION (Linux)" >&2
    exit 1
fi

# Print only result to stdout
echo "$cmdline_id"
