FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}
ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV SCRIPTS_DIR=${SCRIPTS_DIR}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS base devcontainer"
LABEL org.opencontainers.image.licenses=MIT

ARG ASDF_VERSION
COPY .tool-versions.asdf ${SCRIPTS_DIR}/${CONTAINER_NAME}/.tool-versions.asdf

COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh
RUN requested_uid="${VSCODE_UID:-1000}" \
    && requested_gid="${VSCODE_GID:-1000}" \
    && current_uid="$(id -u vscode)" \
    && current_gid="$(id -g vscode)" \
    && if [ "${current_gid}" != "${requested_gid}" ]; then groupmod -g "${requested_gid}" vscode; fi \
    && if [ "${current_uid}" != "${requested_uid}" ]; then usermod -u "${requested_uid}" -g "${requested_gid}" vscode; fi \
    && chown -R vscode:vscode /home/vscode

USER vscode

ENV PATH="/home/vscode/.asdf/shims/:$PATH"
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
COPY --chown=vscode:vscode .tool-versions.asdf /home/vscode/.tool-versions.asdf
COPY --chown=vscode:vscode .tool-versions /home/vscode/.tool-versions

RUN ./vscode_install.sh
