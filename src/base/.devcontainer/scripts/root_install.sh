#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Add amd64 architecture if on arm64
if [ "$TARGETARCH" == "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then 
    echo "Adding amd64 architecture support"
    dpkg --add-architecture amd64

    # Update sources.list to include amd64 repositories
    echo "Configuring sources.list for amd64 and arm64"
    sed -i.bak '/^deb / s|http://ports.ubuntu.com/ubuntu-ports|[arch=arm64] http://ports.ubuntu.com/ubuntu-ports|' /etc/apt/sources.list
    # shellcheck disable=SC2129
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main universe" >> /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-updates main universe" >> /etc/apt/sources.list
    echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-security main universe" >> /etc/apt/sources.list
fi

# update and upgrade packages
echo "Running apt-get update"
apt-get update
apt-get upgrade -y

# install necessary libraries for asdf and language runtimes
echo "Installing necessary packages"
apt-get -y install --no-install-recommends htop vim curl git build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev libbz2-dev \
    zlib1g-dev unixodbc unixodbc-dev libsecret-1-0 libsecret-1-dev libsqlite3-dev \
    jq apt-transport-https ca-certificates gnupg-agent \
    software-properties-common bash-completion make libbz2-dev \
    libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev liblzma-dev netcat-traditional libyaml-dev uuid-runtime xxd unzip

# Download correct SAM CLI for arch
echo "Installing aws-sam cli"
if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then
      wget -O /tmp/aws-sam-cli.zip --no-verbose "https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-arm64.zip"
    else
      wget -O /tmp/aws-sam-cli.zip --no-verbose "https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip"
    fi
    unzip -q /tmp/aws-sam-cli.zip -d /tmp/aws-sam-cli
    /tmp/aws-sam-cli/install
    rm /tmp/aws-sam-cli.zip
    rm -rf /tmp/aws-sam-cli

# Install ASDF
echo "Installing asdf"
ASDF_VERSION=$(awk '!/^#/ && NF {print $1; exit}' "${SCRIPTS_DIR}/${CONTAINER_NAME}/.tool-versions.asdf")
if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
    wget -O /tmp/asdf.tar.gz --no-verbose "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-arm64.tar.gz"
else
    wget -O /tmp/asdf.tar.gz --no-verbose "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-amd64.tar.gz"
fi
tar -xzf /tmp/asdf.tar.gz -C /tmp
mkdir -p /usr/bin
mv /tmp/asdf /usr/bin/asdf
chmod +x /usr/bin/asdf
rm -rf /tmp/asdf.tar.gz 

# install gitsecrets
git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets
cd /tmp/git-secrets
make install
cd
rm -rf /tmp/git-secrets
mkdir -p /usr/share/secrets-scanner
chmod 755 /usr/share/secrets-scanner
curl -L https://raw.githubusercontent.com/NHSDigital/software-engineering-quality-framework/main/tools/nhsd-git-secrets/nhsd-rules-deny.txt -o /usr/share/secrets-scanner/nhsd-rules-deny.txt

# fix user and group ids for vscode user to be 1001 so it can be used by github actions
requested_uid=1001
requested_gid=1001
current_uid="$(id -u vscode)"
current_gid="$(id -g vscode)"
if [ "${current_gid}" != "${requested_gid}" ]; then groupmod -g "${requested_gid}" vscode; fi
if [ "${current_uid}" != "${requested_uid}" ]; then usermod -u "${requested_uid}" -g "${requested_gid}" vscode; fi
chown -R vscode:vscode /home/vscode
