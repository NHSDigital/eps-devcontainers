CONTAINER_PREFIX=ghcr.io/nhsdigital/eps-devcontainer-
CONTAINER_NAME=base
IMAGE_NAME=${CONTAINER_PREFIX}$(CONTAINER_NAME)
WORKSPACE_FOLDER=.

install: install-python install-node install-hooks

install-python:
	poetry install

install-node:
	npm install

install-hooks: install-python
	poetry run pre-commit install --install-hooks --overwrite

install-hooks:
build-base-image: generate-language-version-files
	CONTAINER_NAME=$(CONTAINER_NAME) \
	npx devcontainer build \
		--workspace-folder ./src/base/ \
		--push false \
		--platform linux/${ARCHITECTURE} \
		--image-name "${IMAGE_NAME}"

generate-language-version-files:
	./scripts/generate_language_version_files.sh

scan-base-image:
	trivy image \
		--severity HIGH,CRITICAL \
		--ignorefile .trivyignore.yaml \
		--scanners vuln \
		--exit-code 1 \
		--format table ${IMAGE_NAME} 

lint: lint-githubactions

test:
	echo "Not implemented"

lint-githubactions:
	actionlint
