<p align="center"><a href="#"><img width="196" alt="Alpaquita Android logo" src="https://github.com/user-attachments/assets/072e3c39-6f8f-4de0-b436-1c89b7a0173f" /></a></p>

# Alpaquita Android CI Docker Images

Minimalist, high-performance Docker images for Android CI/CD pipelines. Based on **Alpaquita Linux** (`glibc`) and BellSoft Liberica JDK. Optimized with `mimalloc` for maximum build speed and reduced memory footprint. Self-updating via Renovate automerge.

## Registries & Quick Start

The images (`linux/amd64` and `linux/arm64`) are published to both Docker Hub and GitHub Container Registry (GHCR).

#### Docker Hub
```bash
docker pull g00fy2/alpaquita-android:latest
```
View on [Docker Hub](https://hub.docker.com/r/g00fy2/alpaquita-android)

#### GitHub Container Registry (GHCR)
```bash
docker pull ghcr.io/g00fy2/alpaquita-android:latest
```
View on [GHCR](https://github.com/G00fY2/alpaquita-android/pkgs/container/alpaquita-android/)

> [!TIP]
> Current images and their content are listed in the latest [GitHub Release](https://github.com/g00fy2/alpaquita-android/releases/latest).

## Core Features & Focus

These images are specifically engineered for development teams and engineers who prioritize **modern, bleeding-edge Android toolchains**. If your project targets the latest stable **Android Gradle Plugin (AGP)** releases, and relies on up-to-date dependencies, this image provides the ideal runtime environment.

* **Performance Optimized:** Built on Alpaquita Linux using native `glibc` and Microsoft's `mimalloc` allocator to drastically reduce Gradle compile and garbage collection times.
* **Fully Automated Maintenance:** Driven by a proactive, "no-touch" Renovate architecture that detects and merges official Google Android SDK updates autonomously - eliminating the typical lag found in traditional CI images to ensure your pipeline is always as modern as your local development setup.
* **Immutable and Reproducible:** Offers strict pinning of all core components and base images to guarantee absolute determinism across your CI/CD pipelines.

> [!IMPORTANT]
> **Streamlined & Focused (No NDK / Emulator):** To maintain a minimal footprint and maximum execution speed, this image currently excludes the Android NDK (C/C++ toolchains) and the Android Emulator. It is strictly optimized for pure Java/Kotlin Android compilation. *(Dedicated image variants for NDK and Emulator workflows are planned for the future).*

## Image Matrix & Tagging Strategy

The repository maintains a support matrix tracking the last two Java LTS versions alongside a rolling window of the last three stable major Android API levels (including minor versions). While the Java baseline remains stable, all enclosed Android SDK components roll forward fully automatically the moment Google releases a new stable update.

### Matrix Overview example

| Android API Level (Rolling Window) | Platform Version (Minor)    | Supported Java LTS Versions | Rolling Tag Examples                                    |
|:-----------------------------------|:----------------------------|:----------------------------|:--------------------------------------------------------|
| **Latest API** (e.g., `37`)        | `37.0` *(Tracks Revisions)* | JDK 21 / JDK 25             | `android-37.0-jdk21`<br>`android-37.0-jdk25` *(latest)* |
| **Previous API** (e.g., `36`)      | `36.1` / `36.0`             | JDK 21 / JDK 25             | `android-36.1-jdk25`<br>`android-36.0-jdk21`            |
| **Older Stable API** (e.g., `35`)  | `35.0`                      | JDK 21 / JDK 25             | `android-35.0-jdk21`<br>`android-35.0-jdk25`            |

### Tag Anatomy

Every image is published with multiple alias tags to support both flexible rolling updates and strict, deterministic version pinning:

* **Dynamic / Rolling Tags:** `android-<api>-jdk<java>` (e.g., `android-37.0-jdk25`) - Automatically rolls forward to the latest pipeline release, base image updates, and minor Android platform revisions.
* **Immutable / Release Tags:** `v<year>.<release>.<patch>-android-<api>-jdk<java>` (e.g., `v2026.1.0-android-37.0-jdk25`) - Hard-pinned build that will never change, ideal for production immutability.
* **The `latest` Tag:** Points to the highest combination of the newest stable Android API level and the highest supported Java LTS version.

### Dynamic Matrix Lifecycle

This image operates on a self-shifting support window. The moment Google releases a new major Android API level, an official minor platform version, or an SDK component revision, our automated pipeline dynamically adjusts the matrix without manual intervention:

1. **Automatic Expansion:** A new stable Android API level is immediately detected, a new set of images is built, and it becomes the new top-tier target in the matrix.
2. **Rolling Shift:** The previous API levels shift down by one tier, and the oldest API level outside the three-major-version window drops out of the active matrix.
3. **Platform Revision Updates (Latest API Only):** For the *absolute latest* stable Android platform version in the matrix, the pipeline continuously tracks SDK component revisions (e.g., when Google updates the latest platform from revision `1` to revision `2`). Renovate detects these silent updates instantly and rebuilds the tags (e.g., `android-37.0-jdk25`) to ensure the toolchain is always up to date.

## Architecture & Design Decisions (FAQ)

### 1. What makes this image "optimized" compared to standard Alpine images?
Standard Alpine images rely on `musl` libc, which introduces performance overhead when running the pre-compiled Android SDK binaries. This image uses BellSoft's Alpaquita Linux with a native, optimized `glibc` implementation. Additionally, it integrates Microsoft's `mimalloc` allocator to maximize heap performance and throughput for the Kotlin Daemon and parallel Gradle workers.

### 2. Why is this image designed to be "minimalist"?
To ensure maximum download speed, minimal disk space usage, and a reduced security attack surface, this image pre-installs only the absolute bare minimum of OS packages and Android SDK components required to compile a standard project.
* **Feature Requests:** If your pipeline requires an additional system package, please open an issue in the repository to discuss the use case.
* **Future Roadmap:** There are plans to introduce separate, dedicated image variants in the future that include the Android Emulator and necessary hardware acceleration libraries, keeping this main image clean and lightweight.

### 3. What is unique about the Renovate auto-update architecture?
Instead of relying on manual updates, this project features a fully automated "no-touch" architecture via Renovate:
* **Custom Datasources:** Tracks Google's official Android SDK repository structures directly to detect updates instantly.
* **Revision Support:** Detects and applies minor SDK platform revisions automatically.
* **Automerge:** Updates that pass automated smoke tests are merged and deployed autonomously, keeping the toolchain current without human intervention.

### 4. How is the quality and size of each release guaranteed?
Before any image is pushed to public registries, it undergoes a strict verification pipeline:
1. **Smoke Test:** Assembles a real Android test project inside the container to verify compiler and runtime stability.
2. **Audit:** Scans for vulnerabilities via `Trivy` and audits layers via `Dive` to maintain a minimal footprint (~340MB compressed using `zstd` level 9).

### 5. Why does every API level image include the absolute latest Build-Tools version?
Google recommends omitting `buildToolsVersion`, letting the Android Gradle Plugin (AGP) choose a default. This introduces critical issues for CI/CD:
* **AGP Hardcoding:** Default versions are hardcoded inside AGP, meaning it often lags behind and forces the use of older Build-Tools even if you upgrade your `compileSdk`.
* **Lagging Bugfixes:** You miss out on crucial compiler bugfixes unless you explicitly override the version.
* **Deterministic Builds:** Without an explicit version, AGP scans the local runner environment dynamically, which can lead to unpredictable behavior or accidental fallback to preview versions.

### 6. Why are Android Home and Gradle Home isolated under `/opt/android/user`?
Anchoring `ANDROID_HOME` and `GRADLE_USER_HOME` in a single, user-agnostic path decouples the toolchain from specific host user layouts. This simplifies the setup of persistent volume mounts in Kubernetes or GitLab CI, enabling efficient dependency caching and optimal I/O throughput.

### 7. How does the image handle Kubernetes and OpenShift security contexts?
Enterprise platforms often forbid running containers as `root` or using static non-root UIDs. This image implements the OpenShift GID 0 pattern: all system directories, configurations, and binaries grant read/write/execute permissions to the root group (`GID 0`). This allows the container to run under arbitrary, dynamically assigned UIDs while maintaining full toolchain access.

## License
    The MIT License (MIT)
    
    Copyright (C) 2026 Thomas Wirth
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
    OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

