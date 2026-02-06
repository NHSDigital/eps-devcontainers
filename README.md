EPS DEV CONTAINERS
==================

# Introduction
This repo contains code to build a vscode devcontainer that is used as a base image for all EPS projects.   
Images are build for amd64 and arm64 and a manifest file created that can be pulled for both architectures.   
Images are based on mcr.microsoft.com/devcontainers/base:ubuntu-22.04
Images contain
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

Install asdf plugins for all tools we use
Install asdf versions of node, python, java, terraform, golang used by all EPS projects to speed up initial build of local dev container
Install and setup git-secrets

# Project structure
The dev container is defined in src/base/.devcontainer folder. This folder contains a Dockerfile and a devcontainer.json file which is used to build the container

The dev container is built using https://github.com/devcontainers/cli

The script `scripts/generate_language_version_files.sh` gets the version of node, python, java and terraform from all EPS repositories. It uses the list of repos from https://github.com/NHSDigital/eps-repo-status/blob/main/repos.json to find all EPS repos.

# Build process
Docker images are built for each pull request, and on merges to main

Docker images are scanned for vulnerabilities using trivy as part of a build step, and the build fails if vulnerabilities are found not in .trivyignore file.
   
On merges to main, a new release is created and the images are pushed to github. The images are tagged with `latest` and the version of the release.

# Local testing
For local testing, you can run
```
ARCHITECTURE=amd64 make build-base-image
``` 
to build a local image, and then
```
make scan-base-image
```
to scan for vulnerabilities
