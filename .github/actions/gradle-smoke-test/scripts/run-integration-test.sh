#!/usr/bin/env bash
set -euo pipefail

image=$1
action_path=$2
run_as_uid=$3
run_as_gid=$4

workspace_name="integration-workspace"
host_workspace="$(pwd)/$workspace_name"

echo "### Host: Preparing Jenkins-style environment ###"
echo "### Host: Using UID:GID $run_as_uid:$run_as_gid ###"

mkdir -p "$host_workspace"
chmod 777 "$host_workspace"

echo "### Host: Starting Docker Integration Test ###"

# Mounts:
# - host_workspace -> /workspace (The shared volume)
# - action_path/scripts -> /scripts (The logic)
docker run --rm \
    --user "$run_as_uid:$run_as_gid" \
    -v "$host_workspace":/workspace \
    -v "$action_path/scripts":/scripts:ro \
    -w /workspace \
    "$image" \
    bash /scripts/gradle-init-and-exec.sh "/workspace"

echo "### Host: Integration Test Finished Successfully ###"
