.PHONY: trivy-license-check trivy-generate-sbom trivy-scan-python trivy-scan-node trivy-scan-go trivy-scan-java

trivy-license-check:
	mkdir -p .trivy_out/
	@if [ -f poetry.lock ]; then \
		poetry self add poetry-plugin-export; \
		poetry export -f requirements.txt --with dev --without-hashes --output=requirements.txt; \
	fi
	@if [ -f src/go.sum ]; then \
		cd src && go mod vendor; \
	fi
	VIRTUAL_ENV=./.venv/ trivy fs . \
		--scanners license \
		--severity HIGH,CRITICAL \
		--config trivy.yaml \
		--include-dev-deps \
		--pkg-types library \
		--exit-code 1 \
		--output .trivy_out/license_scan.txt \
		--format table
	@if [ -f poetry.lock ]; then rm -f requirements.txt; fi
	@if [ -f src/go.sum ]; then rm -rf src/vendor; fi

trivy-generate-sbom:
	mkdir -p .trivy_out/
	trivy fs . \
		--scanners vuln \
		--config trivy.yaml \
		--include-dev-deps \
		--exit-code 0 \
		--output .trivy_out/sbom.cdx.json \
		--format cyclonedx

trivy-scan-python:
	mkdir -p .trivy_out/
	trivy fs . \
		--scanners vuln \
		--severity HIGH,CRITICAL \
		--config trivy.yaml \
		--include-dev-deps \
		--exit-code 1 \
		--skip-files "**/package-lock.json,**/go.mod,**/pom.xml" \
		--output .trivy_out/dependency_results_python.txt \
		--format table

trivy-scan-node:
	mkdir -p .trivy_out/
	trivy fs . \
		--scanners vuln \
		--severity HIGH,CRITICAL \
		--config trivy.yaml \
		--include-dev-deps \
		--exit-code 1 \
		--skip-files "**/poetry.lock,**/go.mod,**/pom.xml" \
		--output .trivy_out/dependency_results_node.txt \
		--format table

trivy-scan-go:
	mkdir -p .trivy_out/
	trivy fs . \
		--scanners vuln \
		--severity HIGH,CRITICAL \
		--config trivy.yaml \
		--include-dev-deps \
		--exit-code 1 \
		--skip-files "**/poetry.lock,**/package-lock.json,**/pom.xml" \
		--output .trivy_out/dependency_results_go.txt \
		--format table

trivy-scan-java:
	mkdir -p .trivy_out/
	trivy fs . \
		--scanners vuln \
		--severity HIGH,CRITICAL \
		--config trivy.yaml \
		--include-dev-deps \
		--exit-code 1 \
		--skip-files "**/poetry.lock,**/package-lock.json,**/go.mod" \
		--output .trivy_out/dependency_results_java.txt \
		--format table

trivy-scan-docker: guard-DOCKER_IMAGE
	mkdir -p .trivy_out/
	trivy image $${DOCKER_IMAGE} \
		--scanners vuln \
		--severity HIGH,CRITICAL \
		--config trivy.yaml \
		--include-dev-deps \
		--exit-code 1 \
		--pkg-types os,library \
		--output .trivy_out/dependency_results_docker.txt \
		--format table
