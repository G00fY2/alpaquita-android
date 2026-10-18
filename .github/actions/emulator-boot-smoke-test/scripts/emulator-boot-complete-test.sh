#!/usr/bin/env bash
set -euo pipefail

image=$1
run_as_uid=$2
run_as_gid=$3
boot_timeout_seconds=$4

container_id=$(docker run -d --rm --device /dev/kvm --user "$run_as_uid:$run_as_gid" "$image")

trap 'docker logs "$container_id" || true; docker stop "$container_id" >/dev/null || true' EXIT

docker exec "$container_id" timeout "$boot_timeout_seconds" adb wait-for-device
docker exec "$container_id" timeout "$boot_timeout_seconds" sh -c \
    'until [ "$(adb shell getprop sys.boot_completed | tr -d "\r")" = "1" ]; do sleep 2; done'

echo "### Emulator booted successfully"
