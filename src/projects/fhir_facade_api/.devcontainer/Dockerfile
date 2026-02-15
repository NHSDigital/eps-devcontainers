ARG BASE_VERSION_TAG=latest
ARG BASE_IMAGE=ghcr.io/nhsdigital/eps-devcontainers/node_24_python_3_13:${BASE_VERSION_TAG}

FROM ${BASE_IMAGE}

ARG SCRIPTS_DIR=/usr/local/share/eps
ARG CONTAINER_NAME
ARG MULTI_ARCH_TAG
ARG BASE_VERSION_TAG
ARG IMAGE_TAG
ARG TARGETARCH

ENV SCRIPTS_DIR=${SCRIPTS_DIR}
ENV CONTAINER_NAME=${CONTAINER_NAME}
ENV MULTI_ARCH_TAG=${MULTI_ARCH_TAG}
ENV BASE_VERSION_TAG=${BASE_VERSION_TAG}
ENV IMAGE_TAG=${IMAGE_TAG}
ENV TARGETARCH=${TARGETARCH}

LABEL org.opencontainers.image.source=https://github.com/NHSDigital/eps-devcontainers
LABEL org.opencontainers.image.description="EPS fhir facade devcontainer"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.version=${IMAGE_TAG}
LABEL org.opencontainers.image.baseImage=${BASE_IMAGE}
LABEL org.opencontainers.image.containerName=${CONTAINER_NAME}

USER root
COPY --chmod=755 scripts ${SCRIPTS_DIR}/${CONTAINER_NAME}
WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
RUN ./root_install.sh

USER vscode

WORKDIR ${SCRIPTS_DIR}/${CONTAINER_NAME}
COPY .tool-versions /tmp/.tool-versions
RUN cat /tmp/.tool-versions >> /home/vscode/.tool-versions

RUN ./vscode_install.sh

# Switch back to root to install the devcontainer CLI globally
USER root
