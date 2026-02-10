#!/bin/bash
set -e
set -o pipefail

DOCKERFILE=$1

if [[ ! -f "$DOCKERFILE" ]]; then
    echo "ERROR: Dockerfile not found at $DOCKERFILE" >&2
    exit 1
fi

JDK_LIST=$(grep -iE "^FROM.*[[:space:]]AS[[:space:]]jdk" "$DOCKERFILE" | awk '{print $NF}')

if [[ -z "$JDK_LIST" ]]; then
    echo "ERROR: No stage aliases starting with 'jdk' found in $DOCKERFILE" >&2
    exit 1
fi

JSON_OUTPUT=$(echo "$JDK_LIST" | jq -R . | jq -s -c .)

echo "$JSON_OUTPUT"
