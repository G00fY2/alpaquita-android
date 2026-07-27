<p align="center"><a href="#"><img width="196" alt="Alpaquita Android logo" src="https://github.com/user-attachments/assets/072e3c39-6f8f-4de0-b436-1c89b7a0173f" /></a></p>

# Alpaquita Android CI Docker Images

Minimalist, high-performance Docker images for Android CI/CD pipelines. Based on **Alpaquita Linux**[^1] (`glibc`) and BellSoft Liberica JDK[^2]. Optimized with `mimalloc`[^3] for maximum build speed and reduced memory footprint. Self-updating via Renovate automerge.

## Quick Start

Images are published to both Docker Hub and GHCR:

#### [Docker Hub](https://hub.docker.com/r/g00fy2/alpaquita-android)
```bash
docker pull g00fy2/alpaquita-android:latest
```

#### [GitHub Container Registry (GHCR)](https://github.com/g00fY2/alpaquita-android/pkgs/container/alpaquita-android/)
```bash
docker pull ghcr.io/g00fy2/alpaquita-android:latest
```

> [!TIP]
> Available images and their content are listed in the latest [GitHub Release](https://github.com/g00fy2/alpaquita-android/releases/latest).

## Why this image?

- **Faster builds** - `glibc` (via Alpaquita Linux) avoids the performance overhead of Alpine's `musl`, and Microsoft's `mimalloc` allocator speeds up the Kotlin Daemon and parallel Gradle workers.
- **Always current** - Renovate tracks Google's official Android SDK repositories directly and auto-merges updates (including minor platform revisions) as soon as they're released - no manual lag.
- **Minimal & secure** - Only the OS packages and SDK components needed to compile a standard Java/Kotlin project are included, keeping the image small (~340 MB compressed) and the attack surface low.
- **Reproducible** - All core components and base images are strictly pinned for deterministic CI/CD builds.
- **K8s/OpenShift-ready** - Follows the OpenShift GID 0 pattern for `/opt/android/sdk` and `/opt/android/user`, so the container runs under arbitrary non-root UIDs while keeping access to the toolchain.

> [!IMPORTANT]
> **Not included:** Android NDK and the Android Emulator. This image is focused purely on Java/Kotlin compilation; dedicated NDK/Emulator variants are planned.

## Image Matrix & Tagging

The matrix covers the current Java baseline alongside the three most recent stable major Android API levels (with minor versions). SDK components roll forward automatically as Google ships updates - no separate action needed on the Java side.

| Android API (rolling window) | Platform version | Java versions | Example tags |
|---|---|---|---|
| Latest (e.g. `37`) | `37.1` / `37.0` | JDK 26 / 25 / 21 | `android-37.1-jdk26` … `android-37.0-jdk21` |
| Previous (e.g. `36`) | `36.1` / `36.0` | JDK 26 / 25 / 21 | `android-36.1-jdk26` … `android-36.0-jdk21` |
| Older (e.g. `35`) | `35.0` | JDK 26 / 25 / 21 | `android-35.0-jdk26` … `android-35.0-jdk21` |

- **Rolling tags** - `android-<api>-jdk<java>` - always point to the latest build for that API/JDK combo.
- **Immutable tags** - `android-<api>-jdk<java>-v<year>.<release>.<patch>` - pinned forever, for production use.
- **`latest`** - newest stable API level combined with the highest supported Java version.

When Google ships a new major API level, it's added at the top of the matrix and the oldest one drops out. Minor SDK revisions for the current top API are picked up automatically as they're published.

## FAQ

**Why is it "minimalist"?**\
Only the bare minimum of OS packages and SDK components needed to compile a standard project are pre-installed, to keep download size, disk usage and attack surface as small as possible. Emulator, hardware acceleration libs and NDK support are planned as separate, dedicated variants rather than being bundled in. Missing a package your pipeline needs? Open an issue.

**What's special about the Renovate auto-update setup?**\
It uses custom datasources that track Google's official Android SDK repo structure directly (including minor revision bumps), and automerges any update that passes the automated smoke tests, without manual intervention.

**How is release quality and size guaranteed?**\
Every image runs a smoke test (assembling a real Android test project inside the container), then gets scanned for vulnerabilities with `Trivy` and audited layer-by-layer with `Dive`. Compressed size lands around 340 MB (zstd level 9).

**Why does every API-level image ship the newest Build-Tools version?**\
Google's recommended default (letting AGP pick `buildToolsVersion`) causes problems in CI: the default is hardcoded into AGP and often lags behind, you miss recent compiler bugfixes, and without an explicit version AGP scans the local runner environment, which can behave unpredictably. Pinning the latest version avoids all of that.

**Why are `ANDROID_HOME` and `GRADLE_USER_HOME` under `/opt/android/user`?**\
Anchoring them to a single, user-agnostic path decouples the toolchain from any specific host user layout, which makes setting up persistent volume mounts (Kubernetes, GitLab CI) and dependency caching a lot simpler.

**How does it handle Kubernetes/OpenShift security contexts?**\
Many enterprise platforms don't allow containers to run as `root` or with a static non-root UID. This image follows the OpenShift GID 0 pattern for its toolchain paths (`/opt/android/sdk` and `/opt/android/user`): those directories are readable/writable/executable by the root group (GID 0), so the container works under arbitrary, dynamically assigned UIDs.

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

[^1]: [Alpaquita Linux](https://bell-sw.com/alpaquita-linux/)
[^2]: [Liberica JDK](https://bell-sw.com/libericajdk/)
[^3]: [mimalloc](https://github.com/microsoft/mimalloc)
