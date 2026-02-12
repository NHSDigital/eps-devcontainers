CONTAINER_PREFIX=ghcr.io/nhsdigital/eps-devcontainers/

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

install: install-python install-node install-hooks

install-python:
	poetry install

install-node:
	npm install

install-hooks: install-python
	poetry run pre-commit install --install-hooks --overwrite

build-image: guard-CONTAINER_NAME guard-BASE_VERSION
	npx devcontainer build \
		--workspace-folder ./src/$${CONTAINER_NAME}/ \
		--push false \
		--image-name "${CONTAINER_PREFIX}$${CONTAINER_NAME}" 

scan-image: guard-CONTAINER_NAME
	trivy image \
		--severity HIGH,CRITICAL \
		--ignorefile .trivyignore.yaml \
		--scanners vuln \
		--exit-code 1 \
		--format table "${CONTAINER_PREFIX}/$${CONTAINER_NAME}" 

lint: lint-githubactions

test:
	echo "Not implemented"

lint-githubactions:
	actionlint
