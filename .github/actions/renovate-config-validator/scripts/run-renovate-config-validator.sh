#!/usr/bin/env bash
set -euo pipefail

config_file=$1

npx --yes --loglevel error --package renovate@latest renovate-config-validator "$config_file"
