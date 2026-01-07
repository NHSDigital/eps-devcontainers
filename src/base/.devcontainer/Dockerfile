FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}
ARG SCRIPTS_DIR=/usr/local/share/eps/
ARG CONTAINER_NAME
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV SCRIPTS_DIR=${SCRIPTS_DIR}

ARG ASDF_VERSION
COPY .tool-versions.asdf /tmp/.tool-versions.asdf

COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

USER vscode

ENV PATH="/home/vscode/.asdf/shims/:$PATH"
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
COPY .tool-versions.asdf /home/vscode/.tool-versions.asdf
COPY .tool-versions /home/vscode/.tool-versions
COPY language_versions/nodejs-versions.txt /tmp/nodejs-versions.txt
COPY language_versions/python-versions.txt /tmp/python-versions.txt
COPY language_versions/java-versions.txt /tmp/java-versions.txt
COPY language_versions/terraform-versions.txt /tmp/terraform-versions.txt
COPY language_versions/golang-versions.txt /tmp/golang-versions.txt

RUN ./vscode_install.sh
