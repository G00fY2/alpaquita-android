#!/bin/bash
set -e

# detect target UID/GID from workspace or fallback to default
TARGET_UID=$(stat -c %u . 2>/dev/null || echo "${DEFAULT_USER_UID:-1000}")
TARGET_GID=$(stat -c %g . 2>/dev/null || echo "${DEFAULT_USER_UID:-1000}")

# update ownership of SDK and home directories
chown -R "$TARGET_UID:$TARGET_GID" "$ANDROID_HOME"
chown -R "$TARGET_UID:$TARGET_GID" "$USER_HOME" 2>/dev/null || true

echo "Dropping privileges to $USER_NAME (UID: $TARGET_UID, GID: $TARGET_GID)..."

# switch to target user and execute command
exec chroot --userspec="$TARGET_UID:$TARGET_GID" / "$@"
