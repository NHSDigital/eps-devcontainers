EPS DEV CONTAINERS
==================

# Introduction
This repo contains code to build a vscode devcontainers that can be used as a base image for all EPS projects.   
Images are build for amd64 and arm64 and a manifest file created that can be pulled for both architectures. This is then pushed to github container registry.    
Images are built using using https://github.com/devcontainers/cli.   

We build a base image based on mcr.microsoft.com/devcontainers/base:ubuntu-22.04 that other images are then based on

The images have vsocde user setup as user 1001 so that they can be used in github actions

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
    "args": {
      "DOCKER_GID": "${env:DOCKER_GID:}",
      "IMAGE_NAME": "node_24_python_3_14",
      "IMAGE_VERSION": "v1.0.1",
      "USER_UID": "${localEnv:USER_ID:}",
      "USER_GID": "${localEnv:GROUP_ID:}"
    },
    "updateRemoteUserUID": false,
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
      ... add any customisations you want here
    }
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
We have 3 types of dev container. These are defined under src

`base` - this is the base image that all others are based on.   
`languages` - this installs specific versions of node and python.   
`projects` - this is used for projects where more customization is needed than just a base language image

Each image to be built contains a .devcontainer folder that defines how the devcontainer should be built. At a minimum, this should contain a devcontainer.json file. See https://containers.dev/implementors/json_reference/ for options for this

Images under languages should point to a dockerfile under src/common that is based off the base image. This also runs `.devcontainer/scripts/root_install.sh` and `.devcontainer/scripts/vscode_install.sh` as vscode user as part of the build. These files should be in the language specific folder.

We use trivy to scan for vulnerabilities in the built docker images. Known vulnerabilities in the base image are in `src/common/.trivyignore.yaml`. Vulnerabilities in specific images are in `.trivyignore.yaml` file in each images folder. These are combined before running a scan to exclude all known vulnerabilities

# Pull requests and merge to main process
For each pull request, and merge to main, images are built and scanned using trivy, but the images are not pushed to github container registry
Docker images are built for each pull request, and on merges to main.   
Docker images are built for amd64 and arm64 architecture, and a combined manifest is created and pushed as part of the build.   

The base image is built first, and then language images, and finally project images. 

Docker images are scanned for vulnerabilities using trivy as part of a build step, and the build fails if vulnerabilities are found not in .trivyignore file.

For pull requests, images are tagged with the pr-<pull request id>-<short commit sha>.   
For merges to main, images are tagged with the <short commit sha>.   

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
CONTAINER_NAME=node_24_python_3_12 \
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
You can use local or pull request images by changing IMAGE_VERSION in devcontainer.json

## Generating a .trivyignore file
You can generate a .trivyignore file for known vulnerabilities by either downloading the json scan output generated by the build, or by generating it locally using the scanning images commands above with a make target of scan-image-json

If generated locally, then the output goes into .out/scan_results_docker.json

Once you have the scan output, use the following to generate a .trivyignore
```
poetry run python \
  scripts/trivy_to_trivyignore.py \
  --input .out/scan_results_docker.json \
  --output src/common/.trivyignore.yaml 
```
