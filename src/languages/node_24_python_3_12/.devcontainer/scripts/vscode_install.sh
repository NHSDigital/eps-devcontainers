#!/usr/bin/env bash
set -e

asdf plugin add python
asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

asdf install python
asdf install
