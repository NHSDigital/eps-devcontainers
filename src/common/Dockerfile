ARG BASE_VERSION=latest

FROM ghcr.io/nhsdigital/eps-devcontainers/base:${BASE_VERSION}

ARG CONTAINER_NAME
ENV CONTAINER_NAME=${CONTAINER_NAME}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS ${CONTAINER_NAME} devcontainer"
LABEL org.opencontainers.image.licenses=MIT

USER root
COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

USER vscode

WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
COPY .tool-versions /tmp/.tool-versions
RUN cat /tmp/.tool-versions >> /home/vscode/.tool-versions

RUN ./vscode_install.sh
WORKDIR /home/vscode

# need to finish as root
USER root
