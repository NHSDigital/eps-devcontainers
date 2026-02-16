#!/usr/bin/env bash

set -e

# shellcheck disable=SC2129
# shellcheck disable=SC2016
echo 'PATH="/home/vscode/.asdf/shims/:$PATH"' >> ~/.bashrc
echo '. <(asdf completion bash)' >> ~/.bashrc
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
# shellcheck disable=SC2016
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
# shellcheck disable=SC2016
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc

# Install ASDF plugins
asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git
asdf plugin add direnv
asdf plugin add actionlint
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git
asdf plugin add trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git
asdf plugin add yq https://github.com/sudermanjr/asdf-yq.git

# install base asdf versions of common tools
cd /home/vscode
asdf install
