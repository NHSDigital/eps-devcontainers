ARG BASE_VERSION=latest

FROM ghcr.io/nhsdigital/eps-devcontainers/node_24_python_3_13:${BASE_VERSION}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS fhir facade devcontainer"
LABEL org.opencontainers.image.licenses=MIT

USER root
COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh


USER vscode

USER vscode

WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
COPY .tool-versions /tmp/.tool-versions
RUN cat /tmp/.tool-versions >> /home/vscode/.tool-versions

RUN ./vscode_install.sh
WORKDIR /home/vscode
