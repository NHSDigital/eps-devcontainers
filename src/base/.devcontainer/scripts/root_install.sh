#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Install essential packages first
apt-get update
apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    unzip
apt-get clean
rm -rf /var/lib/apt/lists/*

# Add amd64 architecture if on arm64
if [ "$TARGETARCH" == "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then 
    echo "Adding amd64 architecture support"
    dpkg --add-architecture amd64
    echo "Running apt-get update for multi-arch"
    apt-get update
fi

# uninstall unnecessary packages
echo "Removing unnecessary packages"
apt-get remove -y \
    python3
# install necessary libraries for asdf and language runtimes
echo "Installing necessary packages"
apt-get -y install --no-install-recommends htop vim curl git build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev libbz2-dev \
    zlib1g-dev unixodbc unixodbc-dev libsecret-1-0 libsecret-1-dev libsqlite3-dev \
    jq apt-transport-https ca-certificates gnupg-agent \
    software-properties-common bash-completion make libbz2-dev \
    libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev liblzma-dev netcat-traditional libyaml-dev uuid-runtime xxd unzip

# install aws stuff
# Download correct AWS CLI for arch
if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
      wget -O /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else
      wget -O /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    fi
    unzip /tmp/awscliv2.zip -d /tmp/aws-cli
    /tmp/aws-cli/aws/install
    rm /tmp/awscliv2.zip
    rm -rf /tmp/aws-cli

# Download correct SAM CLI for arch
if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then
      wget -O /tmp/aws-sam-cli.zip "https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-arm64.zip"; \
    else
      wget -O /tmp/aws-sam-cli.zip "https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip"; \
    fi
    unzip /tmp/aws-sam-cli.zip -d /tmp/aws-sam-cli
    /tmp/aws-sam-cli/install
    rm /tmp/aws-sam-cli.zip
    rm -rf /tmp/aws-sam-cli

# Install ASDF
ASDF_VERSION=$(awk '!/^#/ && NF {print $1; exit}' /tmp/.tool-versions.asdf)
if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then
    wget -O /tmp/asdf.tar.gz "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-arm64.tar.gz"; \
else
    wget -O /tmp/asdf.tar.gz "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-amd64.tar.gz"; \
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
