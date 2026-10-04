#!/bin/sh
set -eu

# --- Configuration (override via environment variables) ---
AVD_NAME="${AVD_NAME:-medium_phone}"
EMULATOR_RAM="${EMULATOR_RAM:-2560}"
EMULATOR_CORES="${EMULATOR_CORES:-2}"
EMULATOR_TIMEZONE="${EMULATOR_TIMEZONE:-Etc/UTC}"

log() { echo "[entrypoint] $*"; }

# Start the adb server before the emulator and the background task
adb start-server

# Extra emulator flags can be passed as container arguments ("$@")
log "Starting emulator '${AVD_NAME}' (RAM ${EMULATOR_RAM} MB, ${EMULATOR_CORES} cores)"
emulator "@${AVD_NAME}" \
  -no-window -no-audio -no-boot-anim \
  -gpu swiftshader -accel on \
  -memory "${EMULATOR_RAM}" -cores "${EMULATOR_CORES}" \
  -camera-back none -camera-front none \
  -no-snapshot -no-metrics \
  -timezone "${EMULATOR_TIMEZONE}" \
  -ports 5554,5555 -delay-adb \
  "$@" &
emu_pid=$!

# After boot: apply guest settings and mark the container as ready
(
  adb wait-for-device
  waited=0
  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    waited=$((waited + 1))
    if [ "$waited" -ge 300 ]; then
      log "ERROR: emulator did not finish booting within 300 seconds"
      kill "$emu_pid"
      exit 1
    fi
    sleep 1
  done
  adb shell settings put global window_animation_scale 0
  adb shell settings put global transition_animation_scale 0
  adb shell settings put global animator_duration_scale 0
  adb shell settings put system screen_off_timeout 2147483647
  : > /tmp/emulator-ready
  log "Emulator ready"
) &

# Shut the emulator down cleanly on SIGTERM/SIGINT
trap 'log "Stopping emulator"; adb emu kill >/dev/null 2>&1 || true; wait "$emu_pid" || true; exit 0' TERM INT

wait "$emu_pid"
