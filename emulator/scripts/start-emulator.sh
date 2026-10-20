#!/bin/sh
set -eu

# --- Configuration (override via environment variables) ---
emulator_name="${EMULATOR_NAME:?}"
emulator_ram="${EMULATOR_RAM:-2560}"
emulator_cores="${EMULATOR_CORES:-2}"
emulator_timezone="${EMULATOR_TIMEZONE:-Etc/UTC}"

emu_pid=""

log() { echo "[entrypoint] $*"; }

if [ "$#" -gt 0 ]; then
    log "WARNING: ignoring unsupported arguments: $*. Configure the image via environment variables."
fi

# Shut the emulator down cleanly on SIGTERM/SIGINT. Registered first so that
# signals during adb start-server or the emulator launch are not lost as PID 1.
shutdown() {
    log "Stopping emulator"
    if [ -n "$emu_pid" ]; then
        adb emu kill >/dev/null 2>&1 || true
        wait "$emu_pid" || true
    fi
    exit 0
}
trap shutdown TERM INT

# Disable animations in a single adb call; fail loudly and stop the emulator on error
disable_animations() {
    adb shell "
        settings put global window_animation_scale 0 &&
        settings put global transition_animation_scale 0 &&
        settings put global animator_duration_scale 0
    " >/dev/null || {
        log "ERROR: could not disable animations"
        : >/tmp/emulator-failed
        kill "$emu_pid"
        exit 1
    }
}

rm -f /tmp/emulator-ready /tmp/emulator-failed

# Start the adb server before the emulator and the background task
adb start-server

log "Starting emulator '${emulator_name}' (memory: ${emulator_ram} MB, cores: ${emulator_cores})"
emulator "@${emulator_name}" \
    -no-window -no-audio -no-boot-anim \
    -gpu swiftshader -accel on \
    -memory "${emulator_ram}" -cores "${emulator_cores}" \
    -camera-back none -camera-front none \
    -no-snapshot -no-metrics \
    -timezone "${emulator_timezone}" \
    -ports 5554,5555 -delay-adb &
emu_pid=$!

# After boot: apply guest settings and mark the container as ready
(
    waited=0
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
        waited=$((waited + 1))
        if [ "$waited" -ge 300 ]; then
            log "ERROR: emulator did not finish booting within 300 seconds"
            : >/tmp/emulator-failed
            kill "$emu_pid"
            exit 1
        fi
        sleep 1
    done
    disable_animations
    : >/tmp/emulator-ready
    log "Emulator ready"
) &

wait "$emu_pid"
# Reached only if the emulator exited with status 0, e.g. after our own kill on a failed start
if [ -f /tmp/emulator-failed ]; then
    exit 1
fi
