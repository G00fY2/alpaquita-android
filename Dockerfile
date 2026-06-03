# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=experimental=all;error=true

ARG BASE_IMAGE=jdk25

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-21.0.11_11-glibc@sha256:784b7f65a72538082cadd5d8228fe219dab19b6a38fceda9787bc07b9bf22a63 AS jdk21
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25.0.3_11-glibc@sha256:4dec427258850c884b85e8f4b522c5d77302f0c8d67b9792c2738e8476f96a4e AS jdk25

FROM ${BASE_IMAGE}

ARG ANDROID_CMDLINE_TOOLS_ID
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
    /bin/sh /tmp/setup-alpaquita.sh "${MIMALLOC_PATH}" && \
    /bin/bash /tmp/setup-android.sh \
    "${ANDROID_CMDLINE_TOOLS_ID}" \
    "${ANDROID_PLATFORM_TOOLS_VERSION}" \
    "${ANDROID_BUILD_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_VERSION}" && \
    mkdir -p "${ANDROID_USER_HOME}" "${GRADLE_USER_HOME}" && \
    chgrp -R 0 "${ANDROID_HOME}" "${ANDROID_SDK_HOME}" && \
    chmod -R g=u "${ANDROID_HOME}" "${ANDROID_SDK_HOME}"

ENV LD_PRELOAD=$MIMALLOC_PATH

CMD ["/bin/bash"]
