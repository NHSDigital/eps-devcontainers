CONTAINER_PREFIX=ghcr.io/nhsdigital/eps-devcontainers/

ifneq ($(strip $(PLATFORM)),)
PLATFORM_FLAG=--platform $(PLATFORM)
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

build-image: guard-CONTAINER_NAME guard-BASE_VERSION guard-PLATFORM
	npx devcontainer build \
		--workspace-folder ./src/$${CONTAINER_NAME}/ \
		--push false \
		--platform $${PLATFORM} \
		--image-name "${CONTAINER_PREFIX}$${CONTAINER_NAME}" 

scan-image: guard-CONTAINER_NAME
	@combined="src/$${CONTAINER_NAME}/.trivyignore_combined.yaml"; \
	common="src/common/.trivyignore.yaml"; \
	specific="src/$${CONTAINER_NAME}/.trivyignore.yaml"; \
	echo "vulnerabilities:" > "$$combined"; \
	if [ -f "$$common" ]; then sed -n '2,$$p' "$$common" >> "$$combined"; fi; \
	if [ -f "$$specific" ]; then sed -n '2,$$p' "$$specific" >> "$$combined"; fi
	trivy image \
		--severity HIGH,CRITICAL \
		--config src/${CONTAINER_NAME}/trivy.yaml \
		--scanners vuln \
		--exit-code 1 \
		--format table "${CONTAINER_PREFIX}$${CONTAINER_NAME}" 

scan-image-json: guard-CONTAINER_NAME
	@combined="src/$${CONTAINER_NAME}/.trivyignore_combined.yaml"; \
	common="src/common/.trivyignore.yaml"; \
	specific="src/$${CONTAINER_NAME}/.trivyignore.yaml"; \
	echo "vulnerabilities:" > "$$combined"; \
	if [ -f "$$common" ]; then sed -n '2,$$p' "$$common" >> "$$combined"; fi; \
	if [ -f "$$specific" ]; then sed -n '2,$$p' "$$specific" >> "$$combined"; fi
	mkdir -p .out
	trivy image \
		--severity HIGH,CRITICAL \
		--config src/${CONTAINER_NAME}/trivy.yaml \
		--scanners vuln \
		--exit-code 1 \
		--format json \
		--output .out/scan.out.json "${CONTAINER_PREFIX}$${CONTAINER_NAME}" 

shell-image: guard-CONTAINER_NAME
	docker run -it \
	"${CONTAINER_PREFIX}$${CONTAINER_NAME}"  \
	bash

lint: lint-githubactions

test:
	echo "Not implemented"

lint-githubactions:
	actionlint
