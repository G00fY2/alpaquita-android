# Android CI Build-Image Style Guide

# Project Purpose
This repository maintains a specialized, high-performance Docker image designed exclusively for CI agents to build Android projects.

### Core Technical Pillars:
* **Minimal Footprint:** Reduce image pull latency through aggressive layer optimization and zstandard (zstd) compression.
* **Maximum Build Speed:** Integration of `mimalloc` to accelerate memory-intensive processes (Gradle, Kotlin compiler).
* **Tooling Excellence:** Ensure the latest stable Android SDKs, build tools, and essential CLI utilities are provided in a pre-configured state.
* **Autonomous Maintenance:** Fully self-updating lifecycle via Renovate and Automerge.

### Runtime & Orchestration
* **CI/CD Platform:** The entire pipeline, from validation to deployment, is powered by **GitHub Actions**. Use Composite Actions to encapsulate modular logic and maintain clean workflow YAMLs.
* **Execution Environment:** The resulting image is designed to run on **Kubernetes** orchestrated by a **Jenkins Controller** using **Jenkins Agents**.

### Permissions & UID Agnosticism
* **Arbitrary UID Support:** The image must be executable by any arbitrary UID to support restricted Kubernetes environments (e.g., `runAsNonRoot: true` or specific `runAsUser` contexts).
* **GID 0 Strategy:** Adhere to the **OpenShift/Kubernetes GID 0 pattern**. All tool and cache directories must be owned by the root group (`chgrp -R 0`) with group permissions mirroring owner permissions (`chmod -R g=u`).
* **Agnostic Home:** Redirect all stateful data (Gradle caches, Android configs) to a neutral path (`/opt/android/user`) instead of the standard `/root` or `/home`. This ensures portability and simplifies volume mounting for persistent CI caching.

# !!! WORK IN PROGRESS (WIP) - REMOVE ONCE FINALIZED !!!
The following features are currently under development and may contain placeholders:
* **Registry Authentication:** Docker login logic for target registries is not yet fully implemented.
* **Image Pushing:** Registry push logic for multi-arch builds is pending.
* **Versioning:** A strategy for automated image tagging (e.g., Semantic Versioning or Git-SHA based) is still being defined.
* **Release Generation:** Automated GitHub Release creation after successful main branch merges is not yet active.
# !!! END OF WIP SECTION !!!

# Autonomous Maintenance (Renovate)
* **Automerge:** PRs from Renovate are automatically merged if the CI pipeline (Dry-Run) passes.
* **Validation:** Automated validation (Trivy, Dive) is mandatory to replace human intervention.
* **Release Trigger:** Merges to main trigger an automated release and registry push via GitHub Actions.

# Technical Standards
### Scripting
* **POSIX Shell (sh):** Mandatory for bootstrap scripts (e.g., initial setup) before `bash` is available. Use `#!/bin/sh` and `set -eu`.
* **Bash:** Preferred for all CI orchestration. Use `#!/usr/bin/env bash` with `set -euo pipefail`.
* **Decoupling:** Scripts must be portable. Pass output paths as parameters; do not rely on CI-specific environment variables for core logic.
* **Self-Documenting Code:** Code and variables must be self-explanatory. Use descriptive names that convey intent.
* **Comments:** Use comments sparingly. Only use them to explain the "why" behind complex logic, not the "what".
* **Language:** All code, comments, and documentation must be in English.

### Docker Architecture
* **Reproducible Builds:** Ensure consistency across environments through deterministic build steps.
* **Version & Digest Pinning:** Explicitly pin versions and SHA-256 digests for all base images to ensure immutability (e.g., `image:tag@sha256:...`). This is enforced by Renovate as configured in `.github/renovate.json5`.
* **Allocators:** `mimalloc` must be preloaded via `LD_PRELOAD` to optimize tool performance.
* **Compression:** Use `zstd` (level 9) with `force-compression=true` for registry exports.

# Formatting & Tooling
* **EditorConfig:** Source of truth for indentation and line endings (enforced via `.editorconfig`).
* **Linters & Formatters:** * `shfmt`: Mandatory for formatting shell scripts. Use settings that respect `.editorconfig`.
  * `shellcheck`: Mandatory for static analysis of `.sh` and `.bash` files.
  * `hadolint`: Mandatory for Dockerfile best practices.
  * `yamllint`: Mandatory for YAML files using `.github/.yamllint.yaml`.
* **Analysis:** Every build must be verified by `dive` for layer efficiency.

# CI/CD Strategy (GitHub Actions)
* **Dry-Run:** Build `linux/amd64` only for rapid feedback and security scanning.
* **Release:** Full multi-arch build (`amd64`, `arm64`) with registry push.
* **Concurrency:** `cancel-in-progress: true` is mandatory for all workflows to optimize runner usage.
