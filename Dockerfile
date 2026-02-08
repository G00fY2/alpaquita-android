# syntax=docker/dockerfile:1

ARG BASE_IMAGE=jdk25

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-21-glibc AS jdk21
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25-glibc AS jdk25

FROM ${BASE_IMAGE}

ARG IMAGE_VERSION
ARG GIT_HASH
ARG ANDROID_CMDLINE_TOOLS_VERSION
ARG ANDROID_PLATFORM_TOOLS_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION
ARG ANDROID_PLATFORM_VERSION
ARG USER_UID=1000

LABEL org.opencontainers.image.title="Alpaquita Android" \
      org.opencontainers.image.description="Optimized Android CI Image based on Alpaquita and mimalloc" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${GIT_HASH}" \
      org.opencontainers.image.source="https://github.com/G00fY2/alpaquita-android" \
      org.opencontainers.image.licenses="MIT"

RUN addgroup -g "${USER_UID}" androidgroup && \
    adduser -D -u "${USER_UID}" -G androidgroup androiduser

ENV ANDROID_HOME="/opt/android/sdk"
ENV ANDROID_USER_HOME="${ANDROID_HOME}/.android-home"

ENV PATH=$PATH:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

RUN --mount=type=bind,source=scripts/setup-alpaquita.sh,target=/tmp/setup-alpaquita.sh \
    /bin/sh /tmp/setup-alpaquita.sh

RUN --mount=type=bind,source=scripts/setup-android.sh,target=/tmp/setup-android.sh \
    /bin/sh /tmp/setup-android.sh \
    "${USER_UID}" \
    "${ANDROID_CMDLINE_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_TOOLS_VERSION}" \
    "${ANDROID_BUILD_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_VERSION}"

ENV LD_PRELOAD="/usr/lib/libmimalloc_stable.so"

RUN MIMALLOC_VERBOSE=1 ls 2>&1 | grep -q "mimalloc: process init" || \
    (echo "ERROR: mimalloc not active!" && exit 1)

USER ${USER_UID}

