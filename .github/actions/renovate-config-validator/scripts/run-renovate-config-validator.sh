#!/usr/bin/env bash
set -euo pipefail

npx --yes --loglevel error --package renovate@latest renovate-config-validator
