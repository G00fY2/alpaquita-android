#!/usr/bin/env bash
set -euo pipefail

version=$1
manifests_dir=$2
output_file=$3

{
    echo "# Android CI Build Image Release - ${version}"
    echo "This release contains the following built image variants:"
    echo ""
} >"$output_file"

if [[ -d "$manifests_dir" ]]; then
    while read -r manifest; do
        echo ""
        cat "$manifest"
        echo ""
    done < <(find "$manifests_dir" -type f -name "*.md" | sort -r) >>"$output_file"
else
    echo "Error: Directory '$manifests_dir' does not exist. No manifests found to consolidate!" >&2
    exit 1
fi
