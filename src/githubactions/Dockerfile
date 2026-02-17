ARG BASE_IMAGE_NAME=base
ARG BASE_IMAGE_TAG=latest
FROM ghcr.io/nhsdigital/eps-devcontainers/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

RUN requested_uid=1001 \
	&& requested_gid=1001 \
	&& current_uid="$(id -u vscode)" \
	&& current_gid="$(id -g vscode)" \
	&& if [ "${current_gid}" != "${requested_gid}" ]; then groupmod -g "${requested_gid}" vscode; fi \
	&& if [ "${current_uid}" != "${requested_uid}" ]; then usermod -u "${requested_uid}" -g "${requested_gid}" vscode; fi \
	&& chown -R vscode:vscode /home/vscode
