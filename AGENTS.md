# Android CI Images Style Guide

# Project Purpose
This repository maintains two specialized Docker images for Android CI on Kubernetes (Jenkins agents):
* **Build image (`android/`):** Builds Android projects with Gradle and the Kotlin compiler.
* **Emulator image (`emulator/`):** Runs a headless Android emulator as a sidecar container next to the build container.

## Core Technical Pillars
* **Minimal Footprint:** Reduce image pull latency through aggressive layer optimization and zstandard (zstd) compression.
* **Maximum Build Speed:** Integration of `mimalloc` (build image) to accelerate memory-intensive processes (Gradle, Kotlin compiler).
* **Tooling Excellence:** Ensure the latest stable Android SDKs, build tools, and essential CLI utilities are provided in a pre-configured state.
* **Reliable Emulation:** The emulator image boots deterministically, fails loudly, and exposes a clear readiness signal.
* **Autonomous Maintenance:** Fully self-updating lifecycle via Renovate and Automerge.

## Runtime & Orchestration
* **CI/CD Platform:** The entire pipeline, from validation to deployment, is powered by **GitHub Actions**. Use Composite Actions to encapsulate modular logic and maintain clean workflow YAMLs.
* **Execution Environment:** The resulting images are designed to run on **Kubernetes** orchestrated by a **Jenkins Controller** using **Jenkins Agents**. The emulator image runs as a sidecar in the agent pod.

## Repository Layout
* `android/` and `emulator/` are independent build contexts. Each has its own `Dockerfile`, `.dockerignore` (deny all, allow `scripts/`) and `scripts/` directory.
* Version pins live in `versions.env` files and are managed by Renovate.

## Permissions & UID Agnosticism
* **Arbitrary UID Support:** The images must be executable by any arbitrary UID to support restricted Kubernetes environments (e.g., `runAsNonRoot: true` or specific `runAsUser` contexts).
* **GID 0 Strategy:** Adhere to the **OpenShift/Kubernetes GID 0 pattern**. All defined Android and Gradle directories must be owned by the root group (`chgrp -R 0`) with group permissions mirroring owner permissions (`chmod -R g=u`). This ensures arbitrary-UID CI containers have full read/write access to the following paths:
  * **Tooling (`ANDROID_HOME`):** Contains the Android SDK, build tools, and platform tools.
  * **User State (`ANDROID_USER_HOME_BASE`):** Parent directory for stateful data, including:
    * `ANDROID_USER_HOME`: Stores Android-specific configurations and keys.
    * `GRADLE_USER_HOME`: Stores build caches, dependencies, and daemon logs.
* **Agnostic Home:** Redirect all stateful data (Gradle caches, Android configs) to a neutral path (`/opt/android/user`) instead of the standard `/root` or `/home`. This ensures portability and simplifies volume mounting for persistent CI caching.

# Autonomous Maintenance (Renovate)
* **Automerge:** PRs from Renovate are automatically merged if the CI pipeline (Dry-Run) passes.
* **Validation:** Automated validation (Trivy, Dive) is mandatory to replace human intervention.
* **Release Trigger:** Merges to main trigger an automated release and registry push via GitHub Actions.

# Technical Standards
## Scripting
* **POSIX Shell (sh):** Mandatory for bootstrap scripts (e.g., initial setup) before `bash` is available and for every script that runs inside the emulator image (BusyBox only). Use `#!/bin/sh` and `set -eu`.
* **Bash:** Preferred for all CI orchestration and for build-time scripts in stages that ship `bash`. Use `#!/usr/bin/env bash` with `set -euo pipefail`.
* **Decoupling:** Scripts must be portable. Pass output paths as parameters; do not rely on CI-specific environment variables for core logic.
* **Self-Documenting Code:** Code and variables must be self-explanatory. Use descriptive names that convey intent.
* **Comments:** Use comments sparingly. Only use them to explain the "why" behind complex logic, not the "what".
* **Language:** All code, comments, and documentation must be in English.

## Docker Architecture
* **Reproducible Builds:** Ensure consistency across environments through deterministic build steps.
* **Dockerfile Header:** Start every Dockerfile with the syntax directive pinned by digest and `# check=experimental=all;error=true`.
* **Version & Digest Pinning:** Explicitly pin versions and SHA-256 digests for all base images to ensure immutability (e.g., `image:tag@sha256:...`). This is enforced by Renovate as configured in `.github/renovate.json5`.
* **Layer Optimization:**
  * **Alphanumeric Sorting:** Sort multi-line arguments (e.g., packages in `apt-get install`, labels, or environment variables) alphanumerically to avoid duplicates and improve PR readability.
  * **Atomic RUN Commands:** Always combine `update` and `install` instructions (e.g., `apt-get update && apt-get install -y --no-install-recommends ...`) to prevent caching issues.
  * **Minimalism:** Use `--no-install-recommends` for all package managers and clean up caches (e.g., `rm -rf /var/lib/apt/lists/*`) within the same `RUN` layer.
  * **Stage Hygiene:** Copy only runtime artifacts into the final stage with `COPY --from`. Delete files in the stage that produces them; a later `rm` or `chmod` does not shrink or avoid earlier layers.
