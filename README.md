# Alpaquita Android CI Docker Images

Minimalist, high-performance Docker images for Android CI/CD pipelines. Based on Alpaquita Linux (glibc) and BellSoft Liberica JDK. Optimized with mimalloc for maximum build speed and reduced memory footprint.

> [!NOTE]
> **WIP:** This Readme is under active development. Updates will come soon.

---

## Registries & Quick Start

The images are multi-architecture (linux/amd64 and linux/arm64) and published to both Docker Hub and GitHub Container Registry (GHCR).

### Docker Hub
```bash
docker pull g00fy2/alpaquita-android:latest
```
View on Docker Hub: https://hub.docker.com/r/g00fy2/alpaquita-android

### GitHub Container Registry (GHCR)
```bash
docker pull ghcr.io/g00fy2/alpaquita-android:latest
```
View on GHCR: https://github.com/G00fY2/alpaquita-android/pkgs/container/alpaquita-android/

---

## Image Tags & Versioning Matrix

Tags follow a strict naming convention to let you pin exactly what your project needs:
`[image-version]-android-[api-level]-jdk[java-version]`

### Supported Versions
This project maintains support for the last 3 major Android API versions. Older versions are archived and no longer receive regular dependency updates.

### Available Variants
We support combinations of JDK 21 / 25 and Android API Levels 35 / 36 / 36.1 / 37.

| Android API | JDK Version | Complete Tag Example |
| :---: | :---: | :--- |
| **37.0** | 25 | `v2026.1.0-android-37.0-jdk25` |
| **37.0** | 21 | `v2026.1.0-android-37.0-jdk21` |
| **36.1** | 25 | `v2026.1.0-android-36.1-jdk25` |
| **36.1** | 21 | `v2026.1.0-android-36.1-jdk21` |
| **36** | 25 | `v2026.1.0-android-36-jdk25` |
| **36** | 21 | `v2026.1.0-android-36-jdk21` |
| **35** | 25 | `v2026.1.0-android-35-jdk25` |
| **35** | 21 | `v2026.1.0-android-35-jdk21` |

The `latest` tag points to the combination of the highest stable Android API and the highest stable JDK version (currently: Android 37.0 + JDK 25).

---

## Image Details & Environment

To support restricted Kubernetes environments, this image is completely UID agnostic and designed for non-root execution (e.g., `runAsNonRoot: true`).

* Permissions: Built using the OpenShift/Kubernetes GID 0 strategy. All tool and cache directories are owned by the root group (`chgrp -R 0`) with group permissions mirroring owner permissions (`chmod -R g=u`).
* Agnostic Home: All stateful data, Gradle caches, and Android configurations are redirected to a neutral path at `/opt/android/user` instead of `/root` or `/home`. This simplifies volume mounting for persistent CI caching.
* Android SDK Root: `/opt/android/sdk`

### Pre-installed Components
* Android SDK Platform-Tools & Build-Tools
* Command-line Tools (`cmdline-tools;latest`)
* Memory Performance: `mimalloc` preloaded via `LD_PRELOAD`
* Essential OS Packages: `bash`, `curl`, `git`, `unzip`, `openssh-client`
