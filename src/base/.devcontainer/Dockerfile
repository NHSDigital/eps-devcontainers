FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}
ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV SCRIPTS_DIR=${SCRIPTS_DIR}

ARG ASDF_VERSION
COPY .tool-versions.asdf ${SCRIPTS_DIR}/${CONTAINER_NAME}/.tool-versions.asdf

COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

USER vscode

ENV PATH="/home/vscode/.asdf/shims/:$PATH"
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
COPY --chown=vscode:vscode .tool-versions.asdf /home/vscode/.tool-versions.asdf
COPY --chown=vscode:vscode .tool-versions /home/vscode/.tool-versions

RUN ./vscode_install.sh
WORKDIR /home/vscode
