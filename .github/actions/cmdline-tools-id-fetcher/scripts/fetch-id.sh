#!/bin/bash
set -e
set -o pipefail

target_version=$1
xml_url="https://dl.google.com/android/repository/repository2-3.xml"

# Fetch Google's XML repository.
raw_output=$(curl -fsSL "$xml_url")

# Extract the numeric build ID for the latest Linux cmdline-tools matching the target version.
cmdline_id=$(awk -v ver="$target_version" '
    $0 ~ "remotePackage path=\"cmdline-tools;" ver "\"" { in_block=1 }
    in_block && /commandlinetools-linux-/ {
        if (match($0, /linux-([0-9]+)_latest/, arr)) {
            print arr[1]
            exit
        }
    }
    /<\/remotePackage>/ { in_block=0 }
' <<< "$raw_output")

# Validate result
if [[ -z "$cmdline_id" ]]; then
    echo "ERROR: Could not find cmdline-tools ID for version $target_version (Linux)" >&2
    exit 1
fi

# Print result to stdout
echo "$cmdline_id"
