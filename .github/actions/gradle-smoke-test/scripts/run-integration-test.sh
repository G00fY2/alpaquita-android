#!/usr/bin/env bash
set -euo pipefail

image=$1
run_as_uid=$2
run_as_gid=$3
action_path=$4

dist_dir="gradle-dist"
project_dir="integration-test-project"

echo "### Host: Preparing Workspace ###"
mkdir -p "$dist_dir" "$project_dir"
chmod 777 "$dist_dir" "$project_dir"

echo "### Host: Starting Docker Integration Test ###"

docker run --rm \
    --user "$run_as_uid:$run_as_gid" \
    -v "$(pwd)":/workspace \
    -v "$action_path/scripts":/scripts:ro \
    -w /workspace \
    "$image" \
    bash /scripts/gradle-init-and-exec.sh "$dist_dir" "$project_dir"

echo "### Host: Integration Test Finished Successfully ###"
