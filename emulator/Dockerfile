# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# check=experimental=all;error=true

ARG BASE_IMAGE=ghcr.io/g00fy2/alpaquita-android:latest

FROM ${BASE_IMAGE} AS android

ARG ANDROID_EMULATOR_VERSION
ARG ANDROID_IMAGE_VERSION
ARG ANDROID_IMAGE_VARIANT=google_atd
ARG ANDROID_IMAGE_ARCH=x86_64
ARG ANDROID_IMAGE_REVISION
ARG ANDROID_DEVICE_DEFINITION

RUN --mount=type=bind,source=scripts/setup-virtual-device.sh,target=/tmp/setup-virtual-device.sh \
    /bin/bash /tmp/setup-virtual-device.sh \
    "${ANDROID_EMULATOR_VERSION}" \
    "${ANDROID_IMAGE_VERSION}" \
    "${ANDROID_IMAGE_REVISION}" \
    "${ANDROID_IMAGE_VARIANT}" \
    "${ANDROID_IMAGE_ARCH}" \
    "${ANDROID_DEVICE_DEFINITION}"

# Optimize footprint for headless CI by stripping GUI toolkit (Qt) and non-x86_64 QEMU engines
RUN rm -rf ${ANDROID_HOME}/emulator/lib64/qt && \
    rm -f \
    ${ANDROID_HOME}/emulator/qemu/linux-x86_64/qemu-system-aarch64* \
    ${ANDROID_HOME}/emulator/qemu/linux-x86_64/qemu-system-armel* \
    ${ANDROID_HOME}/emulator/qemu/linux-x86_64/qemu-system-i386* \
    ${ANDROID_HOME}/emulator/qemu/linux-x86_64/qemu-system-x86_64

FROM ghcr.io/bell-sw/alpaquita-linux-base:glibc@sha256:68c2ddf82cc7913fd178fd5b54dda5ffa11251c318a4cd0dff865d7ec1f8eefd  AS emulator

ARG ANDROID_IMAGE_VERSION
ARG ANDROID_IMAGE_VARIANT
ARG ANDROID_IMAGE_ARCH
ARG ANDROID_DEVICE_DEFINITION
ARG ANDROID_USER_HOME_BASE=/opt/android/user

LABEL org.opencontainers.image.description="Minimal Android Headless Emulator image (Alpaquita). Self-updating via Renovate automerge." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/g00fy2/alpaquita-android" \
      org.opencontainers.image.title="Alpaquita Android Emulator"

ENV ANDROID_HOME=/opt/android/sdk
ENV ANDROID_USER_HOME=${ANDROID_USER_HOME_BASE}/.android
ENV ANDROID_EMULATOR_HOME=${ANDROID_USER_HOME}
ENV ANDROID_AVD_HOME=${ANDROID_USER_HOME}/avd
ENV AVD_NAME=${ANDROID_DEVICE_DEFINITION}
ENV PATH=${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools

RUN --mount=type=bind,source=scripts/setup-alpaquita.sh,target=/tmp/setup-alpaquita.sh \
    /bin/sh /tmp/setup-alpaquita.sh

COPY --parents --from=android \
    ${ANDROID_HOME}/emulator \
    ${ANDROID_HOME}/platform-tools \
    ${ANDROID_HOME}/system-images/android-${ANDROID_IMAGE_VERSION}/${ANDROID_IMAGE_VARIANT}/${ANDROID_IMAGE_ARCH} \
    /

COPY --parents --from=android ${ANDROID_AVD_HOME} /

RUN touch "${ANDROID_EMULATOR_HOME}/emu-update-last-check.ini" && \
    chgrp -R 0 "${ANDROID_USER_HOME_BASE}" && \
    chmod -R g=u "${ANDROID_USER_HOME_BASE}"

COPY --chmod=755 scripts/start-emulator.sh /usr/local/bin/start-emulator

ENTRYPOINT ["/usr/local/bin/start-emulator"]