* **Robust Execution:**
  * **Pipefail:** Prepend `set -o pipefail` to all `RUN` instructions involving pipes (`|`) to ensure build failures if any command in the chain fails.
  * **Exec Form:** Use the **JSON Array/Exec Form** (`["executable", "param"]`) for `ENTRYPOINT` and `CMD` to ensure proper signal handling (PID 1).
* **Environment & Pathing:**
  * **Workdir:** Always use absolute paths for `WORKDIR`. Avoid using `RUN cd ...`.
  * **Allocators:** `mimalloc` must be preloaded via `LD_PRELOAD` to optimize tool performance in the build image. The emulator image never sets `LD_PRELOAD`.
* **Compression:** Use `zstd` (level 9) with `force-compression=true` for registry exports (both images).

# Emulator Image
## Principles
* **Headless Only:** Run with `-no-window`, software rendering (`-gpu swiftshader`), no audio and no snapshots. x86_64 only. Hardware acceleration (KVM) is mandatory: the emulator must refuse to start without it instead of falling back to slow emulation (`-accel on`).
* **Minimal Runtime:** Alpaquita glibc base plus only the libraries the headless emulator and adb need. No JDK, bash, curl or git in the final image. Every added package needs a justification.
* **System Image:** `google_atd` (Automated Test Device), x86_64, without Play Store. The API level is pinned deliberately and never bumped automatically.
* **Pruning:** Remove files the headless setup never loads (e.g., Qt, non-x86_64 QEMU binaries) in the SDK stage that produces them, never in the final stage. Every change to the prune list requires a passing boot smoke test.
* **Clean Starts:** The AVD is created at build time. Every container start is a clean cold boot without snapshots.

## Configuration Contract
* Configure only via environment variables; the README is the single place that lists them.
* Fixed emulator flags live in the entrypoint. Container arguments are not forwarded; they are ignored with a warning.
* Add a new variable only for a concrete need and document it in the README. Do not add pass-through flags.

## Entrypoint Behavior
* Run the emulator as the main process and handle SIGTERM/SIGINT with a clean shutdown (`adb emu kill`).
* Start the adb server before the emulator so that early adb calls do not race.
* Fail loudly: a boot timeout or a failing guest setting stops the emulator and exits non-zero, even if the emulator itself exits with status 0.
* Remove stale state at startup. Signal readiness only through `/tmp/emulator-ready`, which is created after boot and guest setup have completed.

## Runtime Requirements
* `/dev/kvm` must be available in the container (device plugin or equivalent on Kubernetes) together with the device's supplementary group. The process runs as an arbitrary UID with GID 0.
* Plan memory with headroom above the guest RAM (the emulator raises values below its minimum).
* Intended deployment: sidecar in the agent pod; the build container talks to the emulator through adb.

# Formatting & Tooling
* **EditorConfig:** Source of truth for indentation and line endings (enforced via `.editorconfig`).
* **Linters & Formatters:**
  * `shfmt`: Mandatory for formatting shell scripts. Use settings that respect `.editorconfig`.
  * `shellcheck`: Mandatory for static analysis of `.sh` and `.bash` files.
  * `hadolint`: Mandatory for Dockerfile best practices.
  * `yamllint`: Mandatory for YAML files using `.github/.yamllint.yaml`.
* **Analysis:** Every build must be verified by `dive` for layer efficiency.

# CI/CD Strategy (GitHub Actions)
* **Dry-Run:** Build `linux/amd64` only for rapid feedback and security scanning on feature branches and pull requests.
* **Boot Smoke Test:** Start the built emulator image with `/dev/kvm`, wait for `/tmp/emulator-ready` (with timeout), assert `sys.boot_completed=1` and network access, and upload the container log on failure. Runners must provide KVM.
* **Registry Authentication:** Secure authentication via GitHub Secrets to target container registries.
* **Two-Stage Release Logic:**
  1. **Push to main (Version Generation):** Merges to `main` evaluate the git commit history since the last tag. If Conventional Commits contain semantic changes (`feat` or `fix`), a new version tag is automatically generated and pushed. Non-semantic changes (e.g., CI-only dependency updates) will not trigger a new tag.
  2. **Push of a Git Tag (Release Execution):** The workflow switches to the release environment when triggered by a new version tag. It executes the full build (`linux/amd64`), pushes the verified images to the designated registries, and automatically generates the GitHub Release.
* **Concurrency:** Use a conditional grouping strategy:
  * Tags and releases must use a unique `run_id` group to ensure atomicity and prevent cancellation.
  * Standard workflows (main/PRs) must use a branch-based group with `cancel-in-progress: true` to optimize runner usage.
