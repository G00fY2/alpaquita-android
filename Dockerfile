# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=experimental=all;error=true

ARG BASE_IMAGE=jdk25

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-21.0.12_10-glibc@sha256:f455780be1384cb8fb17a5844171aebe668f8d9a09aa721a47d89b4acf39197f AS jdk21
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25.0.4_9-glibc@sha256:15040ae05e80cf034bb4e8def353eb2563228a39581545ea6c24faf4baf7a439 AS jdk25
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-26.0.2_13-glibc@sha256:b6a4a1c75040df576f21267f85c28784357aa15b1d98ae9255b3eca91a52aedb AS jdk26

FROM ${BASE_IMAGE}

ARG ANDROID_CMDLINE_TOOLS_VERSION
ARG ANDROID_PLATFORM_TOOLS_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION
ARG ANDROID_PLATFORM_VERSION
ARG MIMALLOC_PATH=/usr/lib/libmimalloc_stable.so

LABEL org.opencontainers.image.description="Optimized Android CI image (Alpaquita/mimalloc). Self-updating via Renovate automerge." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/g00fy2/alpaquita-android" \
      org.opencontainers.image.title="Alpaquita Android"

ENV ANDROID_HOME=/opt/android/sdk
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_SDK_HOME=/opt/android/user
ENV ANDROID_USER_HOME=${ANDROID_SDK_HOME}/.android
ENV GRADLE_USER_HOME=${ANDROID_SDK_HOME}/.gradle
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

RUN --mount=type=bind,source=scripts/setup-alpaquita.sh,target=/tmp/setup-alpaquita.sh \
    --mount=type=bind,source=scripts/setup-android.sh,target=/tmp/setup-android.sh \
    --mount=type=bind,source=scripts/android-tools,target=/tmp/android-tools \
    /bin/sh /tmp/setup-alpaquita.sh "${MIMALLOC_PATH}" && \
    /bin/bash /tmp/setup-android.sh \
    "${ANDROID_CMDLINE_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_TOOLS_VERSION}" \
    "${ANDROID_BUILD_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_VERSION}" && \
    cp /tmp/android-tools /usr/local/bin/android-tools && \
    mkdir -p "${ANDROID_USER_HOME}" "${GRADLE_USER_HOME}" && \
    chgrp -R 0 "${ANDROID_HOME}" "${ANDROID_SDK_HOME}" && \
    chmod -R g=u "${ANDROID_HOME}" "${ANDROID_SDK_HOME}"

ENV LD_PRELOAD=$MIMALLOC_PATH

CMD ["/bin/bash"]
