FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG BASE_VERSION=latest
ARG TARGETARCH
ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ENV TARGETARCH=${TARGETARCH}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV BASE_VERSION=${BASE_VERSION}

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
