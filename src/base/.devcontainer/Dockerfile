FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG BASE_VERSION=latest
ARG TARGETARCH
ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ARG MULTI_ARCH_TAG
ARG BASE_VERSION
ARG IMAGE_TAG

ENV BASE_VERSION=${BASE_VERSION}
ENV TARGETARCH=${TARGETARCH}
ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV MULTI_ARCH_TAG=${MULTI_ARCH_TAG}
ENV BASE_VERSION=${BASE_VERSION}
ENV IMAGE_TAG=${IMAGE_TAG}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS base devcontainer"
LABEL org.opencontainers.image.licenses=MIT

COPY .tool-versions.asdf ${SCRIPTS_DIR}/${CONTAINER_NAME}/.tool-versions.asdf
COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}

WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

USER vscode
COPY --chown=vscode:vscode .tool-versions.asdf /home/vscode/.tool-versions.asdf
COPY --chown=vscode:vscode .tool-versions /home/vscode/.tool-versions

ENV PATH="/home/vscode/.asdf/shims/:$PATH"
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./vscode_install.sh
RUN rm -rf /home/vscode/.ssh

USER root
# store version info in VERSION.txt for reference
RUN echo "[[ ${CONTAINER_NAME} ]]" > "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "BASE_VERSION=${BASE_VERSION}" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "MULTI_ARCH_TAG=${MULTI_ARCH_TAG}" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "IMAGE_TAG=${IMAGE_TAG}" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "" >> "${SCRIPTS_DIR}/VERSION.txt"

USER vscode
WORKDIR /home/vscode
