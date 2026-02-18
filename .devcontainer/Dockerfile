FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}

# Install essential packages first
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy ASDF version file
ARG ASDF_VERSION
COPY .tool-versions.asdf /tmp/.tool-versions.asdf

# Add amd64 architecture if on arm64
RUN if [ "$TARGETARCH" == "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then dpkg --add-architecture amd64; fi

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y dist-upgrade \
    && apt-get -y install --no-install-recommends htop vim curl git build-essential \
    libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg8-dev libbz2-dev \
    zlib1g-dev unixodbc unixodbc-dev libsecret-1-0 libsecret-1-dev libsqlite3-dev \
    jq apt-transport-https ca-certificates gnupg-agent \
    software-properties-common bash-completion python3-pip make libbz2-dev \
    libreadline-dev libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev liblzma-dev netcat-traditional libyaml-dev uuid-runtime xxd unzip

# install aws stuff
# Download correct AWS CLI for arch
RUN if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then \
      wget -O /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"; \
    else \
      wget -O /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; \
    fi && \
    unzip /tmp/awscliv2.zip -d /tmp/aws-cli && \
    /tmp/aws-cli/aws/install && \
    rm /tmp/awscliv2.zip && rm -rf /tmp/aws-cli

# Install ASDF
RUN ASDF_VERSION=$(awk '!/^#/ && NF {print $1; exit}' /tmp/.tool-versions.asdf) && \
    if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" == "aarch64" ]; then \
      wget -O /tmp/asdf.tar.gz "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-arm64.tar.gz"; \
    else \
      wget -O /tmp/asdf.tar.gz "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-amd64.tar.gz"; \
    fi && \
    tar -xzf /tmp/asdf.tar.gz -C /tmp && \
    mkdir -p /usr/bin && \
    mv /tmp/asdf /usr/bin/asdf && \
    chmod +x /usr/bin/asdf && \
    rm -rf /tmp/asdf.tar.gz 

# install gitsecrets
RUN git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets && \
    cd /tmp/git-secrets && \
    make install && \
    cd && \
    rm -rf /tmp/git-secrets && \
    mkdir -p /usr/share/secrets-scanner && \
    chmod 755 /usr/share/secrets-scanner && \
    curl -L https://raw.githubusercontent.com/NHSDigital/software-engineering-quality-framework/main/tools/nhsd-git-secrets/nhsd-rules-deny.txt -o /usr/share/secrets-scanner/nhsd-rules-deny.txt

USER vscode

ENV PATH="/home/vscode/.asdf/shims/:$PATH:/workspaces/eps-devcontainers/node_modules/.bin"
RUN \
    echo 'PATH="/home/vscode/.asdf/shims/:$PATH:/workspaces/eps-devcontainers/node_modules/.bin"' >> ~/.bashrc; \
    echo '. <(asdf completion bash)' >> ~/.bashrc; \
    echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc; \
    echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc; \
    echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc;

# Install ASDF plugins
RUN asdf plugin add python; \
    asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git; \
    asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git; \
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git; \
    asdf plugin add direnv; \
    asdf plugin add actionlint; \
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git; \
    asdf plugin add trivy https://github.com/zufardhiyaulhaq/asdf-trivy.git; \
    asdf plugin add yq https://github.com/sudermanjr/asdf-yq.git


WORKDIR /workspaces/eps-devcontainers
COPY .tool-versions /workspaces/eps-devcontainers/.tool-versions
COPY .tool-versions /home/vscode/.tool-versions

# install python before poetry to ensure correct python version is used
RUN asdf install python; \
    asdf install

RUN git-secrets --register-aws --global && \
  git-secrets --add-provider --global -- cat /usr/share/secrets-scanner/nhsd-rules-deny.txt
