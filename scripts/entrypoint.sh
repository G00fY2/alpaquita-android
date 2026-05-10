#!/bin/bash
set -e

# detect target UID/GID from workspace or fallback to default
TARGET_UID=$(stat -c %u . 2>/dev/null || echo "${DEFAULT_USER_UID:-1000}")
TARGET_GID=$(stat -c %g . 2>/dev/null || echo "${DEFAULT_USER_UID:-1000}")

echo "[ENTRYPOINT] Resolved UID:GID to $TARGET_UID:$TARGET_GID"

# update ownership of SDK and home directories
# we ignore errors as chown might fail in restricted environments (e.g. CI runners)
# write access is often still possible if UIDs match the pre-owned files in the image
echo "[ENTRYPOINT] Ensuring ownership of $ANDROID_HOME and $USER_HOME..."
chown -R "$TARGET_UID:$TARGET_GID" "$ANDROID_HOME" 2>/dev/null || true
chown -R "$TARGET_UID:$TARGET_GID" "$USER_HOME" 2>/dev/null || true

echo "[ENTRYPOINT] Dropping privileges to $USER_NAME (UID: $TARGET_UID, GID: $TARGET_GID)..."

# switch to target user and execute command
exec chroot --userspec="$TARGET_UID:$TARGET_GID" / "$@"
