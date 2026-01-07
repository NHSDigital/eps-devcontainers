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
asdf plugin add python
asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git
asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin add direnv
asdf plugin add actionlint
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf plugin add java
asdf plugin add maven
asdf plugin add golang https://github.com/kennyp/asdf-golang.git
asdf plugin add golangci-lint https://github.com/hypnoglow/asdf-golangci-lint.git
asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git
asdf plugin add trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git

# install base asdf versions of common tools
cd /home/vscode
asdf install

# Read Node.js versions from file and install
while IFS= read -r version; do
    asdf install nodejs "$version"
done < /tmp/nodejs-versions.txt

# Read Python versions from file and install
while IFS= read -r version; do
    asdf install python "$version"
done < /tmp/python-versions.txt

# Read Java versions from file and install
while IFS= read -r version; do 
    asdf install java "$version"
done < /tmp/java-versions.txt

# Read Terraform versions from file and install
while IFS= read -r version; do
    asdf install terraform "$version"
done < /tmp/terraform-versions.txt

# Read Golang versions from file and install
while IFS= read -r version; do
    asdf install golang "$version"
done < /tmp/golang-versions.txt

# setup gitsecrets
git-secrets --register-aws --global
git-secrets --add-provider --global -- cat /usr/share/secrets-scanner/nhsd-rules-deny.txt
