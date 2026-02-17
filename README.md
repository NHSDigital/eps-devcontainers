EPS DEV CONTAINERS
==================

# Introduction
This repo contains code to build a vscode devcontainers that can be used as a base image for all EPS projects.   
Images are build for amd64 and arm64 and a manifest file created that can be pulled for both architectures. This is then pushed to github container registry.    
Images are built using using https://github.com/devcontainers/cli.   

We build a base image based on mcr.microsoft.com/devcontainers/base:ubuntu-22.04 that other images are then based on

The base image contains
 - latest os packages
 - asdf
 - aws cli
 - aws sam cli

 It installs the following dev container features
 - docker outside of docker
 - github cli

As the vscode user the following also happens

asdf install and setup for these so they are available globally as vscode user
 - shellcheck
 - direnv
 - actionlint
 - ruby (for github pages)
 - trivy
 - yq

Install and setup git-secrets

# Using the images
In each eps project, this should be the contents of .devcontainer/Dockerfile.

```
ARG IMAGE_NAME=node_24_python_3_14
ARG IMAGE_VERSION=latest
FROM ghcr.io/nhsdigital/eps-devcontainers/${IMAGE_NAME}:${IMAGE_VERSION}

USER root
# specify DOCKER_GID to force container docker group id to match host
RUN if [ -n "${DOCKER_GID}" ]; then \
    if ! getent group docker; then \
    groupadd -g ${DOCKER_GID} docker; \
    else \
    groupmod -g ${DOCKER_GID} docker; \
    fi && \
    usermod -aG docker vscode; \
    fi
```
And this should be the contents of .devcontainer/devcontainer.json.   
This file will be used in github workflows to calculate the version of container to use in builds, so it must be valid JSON (no comments).   
The name should be changed to match the name of the project.   
IMAGE_NAME and IMAGE_VERSION should be changed as appropriate.   
You should not need to add any features as these are already baked into the image
```
{
  "name": "eps-common-workflows",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "..",
    "args": {
      "DOCKER_GID": "${env:DOCKER_GID:}",
      "IMAGE_NAME": "node_24_python_3_14",
      "IMAGE_VERSION": "local-build",
      "USER_UID": "${localEnv:USER_ID:}",
      "USER_GID": "${localEnv:GROUP_ID:}"
    },
    "updateRemoteUserUID": false,
  },
  "postAttachCommand": "git-secrets --register-aws; git-secrets --add-provider -- cat /usr/share/secrets-scanner/nhsd-rules-deny.txt",
  "mounts": [
    "source=${env:HOME}${env:USERPROFILE}/.aws,target=/home/vscode/.aws,type=bind",
    "source=${env:HOME}${env:USERPROFILE}/.ssh,target=/home/vscode/.ssh,type=bind",
    "source=${env:HOME}${env:USERPROFILE}/.gnupg,target=/home/vscode/.gnupg,type=bind",
    "source=${env:HOME}${env:USERPROFILE}/.npmrc,target=/home/vscode/.npmrc,type=bind"
  ],
  "containerUser": "vscode",
  "remoteEnv": {
    "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}"
  },
  "features": {},
  "customizations": {
    ....
  }
}
```

This job should be used in github actions wherever you need to get the dev container name or tag

```
  get_config_values:
    runs-on: ubuntu-22.04
    outputs:
      devcontainer_image_name: ${{ steps.load-config.outputs.DEVCONTAINER_IMAGE_NAME }}
      devcontainer_image_version: ${{ steps.load-config.outputs.DEVCONTAINER_VERSION }}
    steps:
      - name: Checkout code
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd
      - name: Load config value
        id: load-config
        run: |
          DEVCONTAINER_IMAGE_NAME=$(jq -r '.build.args.IMAGE_NAME' .devcontainer/devcontainer.json)
          DEVCONTAINER_IMAGE_VERSION=$(jq -r '.build.args.IMAGE_VERSION' .devcontainer/devcontainer.json)
          echo "DEVCONTAINER_IMAGE_NAME=$DEVCONTAINER_IMAGE_NAME" >> "$GITHUB_OUTPUT"
          echo "DEVCONTAINER_IMAGE_VERSION=$DEVCONTAINER_VERSION" >> "$GITHUB_OUTPUT"
```
# Project structure
We have 4 types of dev container. These are defined under src

`base` - this is the base image that all others are based on.   
`languages` - this installs specific versions of node and python.   
`projects` - this is used for projects where more customization is needed than just a base language image.   
`githubactions` - this just takes an existing image and remaps vscode user to be 1001 so it can be used by github actions.   

Each image to be built contains a .devcontainer folder that defines how the devcontainer should be built. At a minimum, this should contain a devcontainer.json file. See https://containers.dev/implementors/json_reference/ for options for this

Images under languages should point to a dockerfile under src/common that is based off the base image. This also runs `.devcontainer/scripts/root_install.sh` and `.devcontainer/scripts/vscode_install.sh` as vscode user as part of the build. These files should be in the language specific folder.

We use trivy to scan for vulnerabilities in the built docker images. Known vulnerabilities in the base image are in `src/common/.trivyignore.yaml`. Vulnerabilities in specific images are in `.trivyignore.yaml` file in each images folder. These are combined before running a scan to exclude all known vulnerabilities

# Pull requests and merge to main process
For each pull request, and merge to main, images are built and scanned using trivy, but the images are not pushed to github container registry
Docker images are built for each pull request, and on merges to main.   
Docker images are built for amd64 and arm64 architecture, and a combined manifest is created and pushed as part of the build.   
Images are also created with user vscode mapped to user id 1001 so they can be used by github actions.

