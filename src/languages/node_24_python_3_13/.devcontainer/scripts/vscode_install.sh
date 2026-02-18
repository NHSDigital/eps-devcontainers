#!/usr/bin/env bash
set -e

asdf plugin add python
asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git

asdf install python
asdf install

# install cfn-lint
pip install --user cfn-lint
