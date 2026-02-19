EPS DEV CONTAINERS
==================

## Index
- [Introduction](#introduction)
- [Using the images](#using-the-images)
  - [Project setup](#project-setup)
  - [Getting image name and version in GitHub Actions](#getting-image-name-and-version-in-github-actions)
  - [Using images in GitHub Actions](#using-images-in-github-actions)
  - [Using local or pull request images in Visual Studio Code](#using-local-or-pull-request-images-in-visual-studio-code)
- [Project structure](#project-structure)
- [Pull requests and merge to main process](#pull-requests-and-merge-to-main-process)
- [Release workflow](#release-workflow)
- [Local testing](#local-testing)
  - [Building images](#building-images)
  - [Scanning images](#scanning-images)
  - [Interactive shell on image](#interactive-shell-on-image)
  - [Generating a .trivyignore file](#generating-a-trivyignore-file)
  - [Cleaning up unused container images](#cleaning-up-unused-container-images)
  - [Common Makefile targets](#common-makefile-targets)
    - [Targets](#targets)

# Introduction
This repository contains code to build VS Code devcontainers that can be used as a base image for all EPS projects.   
Images are built for AMD64 and ARM64, and a manifest file is created that can be pulled for both architectures. This is then pushed to GitHub Container Registry.    
Images are built using https://github.com/devcontainers/cli.   

We build a base image based on mcr.microsoft.com/devcontainers/base:ubuntu-22.04 that other images are then based on

The base image contains
 - latest os packages
 - asdf
 - aws cli
 - aws sam cli

 It installs the following dev container features
 - docker outside of docker
 - GitHub CLI

As the vscode user the following also happens

asdf install and setup for these so they are available globally as vscode user
 - shellcheck
 - direnv
 - actionlint
 - ruby (for GitHub Pages)
 - Trivy
 - yq

Install and setup git-secrets

# Using the images
## Project setup
In each EPS project, `.devcontainer/Dockerfile` should be set to
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
`.devcontainer/devcontainer.json` should be set to:   
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
Note - this file will be used in GitHub workflows to calculate the version of container to use in builds, so it must be valid JSON (no comments).   
The name should be changed to match the name of the project.   
IMAGE_NAME and IMAGE_VERSION should be changed as appropriate.   
You should not need to add any features as these are already baked into the image

## Getting image name and version in GitHub Actions
This job should be used in GitHub Actions wherever you need to get the dev container name or tag

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
## Using images in GitHub Actions
To use the image in GitHub Actions, you should first verify the attestation of the image and reference the image by the digest
For CI and release pipelines, you should set verify_published_from_main_image to ensure that only images published from main are used.   
```
jobs:
  verify_attestation:
    uses: NHSDigital/eps-common-workflows/.github/workflows/verify-attestation.yml@<latest published version>
    with:
      runtime_docker_image: "${{ inputs.runtime_docker_image }}"
      verify_published_from_main_image: false
  my_job_name:
    runs-on: ubuntu-22.04
    needs: verify_attestation
    container:
      image: ${{ needs.verify_attestation.outputs.pinned_image }}
      options: --user 1001:1001 --group-add 128
    defaults:
      run:
        shell: bash
    steps:
      - name: copy .tool-versions
        run: |
          cp /home/vscode/.tool-versions "$HOME/.tool-versions"
      ... other steps ....
```
It is important that:
- the image specified uses the tag starting githubactions-
- there is `options: --user 1001:1001 --group-add 128` below image to ensure it uses the correct user id and is added to the docker group
- the default shell is set to be bash
- the first step copies .tool-versions from /home/vscode to $HOME/.tool-versions
## Using local or pull request images in Visual Studio Code
You can use local or pull request images by changing IMAGE_VERSION in devcontainer.json.    
For an image built locally following instructions below, you should put the IMAGE_VERSION=local-build. 
For an image built from a pull request, you should put the IMAGE_VERSION=<tag of image as shown in pull request job>.  
You can only use images built from a pull request for testing changes in GitHub Actions.   

# Project structure
We have 5 types of dev container. These are defined under src

`base` - this is the base image that all others are based on.   
`base_node` - images that install node - most language projects rely on one of these
`languages` - this installs specific versions of python - normally based off a node image   
`projects` - this is used for projects where more customization is needed than just a base language image.   
`githubactions` - this just takes an existing image and remaps vscode user to be 1001 so it can be used by GitHub Actions.   

Each image to be built contains a .devcontainer folder that defines how the devcontainer should be built. At a minimum, this should contain a devcontainer.json file. See https://containers.dev/implementors/json_reference/ for options for this

Images under languages should point to a Dockerfile under src/common or src/common_node_24 that is based off the base or node image. This also runs `.devcontainer/scripts/root_install.sh` and `.devcontainer/scripts/vscode_install.sh` as vscode user as part of the build. These files should be in the language specific folder.

We use Trivy to scan for vulnerabilities in the built Docker images. Known vulnerabilities in the base image are in `src/common/.trivyignore.yaml`. Vulnerabilities in specific images are in `.trivyignore.yaml` files in each image folder. These are combined before running a scan to exclude all known vulnerabilities

# Pull requests and merge to main process
For each pull request, and merge to main, images are built and scanned using Trivy, and pushed to GitHub Container Registry.      
Docker images are built for AMD64 and ARM64 architecture, and a combined manifest is created and pushed as part of the build.
The main images have a vscode user with ID 1000. A separately tagged image is also created with the vscode user mapped to user ID 1001 so it can be used by GitHub Actions.

The base image is built first, and then language images, and finally project images. 

Docker images are scanned for vulnerabilities using Trivy as part of a build step, and the build fails if vulnerabilities are found that are not in the .trivyignore file.

For pull requests, images are tagged with the pr-{pull request id}-{short commit sha}.   
For merges to main, images are tagged with the ci-{short commit sha}.   
GitHub Actions images are tagged with githubactions-{full tag}
AMD64 images are tagged with {tag}-amd64
ARM64 images are tagged with {tag}-arm64
The combined image manifest is tagged with {tag}, so it can be included in devcontainer.json and the correct image is pulled based on the host architecture.   

When a pull request is merged to main or closed, all associated images are deleted from the registry using the GitHub workflow delete_old_images

# Release workflow
There is a release workflow that runs weekly at 18:00 on Thursday and on demand.   
This creates a new release tag, builds all images, and pushes them to GitHub Container Registry.
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
Base node 24 image
```
CONTAINER_NAME=node_24 \
  BASE_VERSION_TAG=local-build \
  BASE_FOLDER=base_node \
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
GitHub Actions image
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
Base node 24 image
```
CONTAINER_NAME=node_24 \
  BASE_FOLDER=base_node \
  IMAGE_TAG=local-build \
  EXTRA_COMMON=common_node_24 \
  make scan-image
```
Language images
```
CONTAINER_NAME=node_24_python_3_14 \
  BASE_FOLDER=languages \
  IMAGE_TAG=local-build \
  EXTRA_COMMON=common_node_24 \
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
You can use this to start an interactive shell in built images
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
GitHub Actions image
```
CONTAINER_NAME=base \
  IMAGE_TAG=githubactions-local-build \
  make shell-image
```

## Generating a .trivyignore file
You can generate a .trivyignore file for known vulnerabilities by either downloading the JSON scan output generated by the build, or by generating it locally using the scanning images commands above with a make target of scan-image-json

If generated locally, then the output goes into .out/scan_results_docker.json.   
You can use GitHub CLI tools to download the scan output file. Replace the run ID from the URL, and the -n with the filename to download
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

## Cleaning up unused container images

There is a script to delete unused container images. This runs on every merge to main and deletes pull request images, and on a weekly schedule it deletes images created by CI.   
You can run it manually using the following. Using the `dry-run` flag just shows what would be deleted

```
make github-login
# or gh auth login --scopes read:packages,delete:packages if you want to be able to delete images
bash .github/scripts/delete_unused_images.sh --delete-pr --dry-run
bash .github/scripts/delete_unused_images.sh --delete-ci --dry-run
bash .github/scripts/delete_unused_images.sh --delete-pr --delete-ci
```

Flags:
- `--dry-run` (`-n`) shows what would be deleted without deleting anything.
- `--delete-pr` deletes images tagged with `pr-...` or `githubactions-pr-...` only when the PR is closed.
- `--delete-ci` deletes images tagged with `ci-<8 hex sha>...` or `githubactions-ci-<8 hex sha>...`.

If neither `--delete-pr` nor `--delete-ci` is set, the script defaults to `--delete-pr`.

## Common Makefile targets
There is a set of common Makefiles that are defined in `src/base/.devcontainer/Mk` and are included from `common.mk`. These are installed to /usr/local/share/eps/Mk on the base image, so they are available for all containers.

This should be added to the end of each project's Makefile to include them
```
%:
	@$(MAKE) -f /usr/local/share/eps/Mk/common.mk $@
```
### Targets
The following targets are defined. These are needed for quality checks to run. Some targets are project-specific and should be overridden in the project's Makefile.

Build targets (`build.mk`)
- `install` - placeholder target - should be overridden locally
- `install-node` - placeholder target - should be overridden locally
- `docker-build` - placeholder target - should be overridden locally
- `compile` - placeholder target - should be overridden locally

Check targets (`check.mk`)
- `lint` - placeholder target - should be overridden locally
- `test` - placeholder target - should be overridden locally
- `shellcheck` - runs shellcheck on `scripts/*.sh` and `.github/scripts/*.sh` when files exist
- `cfn-lint` - runs `cfn-lint` against `cloudformation/**/*.yml|yaml` and `SAMtemplates/**/*.yml|yaml`
- `cdk-synth` - placeholder target - should be overridden locally
- `cfn-guard-sam-templates` - validates SAM templates against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `cfn-guard-cloudformation` - validates `cloudformation` templates against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `cfn-guard-cdk` - validates `cdk.out` against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `cfn-guard-terraform` - validates `terraform_plans` against cfn-guard rulesets and writes outputs to `.cfn_guard_out/`
- `actionlint` - runs actionlint against GitHub Actions
- `secret-scan` - runs git-secrets (including scanning history) against the repository
- `guard-<ENVIRONMENT_VARIABLE>` - checks if an environment variable is set and errors if it is not

Credentials targets (`credentials.mk`)
- `aws-configure` - configures an AWS SSO session
- `aws-login` - Authorizes an SSO session with AWS so AWS CLI tools can be used. You may still need to set AWS_PROFILE before running commands
- `github-login` - Authorizes GitHub CLI to GitHub with scope to read packages
- `create-npmrc` - depends on `github-login`, then writes `.npmrc` with a GitHub Packages auth token and `@nhsdigital` registry

Trivy targets (`trivy.mk`)
- `trivy-license-check` - runs Trivy license scan (HIGH/CRITICAL) and writes `.trivy_out/license_scan.txt`
- `trivy-generate-sbom` - generates CycloneDX SBOM at `.trivy_out/sbom.cdx.json`
- `trivy-scan-python` - scans Python dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_python.txt`
- `trivy-scan-node` - scans Node dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_node.txt`
- `trivy-scan-go` - scans Go dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_go.txt`
- `trivy-scan-java` - scans Java dependencies (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_java.txt`
- `trivy-scan-docker` - scans a built image (HIGH/CRITICAL) and writes `.trivy_out/dependency_results_docker.txt` (requires `DOCKER_IMAGE`), for example:
