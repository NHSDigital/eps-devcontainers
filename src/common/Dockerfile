ARG BASE_VERSION=latest

FROM ghcr.io/nhsdigital/eps-devcontainers/base:${BASE_VERSION}

ARG BASE_VERSION=latest
ARG TARGETARCH
ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ARG DOCKER_TAG
ARG BASE_VERSION
ARG IMAGE_TAG

ENV BASE_VERSION=${BASE_VERSION}
ENV TARGETARCH=${TARGETARCH}
ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV DOCKER_TAG=${DOCKER_TAG}
ENV BASE_VERSION=${BASE_VERSION}
ENV IMAGE_TAG=${IMAGE_TAG}

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
ENV PATH="/home/vscode/.asdf/shims/:$PATH"

RUN ./vscode_install.sh
RUN rm -rf /home/vscode/.ssh

USER root
# store version info in VERSION.txt for reference
RUN echo "[[ ${CONTAINER_NAME} ]]" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "BASE_VERSION=${BASE_VERSION}" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "DOCKER_TAG=${DOCKER_TAG}" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "IMAGE_TAG=${IMAGE_TAG}" >> "${SCRIPTS_DIR}/VERSION.txt" && \
    echo "" >> "${SCRIPTS_DIR}/VERSION.txt"

USER vscode
WORKDIR /home/vscode
