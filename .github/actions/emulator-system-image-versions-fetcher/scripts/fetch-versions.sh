#!/usr/bin/env bash
set -euo pipefail

# Strip everything after the first hyphen (e.g. '36-r1' -> '36')
max_version=${1%%-*}
min_version=$2
xml_url="https://dl.google.com/android/repository/sys-img/google_atd/sys-img2-3.xml"

# Fetch ATD System Image versions extracting only the version numbers and sorting them in descending order.
all_versions=$(curl -fsSL "$xml_url" | grep -oP '(?<=system-images;android-)[0-9.]+(?=;google_atd;x86_64)' | sort -uVr)

# Get all versions from max_version down to min_version, including all respective minor versions.
filtered_versions=$(echo "$all_versions" | awk -v start_ver="$max_version" -v end_ver="$min_version" -F. '
    BEGIN { started = 0 }
    {
        current_major = $1
        if (started == 0 && current_major <= start_ver) {
            started = 1
        }
        if (started == 1) {
            if (current_major < end_ver) {
                exit
            }
            print $0
        }
    }
')

# Validate result
expected_major_versions_count=$((max_version - min_version + 1))
if [[ "$(echo "$filtered_versions" | cut -d. -f1 | uniq | grep -c '^')" -lt "$expected_major_versions_count" ]]; then
    echo "ERROR: Expected $expected_major_versions_count distinct major versions between $max_version and $min_version:" >&2
    echo "$filtered_versions" >&2
    exit 1
fi

echo "$filtered_versions"
