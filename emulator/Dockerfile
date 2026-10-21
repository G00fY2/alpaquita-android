# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=experimental=all;error=true

ARG ANDROID_IMAGE_VERSION
ARG ANDROID_DEVICE_PROFILE=medium_phone
ARG ANDROID_IMAGE_VARIANT=google_atd
ARG ANDROID_IMAGE_ARCH=x86_64
ARG ANDROID_HOME=/opt/android/sdk
ARG ANDROID_USER_HOME_BASE=/opt/android/user

FROM ghcr.io/bell-sw/liberica-runtime-container:jdk-25.0.4_9-glibc@sha256:15040ae05e80cf034bb4e8def353eb2563228a39581545ea6c24faf4baf7a439 AS builder

ARG ANDROID_HOME
ARG ANDROID_USER_HOME_BASE
ARG ANDROID_DEVICE_PROFILE
ARG ANDROID_IMAGE_VERSION
ARG ANDROID_IMAGE_VARIANT
ARG ANDROID_IMAGE_ARCH
ARG ANDROID_CLI_VERSION

ARG ANDROID_CMDLINE_TOOLS_VERSION
ARG ANDROID_PLATFORM_TOOLS_VERSION
ARG ANDROID_EMULATOR_VERSION

ENV ANDROID_HOME=${ANDROID_HOME}
ENV ANDROID_USER_HOME=${ANDROID_USER_HOME_BASE}/.android
ENV ANDROID_EMULATOR_HOME=${ANDROID_USER_HOME}
ENV ANDROID_AVD_HOME=${ANDROID_USER_HOME}/avd
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

RUN --mount=type=bind,source=scripts/builder/setup-alpaquita.sh,target=/tmp/builder/setup-alpaquita.sh \
    --mount=type=bind,source=scripts/builder/setup-android-sdk.sh,target=/tmp/builder/setup-android-sdk.sh \
    --mount=type=bind,source=scripts/builder/setup-virtual-device.sh,target=/tmp/builder/setup-virtual-device.sh \
    /bin/sh /tmp/builder/setup-alpaquita.sh && \
    /bin/bash /tmp/builder/setup-android-sdk.sh \
    "${ANDROID_CLI_VERSION}" \
    "${ANDROID_CMDLINE_TOOLS_VERSION}" \
    "${ANDROID_PLATFORM_TOOLS_VERSION}" \
    "${ANDROID_EMULATOR_VERSION}" \
    "${ANDROID_IMAGE_VERSION}" \
    "${ANDROID_IMAGE_VARIANT}" \
    "${ANDROID_IMAGE_ARCH}" && \
    /bin/bash /tmp/builder/setup-virtual-device.sh \
    "${ANDROID_DEVICE_PROFILE}" \
    "${ANDROID_IMAGE_VERSION}" \
    "${ANDROID_IMAGE_VARIANT}" \
    "${ANDROID_IMAGE_ARCH}" && \
    mkdir -p "${ANDROID_USER_HOME}" && \
    touch "${ANDROID_EMULATOR_HOME}/emu-update-last-check.ini" && \
    chgrp -R 0 "${ANDROID_HOME}" "${ANDROID_USER_HOME_BASE}" && \
    chmod -R g=u "${ANDROID_HOME}" "${ANDROID_USER_HOME_BASE}"

# Optimize footprint for headless CI by stripping GUI toolkit (Qt) and non-x86_64 and non-headless QEMU engines
RUN rm -rf \
    "${ANDROID_HOME}/emulator/lib64/qt" \
    "${ANDROID_HOME}"/emulator/qemu/linux-x86_64/qemu-system-aarch64* \
    "${ANDROID_HOME}"/emulator/qemu/linux-x86_64/qemu-system-armel* \
    "${ANDROID_HOME}"/emulator/qemu/linux-x86_64/qemu-system-i386* \
    "${ANDROID_HOME}/emulator/qemu/linux-x86_64/qemu-system-x86_64"

FROM ghcr.io/bell-sw/alpaquita-linux-base:glibc@sha256:b3c009fbc72d19d02771938cc5811f6abe8039381c39a24881ca06a9f5286ff6 AS emulator

ARG ANDROID_HOME
ARG ANDROID_USER_HOME_BASE
ARG ANDROID_DEVICE_PROFILE
ARG ANDROID_IMAGE_VERSION
ARG ANDROID_IMAGE_VARIANT
ARG ANDROID_IMAGE_ARCH

LABEL org.opencontainers.image.description="Minimal Android Headless Emulator image (Alpaquita). Self-updating via Renovate automerge." \
      org.opencontainers.image.licenses="MIT AND LicenseRef-Android-SDK" \
      org.opencontainers.image.source="https://github.com/g00fy2/alpaquita-android" \
      org.opencontainers.image.title="Alpaquita Android Emulator"

ENV ANDROID_HOME=${ANDROID_HOME}
ENV ANDROID_USER_HOME=${ANDROID_USER_HOME_BASE}/.android
ENV EMULATOR_NAME=${ANDROID_DEVICE_PROFILE}
ENV ANDROID_EMULATOR_HOME=${ANDROID_USER_HOME}
ENV ANDROID_AVD_HOME=${ANDROID_USER_HOME}/avd
ENV PATH=${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools

RUN --mount=type=bind,source=scripts/setup-alpaquita.sh,target=/tmp/setup-alpaquita.sh \
    /bin/sh /tmp/setup-alpaquita.sh

COPY --parents --from=builder \
    ${ANDROID_HOME}/emulator \
    ${ANDROID_HOME}/platform-tools \
    ${ANDROID_HOME}/system-images/android-${ANDROID_IMAGE_VERSION}/${ANDROID_IMAGE_VARIANT}/${ANDROID_IMAGE_ARCH} \
    /

COPY --parents --from=builder \
    ${ANDROID_AVD_HOME} \
    ${ANDROID_EMULATOR_HOME}/emu-update-last-check.ini \
    /

COPY --chmod=755 scripts/start-emulator.sh /usr/local/bin/start-emulator

ENTRYPOINT ["/usr/local/bin/start-emulator"]
