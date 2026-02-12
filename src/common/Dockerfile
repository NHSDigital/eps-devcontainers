FROM ghcr.io/nhsdigital/eps-devcontainers/base:latest

# common Dockerfile used to setup poetry after installing python

ARG POETRY_VERSION=2.3.2

RUN curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION}

ENV PATH="/home/vscode/.local/bin:${PATH}"
