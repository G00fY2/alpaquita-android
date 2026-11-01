#!/usr/bin/env bash
set -euo pipefail

image=$1
run_as_uid=$2
run_as_gid=$3
boot_timeout_seconds=$4

container_id=""

verify_emulator_logs() {
    local container_logs=$1
    local verification_result=0

    local error_lines
    error_lines=$(grep -E '^ERROR' <<<"$container_logs" || true)
    if [[ -n "$error_lines" ]]; then
        echo "ERROR: Emulator logs contain lines starting with 'ERROR':" >&2
        echo "$error_lines" >&2
        verification_result=1
    fi

    local ram_increase_lines
    ram_increase_lines=$(grep -F 'Increasing RAM size to' <<<"$container_logs" || true)
    if [[ -n "$ram_increase_lines" ]]; then
        echo "ERROR: Emulator increased the configured RAM size. Check EMULATOR_RAM against the AVD's minimum requirements:" >&2
        echo "$ram_increase_lines" >&2
        verification_result=1
    fi

    return "$verification_result"
}

on_exit() {
    local exit_code=$?

    if [[ -n "$container_id" ]]; then
        local container_logs
        container_logs=$(docker logs "$container_id" 2>&1 || true)

        {
            echo "### Host: Emulator container logs ###"
            echo "$container_logs"

            if ! verify_emulator_logs "$container_logs" && ((exit_code == 0)); then
                exit_code=1
            fi
        } 2>&1

        docker rm -f "$container_id" >/dev/null 2>&1 || true
    fi

    exit "$exit_code"
}
trap on_exit EXIT

if [[ ! -e /dev/kvm ]]; then
    echo "ERROR: /dev/kvm is missing on this host. KVM must be enabled and passed through to the runner." >&2
    exit 1
fi
if [[ ! -w /dev/kvm ]]; then
    echo "ERROR: /dev/kvm is not writable for the current user. Check group membership (e.g. the kvm group)." >&2
    exit 1
fi

echo "### Host: Starting emulator container as $run_as_uid:$run_as_gid ###"
container_id=$(
    docker run -d \
        --device /dev/kvm \
        --user "$run_as_uid:$run_as_gid" \
        -e HOME=/opt/android/user \
        "$image"
)

if [[ -z "$container_id" ]]; then
    echo "ERROR: Failed to start emulator container from image $image." >&2
    exit 1
fi

echo "### Host: Waiting for emulator readiness ###"
deadline=$((SECONDS + boot_timeout_seconds))
until docker exec "$container_id" test -f /tmp/emulator-ready 2>/dev/null; do
    if [[ "$(docker inspect -f '{{.State.Running}}' "$container_id" 2>/dev/null || echo false)" != "true" ]]; then
        echo "ERROR: Emulator container exited prematurely." >&2
        exit 1
    fi
    if ((SECONDS >= deadline)); then
        echo "ERROR: Emulator not ready within ${boot_timeout_seconds}s." >&2
        exit 1
    fi
    sleep 2
done
echo "### Host: Emulator is ready after ${SECONDS}s ###"

echo "### Host: Counting installed packages ###"
installed_packages=$(docker exec "$container_id" adb shell pm list packages)

if [[ -z "$installed_packages" ]]; then
    echo "ERROR: Package list is empty." >&2
    exit 1
fi

package_count=$(grep -c '^package:' <<<"$installed_packages" || true)
if ((package_count == 0)); then
    echo "ERROR: Package list contains no 'package:' entries:" >&2
    echo "$installed_packages" >&2
    exit 1
fi

echo "### Host: Found $package_count packages. Emulator boot test finished successfully ###"
