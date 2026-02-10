#!/bin/bash
set -e
set -o pipefail

MAX_VERSION=$1
MAX_MAJORS=$2
XML_URL="https://dl.google.com/android/repository/repository2-3.xml"

all_versions=$(curl -fsSL "$XML_URL" | grep -oP '(?<=platforms;android-)[0-9.]+(?=")' | sort -uVr)

# Only get latest MAX_MAJORS versions starting at MAX_VERSION (minor version will persist)
filtered_versions=$(echo "$all_versions" | awk -v start_ver="$MAX_VERSION" -v max_m="$MAX_MAJORS" -F. '
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
found_majors=$(echo "$filtered_versions" | cut -d. -f1 | uniq | grep -c '^' || echo 0)

if [ "$found_majors" -lt 1 ]; then
    echo "ERROR: No versions found for MAX_VERSION $MAX_VERSION" >&2
    exit 1
fi

# Convert to JSON array and print only to stdout
echo "$filtered_versions" | jq -R . | jq -s -c .
