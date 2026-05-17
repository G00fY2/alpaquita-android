#!/usr/bin/env bash
set -euo pipefail

manifests_dir=$1
output_file=$2

{
    echo "# Android CI Build Image Release"
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
