#!/usr/bin/env bash
set -euo pipefail

disable_metrics() {
    if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
        echo "Error: \$HOME ('${HOME:-}') does not exist or is not writable." >&2
        return 1
    fi

    if [ -f "${HOME}/.androidrc" ]; then
        if ! grep -q -- "--no-metrics" "${HOME}/.androidrc"; then
            # Ensure the file ends with a newline character before appending
            awk 1 "${HOME}/.androidrc" >"${HOME}/.androidrc.tmp" && mv "${HOME}/.androidrc.tmp" "${HOME}/.androidrc"
            echo "--no-metrics" >>"${HOME}/.androidrc"
            echo "Info: Added --no-metrics to existing ${HOME}/.androidrc."
        else
            echo "Info: ${HOME}/.androidrc already contains --no-metrics."
        fi
    else
        echo "--no-metrics" >"${HOME}/.androidrc"
        echo "Info: Created ${HOME}/.androidrc."
    fi
}

case "${1:-}" in
disable-metrics)
    disable_metrics
    ;;
*)
    echo "Usage: android-tools <command>"
    echo "Available commands:"
    echo "  disable-metrics - Disables Android CLI metrics collection"
    exit 1
    ;;
esac
