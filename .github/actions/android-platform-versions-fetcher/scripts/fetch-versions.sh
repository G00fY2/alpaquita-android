#!/bin/bash
set -e
set -o pipefail

max_version=$1
max_major_versions_count=$2
xml_url="https://dl.google.com/android/repository/repository2-3.xml"

# Fetch Android platform versions extracting only the version numbers and sorting them in descending order.
all_versions=$(curl -fsSL "$xml_url" | grep -oP '(?<=platforms;android-)[0-9.]+(?=")' | sort -uVr)

# Get latest max_major_versions_count API levels starting at max_version, including all respective minor versions.
filtered_versions=$(echo "$all_versions" | awk -v start_ver="$max_version" -v max_m="$max_major_versions_count" -F. '
    BEGIN { major_count = 0; last_major = ""; started = 0 }
    {
        current_major = $1
        if (started == 0 && current_major <= start_ver) {
            started = 1
        }
        if (started == 1) {
            if (current_major != last_major) {
                major_count++
                last_major = current_major
            }
            if (major_count <= max_m) {
                print $0
            } else {
                exit
            }
        }
    }
')

# Validate result
if [ "$(echo "$filtered_versions" | cut -d. -f1 | uniq | grep -c '^')" -lt "$max_major_versions_count" ]; then
    echo "ERROR: Not enough distinct major versions ($max_major_versions_count) found for $max_version:" >&2
    echo "$filtered_versions" >&2
    exit 1
fi

# Convert to JSON array and print to stdout
echo "$filtered_versions" | jq -R . | jq -s -c .
