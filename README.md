# Alpaquita Android CI

Minimalist, high-performance Docker image for Android builds. Based on **Alpaquita Linux (glibc)** and **BellSoft Liberica JDK 25**. Optimized with **mimalloc** for fast CI/CD workflows.

### Quick Start
`image: ghcr.io/g00fy2/todo:latest`

### Details
- **SDK Root:** `/opt/android/sdk`
- **Config/Cache:** `/opt/android/sdk/.android-config`
- **User:** `androiduser` (UID 1000)
