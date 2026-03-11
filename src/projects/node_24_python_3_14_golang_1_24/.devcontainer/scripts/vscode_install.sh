#!/usr/bin/env bash
set -e

asdf plugin add golang
asdf plugin add golangci-lint

asdf install

# install cfn-lint
pip install --user cfn-lint