The base image is built first, and then language images, and finally project images. 

Docker images are scanned for vulnerabilities using trivy as part of a build step, and the build fails if vulnerabilities are found not in .trivyignore file.

For pull requests, images are tagged with the pr-<pull request id>-<short commit sha>.   
For merges to main, images are tagged with the <short commit sha>.   
Github actions images are tagged with githubactions-<tag>

When a pull request is merged to main or closed, all associated images are deleted from the registry using the github workflow delete_old_images

# Release workflow
There is a release workflow that runs weekly at 18:00 on Thursday and on demand.   
This creates a new release tag, builds all images, and pushes them to github container registry.
Images are tagged with the release tag, and also with latest

# Local testing
## Building images
You can use these commands to build images

Base image
```
CONTAINER_NAME=base \
  BASE_VERSION_TAG=latest \
  BASE_FOLDER=. \
  IMAGE_TAG=local-build \
  make build-image
``` 
Language images
```
CONTAINER_NAME=node_24_python_3_14 \
  BASE_VERSION_TAG=local-build \
  BASE_FOLDER=languages \
  IMAGE_TAG=local-build \
  make build-image
``` 
Project images
```
CONTAINER_NAME=fhir_facade_api \
  BASE_VERSION_TAG=local-build \
  BASE_FOLDER=projects \
  IMAGE_TAG=local-build \
  make build-image
``` 
Github actions image
```
BASE_IMAGE_NAME=base \
  BASE_IMAGE_TAG=local-build \
  IMAGE_TAG=local-build \
  make build-githubactions-image
```
## Scanning images
You can use these commands to scan images
Base image
```
CONTAINER_NAME=base \
  BASE_FOLDER=. \
  IMAGE_TAG=local-build \
  make scan-image
```
Language images
```
CONTAINER_NAME=node_24_python_3_12 \
  BASE_FOLDER=languages \
  IMAGE_TAG=local-build \
  make scan-image
``` 
Project images
```
CONTAINER_NAME=fhir_facade_api \
  BASE_FOLDER=projects \
  IMAGE_TAG=local-build \
  make scan-image
``` 

## Interactive shell on image
You can use this to start an interactive shell on built images
base image
```
CONTAINER_NAME=base \
  IMAGE_TAG=local-build \
  make shell-image
```
Language images
```
CONTAINER_NAME=node_24_python_3_12 \
  IMAGE_TAG=local-build \
  make shell-image
``` 
Project images
```
CONTAINER_NAME=fhir_facade_api \
  IMAGE_TAG=local-build \
  make shell-image
``` 

## Using local or pull request images
You can use local or pull request images by changing IMAGE_VERSION in devcontainer.json.    
For an image built locally, you should put the IMAGE_VERSION=local-build. 
For an image built from a pull request, you should put the IMAGE_VERSION=<tag of image as show in pull request job>.  
You can only use images built from a pull request for testing changes in github actions.   

## Generating a .trivyignore file
You can generate a .trivyignore file for known vulnerabilities by either downloading the json scan output generated by the build, or by generating it locally using the scanning images commands above with a make target of scan-image-json

If generated locally, then the output goes into .out/scan_results_docker.json.   
You can use github cli tools to download the scan output file. Replace the run id from the url, and the -n with the filename to download
```
gh run download <run id> -n scan_results_docker_fhir_facade_api_arm64.json 
```

Once you have the scan output, use the following to generate a new .trivyignore file called .trivyignore.new.yaml. Note this will overwrite the output file when run so it should point to a new file and the contents merged with existing .trivyignore file


```
poetry run python \
  scripts/trivy_to_trivyignore.py \
  --input .out/scan_results_docker.json \
  --output src/projects/fhir_facade_api/.trivyignore.new.yaml 
```

## Common makefile targets
The common makefiles are defined in `src/base/.devcontainer/makefiles` and are included from `common.mk`.

You should add this to the end of project Makefile to include them
```
%:
	@$(MAKE) -f /usr/local/share/eps/makefiles/common.mk $@
```

Build targets (`build.mk`)
- `install` - placeholder target (currently not implemented)
- `install-node` - placeholder target (currently not implemented)
- `docker-build` - placeholder target (currently not implemented)
- `compile` - placeholder target (currently not implemented)

Check targets (`check.mk`)
- `lint` - placeholder target (currently not implemented)
- `test` - placeholder target (currently not implemented)
- `shellcheck` - runs shellcheck on `scripts/*.sh` and `.github/scripts/*.sh` when files exist
- `cfn-lint` - runs `cfn-lint` against `cloudformation/**/*.yml|yaml` and `SAMtemplates/**/*.yml|yaml`
- `cdk-synth` - placeholder target (currently not implemented)
- `cfn-guard-sam-templates` - validates SAM templates against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `cfn-guard-cloudformation` - validates `cloudformation` templates against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `cfn-guard-cdk` - validates `cdk.out` against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `cfn-guard-terraform` - validates `terraform_plans` against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`

Trivy targets (`trivy.mk`)
- `trivy-license-check` - runs Trivy license scan (HIGH/CRITICAL) and writes `.trivy_out/license_scan.txt`
- `trivy-generate-sbom` - generates CycloneDX SBOM at `.trivy_out/sbom.cdx.json`
- `trivy-scan-python` - scans Python dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_python.txt`
- `trivy-scan-node` - scans Node dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_node.txt`
- `trivy-scan-go` - scans Go dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_go.txt`
- `trivy-scan-java` - scans Java dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_java.txt`
- `trivy-scan-docker` - scans a built image (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_docker.txt` (requires `DOCKER_IMAGE`), for example:
