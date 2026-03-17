# syntax=docker/dockerfile:1@sha256:4a43a54dd1fedceb30ba47e76cfcf2b47304f4161c0caeac2db1c61804ea3c91
# check=experimental=all;error=true

ARG BASE_IMAGE=jdk25

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-21.0.10_10-glibc@sha256:9f1cde8be06f4d8d3db9f512e7132369f08de9a8afd9a54e0639585cf790ecbd AS jdk21
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25.0.2_12-glibc@sha256:4440de3ce0ca8a2187976f9b5ec101a2e1d1fb03b096596ac0144e9735af2d5e AS jdk25

FROM ${BASE_IMAGE}

ARG ANDROID_CMDLINE_TOOLS_ID
ARG ANDROID_PLATFORM_TOOLS_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION
ARG ANDROID_PLATFORM_VERSION
ARG USER_UID=1000
ARG MIMALLOC_PATH=/usr/lib/libmimalloc_stable.so

LABEL org.opencontainers.image.title="Alpaquita Android" \
      org.opencontainers.image.description="Optimized Android CI Image based on Alpaquita and mimalloc" \
      org.opencontainers.image.source="https://github.com/G00fY2/alpaquita-android" \
      org.opencontainers.image.licenses="MIT"

ENV ANDROID_HOME="/opt/android/sdk"
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_USER_HOME="${ANDROID_HOME}/.android-home"
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

RUN --mount=type=bind,source=scripts/setup-alpaquita.sh,target=/tmp/setup-alpaquita.sh \
    --mount=type=bind,source=scripts/setup-android.sh,target=/tmp/setup-android.sh \
    addgroup -g "${USER_UID}" androidgroup && \
    adduser -D -u "${USER_UID}" -G androidgroup androiduser && \
    /bin/sh /tmp/setup-alpaquita.sh "${MIMALLOC_PATH}" && \
    /bin/bash /tmp/setup-android.sh \
    "${USER_UID}" \
    "${ANDROID_CMDLINE_TOOLS_ID}" \
    "${ANDROID_PLATFORM_TOOLS_VERSION}" \
    "${ANDROID_BUILD_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_VERSION}"

ENV LD_PRELOAD=$MIMALLOC_PATH

USER ${USER_UID}

CMD ["/bin/bash"]
