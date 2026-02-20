# syntax=docker/dockerfile:1@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6
# check=experimental=all;error=true

ARG BASE_IMAGE=jdk25

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-21-glibc@sha256:e820a6ecc71d404c224d123160ef3b229ee44690fa78eec87f7fde11c177df9c AS jdk21
FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25-glibc@sha256:96d9be84078ddfd88a927c5194decf5a2f648f884457d4024afd577930317def AS jdk25

FROM ${BASE_IMAGE}

ARG IMAGE_VERSION
ARG GIT_HASH
ARG ANDROID_CMDLINE_TOOLS_ID
ARG ANDROID_PLATFORM_TOOLS_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION
ARG ANDROID_PLATFORM_VERSION
ARG USER_UID=1000
ARG MIMALLOC_PATH=/usr/lib/libmimalloc_stable.so

LABEL org.opencontainers.image.title="Alpaquita Android" \
      org.opencontainers.image.description="Optimized Android CI Image based on Alpaquita and mimalloc" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${GIT_HASH}" \
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
