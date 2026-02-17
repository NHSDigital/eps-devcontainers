ARG BASE_IMAGE_NAME=base
ARG BASE_IMAGE_TAG=latest
FROM ghcr.io/nhsdigital/eps-devcontainers/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

# changes needed so that it can be used by github actions
## change vscode user and group id to be 1001
## change and move vscode home dir to be /github/home

RUN requested_uid=1001 \
	&& requested_gid=1001 \
	&& current_uid="$(id -u vscode)" \
	&& current_gid="$(id -g vscode)" \
	&& if [ "${current_gid}" != "${requested_gid}" ]; then groupmod -g "${requested_gid}" vscode; fi \
	&& if [ "${current_uid}" != "${requested_uid}" ]; then usermod -u "${requested_uid}" -g "${requested_gid}" vscode; fi \
	&& mkdir -p /github \
	&& usermod -d /github/home -m vscode \
	&& chown -R vscode:vscode /github/home

ENV PATH="/github/home/.asdf/shims/:/github/home/.guard/bin/:$PATH:/root_path_mod"
USER vscode
ENV PATH="/github/home/.asdf/shims/:/github/home/.guard/bin/:$PATH:/vscode_path_mod"
USER root
