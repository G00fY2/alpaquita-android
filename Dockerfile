# syntax=docker/dockerfile:1@sha256:2780b5c3bab67f1f76c781860de469442999ed1a0d7992a5efdf2cffc0e3d769
# check=experimental=all;error=true

ARG BASE_IMAGE=jdk25

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-21.0.10_10-glibc@sha256:7922124bb9a28abfbc1116118466e56ccb6a3c4af79732f60c8f768bc341e4fe AS jdk21
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25.0.2_12-glibc@sha256:c0c5e72966679cbf0ba77cbe3184fc4953b80b2b153fe2bda3f3188a2da14a2b AS jdk25

FROM ${BASE_IMAGE}

ARG ANDROID_CMDLINE_TOOLS_ID
ARG ANDROID_PLATFORM_TOOLS_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION
ARG ANDROID_PLATFORM_VERSION
ARG MIMALLOC_PATH=/usr/lib/libmimalloc_stable.so

LABEL org.opencontainers.image.title="Alpaquita Android" \
      org.opencontainers.image.description="Optimized Android CI image (Alpaquita/mimalloc). Self-updating via Renovate automerge." \
      org.opencontainers.image.source="https://github.com/g00fy2/alpaquita-android" \
      org.opencontainers.image.licenses="MIT"

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
