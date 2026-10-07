#!/bin/sh
set -eu

# --- Configuration (override via environment variables) ---
AVD_NAME="${AVD_NAME:-medium_phone}"
EMULATOR_RAM="${EMULATOR_RAM:-2560}"
EMULATOR_CORES="${EMULATOR_CORES:-2}"
EMULATOR_TIMEZONE="${EMULATOR_TIMEZONE:-Etc/UTC}"

log() { echo "[entrypoint] $*"; }

if [ "$#" -gt 0 ]; then
    log "WARNING: ignoring unsupported arguments: $*. Configure the image via environment variables."
fi

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

log "Starting emulator '${AVD_NAME}' (memory: ${EMULATOR_RAM} MB, cores: ${EMULATOR_CORES})"
emulator "@${AVD_NAME}" \
    -no-window -no-audio -no-boot-anim \
    -gpu swiftshader -accel on \
    -memory "${EMULATOR_RAM}" -cores "${EMULATOR_CORES}" \
    -camera-back none -camera-front none \
    -no-snapshot -no-metrics \
    -timezone "${EMULATOR_TIMEZONE}" \
    -ports 5554,5555 -delay-adb &
emu_pid=$!

# Shut the emulator down cleanly on SIGTERM/SIGINT
trap 'log "Stopping emulator"; adb emu kill >/dev/null 2>&1 || true; wait "$emu_pid" || true; exit 0' TERM INT

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
if [ -f /tmp/emulator-failed ]; then
    exit 1
fi
