FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ARG IMAGE_TAG
ARG TARGETARCH

ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV TARGETARCH=${TARGETARCH}

COPY .tool-versions.asdf ${SCRIPTS_DIR}/${CONTAINER_NAME}/.tool-versions.asdf
COPY --chmod=755 scripts/root_install.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/root_install.sh
COPY --chmod=755 Mk ${SCRIPTS_DIR}/Mk

WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

COPY --chmod=755 scripts/vscode_install.sh ${SCRIPTS_DIR}/${CONTAINER_NAME}/vscode_install.sh
USER vscode
COPY --chown=vscode:vscode .tool-versions.asdf /home/vscode/.tool-versions.asdf
COPY --chown=vscode:vscode .tool-versions /home/vscode/.tool-versions

ENV PATH="/home/vscode/.asdf/shims/:/home/vscode/.guard/bin/:$PATH"
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./vscode_install.sh

# Switch back to root to install the devcontainer CLI globally
USER root

ENV IMAGE_TAG=${IMAGE_TAG}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS devcontainer ${CONTAINER_NAME}:${IMAGE_TAG}"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.containerName=${CONTAINER_NAME}
LABEL org.opencontainers.image.authors="NHS England EPS Team"
LABEL org.opencontainers.image.base.image="mcr.microsoft.com/devcontainers/base:ubuntu-22.04"
