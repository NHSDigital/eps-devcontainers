#!/usr/bin/env bash
set -e

asdf plugin add java
asdf plugin add maven

asdf install

# install cfn-lint
pip install --user cfn-lint
