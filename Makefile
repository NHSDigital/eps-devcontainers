CONTAINER_PREFIX=ghcr.io/nhsdigital/eps-devcontainers/

ifeq ($(strip $(NO_CACHE)),true)
NO_CACHE_FLAG=--no-cache
endif

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

build-image: guard-CONTAINER_NAME guard-BASE_VERSION_TAG guard-BASE_FOLDER guard-IMAGE_TAG
	npx devcontainer build \
		--workspace-folder ./src/$${BASE_FOLDER}/$${CONTAINER_NAME} \
		$(NO_CACHE_FLAG) \
		--push false \
		--output type=image,name="${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}",push=false,compression=zstd \
		--cache-from "${CONTAINER_PREFIX}$${CONTAINER_NAME}:latest" \
		--image-name "${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}"

build-githubactions-image: guard-BASE_IMAGE_NAME guard-BASE_IMAGE_TAG guard-IMAGE_TAG
	docker buildx build \
		-f src/githubactions/Dockerfile \
		$(NO_CACHE_FLAG) \
		--build-arg BASE_IMAGE_NAME="$${BASE_IMAGE_NAME}" \
		--build-arg BASE_IMAGE_TAG="$${BASE_IMAGE_TAG}" \
		--load \
		-t "${CONTAINER_PREFIX}$${BASE_IMAGE_NAME}:githubactions-$${IMAGE_TAG}" \
		.

scan-image: guard-CONTAINER_NAME guard-BASE_FOLDER
	@combined="src/$${BASE_FOLDER}/$${CONTAINER_NAME}/.trivyignore_combined.yaml"; \
	common="src/common/.trivyignore.yaml"; \
	specific="src/$${BASE_FOLDER}/$${CONTAINER_NAME}/.trivyignore.yaml"; \
	echo "vulnerabilities:" > "$$combined"; \
	if [ -f "$$common" ]; then sed -n '2,$$p' "$$common" >> "$$combined"; fi; \
	if [ -f "$$specific" ]; then sed -n '2,$$p' "$$specific" >> "$$combined"; fi
	trivy image \
		--severity HIGH,CRITICAL \
		--config src/${BASE_FOLDER}/${CONTAINER_NAME}/trivy.yaml \
		--scanners vuln \
		--exit-code 1 \
		--format table "${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}" 

scan-image-json: guard-CONTAINER_NAME guard-BASE_FOLDER guard-IMAGE_TAG
	@combined="src/$${BASE_FOLDER}/$${CONTAINER_NAME}/.trivyignore_combined.yaml"; \
	common="src/common/.trivyignore.yaml"; \
	specific="src/$${BASE_FOLDER}/$${CONTAINER_NAME}/.trivyignore.yaml"; \
	echo "vulnerabilities:" > "$$combined"; \
	if [ -f "$$common" ]; then sed -n '2,$$p' "$$common" >> "$$combined"; fi; \
	if [ -f "$$specific" ]; then sed -n '2,$$p' "$$specific" >> "$$combined"; fi
	mkdir -p .out
	trivy image \
		--severity HIGH,CRITICAL \
		--config src/${BASE_FOLDER}/${CONTAINER_NAME}/trivy.yaml \
		--scanners vuln \
		--exit-code 1 \
		--format json \
		--output .out/scan_results_docker.json "${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}" 

shell-image: guard-CONTAINER_NAME guard-IMAGE_TAG
	docker run -it \
	"${CONTAINER_PREFIX}$${CONTAINER_NAME}:$${IMAGE_TAG}"  \
	bash

lint: lint-githubactions

test:
	echo "Not implemented"

lint-githubactions:
	actionlint

github-login:
	gh auth login --scopes read:packages

lint-githubaction-scripts:
	shellcheck .github/scripts/*.sh
