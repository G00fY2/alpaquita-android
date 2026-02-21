#!/usr/bin/env bash
set -euo pipefail

image=$1
run_as_uid=$2
run_as_gid=$3
action_path=$4

echo "### Host: Starting Docker Integration Test ###"

docker run --rm \
  --user "$run_as_uid:$run_as_gid" \
  -v "$(pwd)":/workspace \
  -v "$action_path/scripts":/scripts:ro \
  -w /workspace \
  "$image" \
  bash /scripts/gradle-init-and-exec.sh

echo "### Host: Integration Test Finished Successfully ###"
