#!/bin/bash
set -e
set -o pipefail

dockerfile=$1

# Extract stage aliases starting with 'jdk' from the Dockerfile's FROM instructions.
jdk_list=$(grep -iE "^FROM.*[[:space:]]AS[[:space:]]jdk" "$dockerfile" | awk '{print $NF}' | sed 's/^jdk//i' | sort -rV)

# Validate result
if [[ -z "$jdk_list" ]]; then
    echo "ERROR: No stage aliases starting with 'jdk' found in $dockerfile" >&2
    exit 1
fi

echo "$jdk_list"
