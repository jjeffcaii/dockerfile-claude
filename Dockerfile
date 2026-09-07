FROM ubuntu:jammy

ARG GO_VERSION=1.26.5
ARG CLAUDE_CODE_VERSION=2.1.261

RUN apt-get update -y && \
    apt-get install -y curl wget git unzip zip ca-certificates build-essential dnsutils telnet vim ripgrep fzf netcat-openbsd jq \
        openjdk-8-jdk openjdk-11-jdk openjdk-17-jdk openjdk-21-jdk maven \
        imagemagick \
        python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

# Go (official tarball; apt version is too old)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | tar -C /usr/local -xz

# Rust (rustup)
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Volta (Node.js latest LTS + Bun)
ENV VOLTA_HOME=/root/.volta
RUN curl -fsSL https://get.volta.sh | bash -s -- --skip-setup && \
    "${VOLTA_HOME}/bin/volta" install node bun

ENV PATH="/usr/local/go/bin:/root/.cargo/bin:${VOLTA_HOME}/bin:/root/.bun/bin:${PATH}"

# Go ecosystem tools (golangci-lint, gopls, staticcheck, gofumpt)
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b /usr/local/bin && \
    GOBIN=/usr/local/bin go install golang.org/x/tools/gopls@latest && \
    GOBIN=/usr/local/bin go install honnef.co/go/tools/cmd/staticcheck@latest && \
    GOBIN=/usr/local/bin go install mvdan.cc/gofumpt@latest && \
    go clean -cache -modcache

# Claude
RUN bun i -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Docker CLI (client only; talks to a mounted /var/run/docker.sock)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update -y && \
    apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# jenv (manage the openjdk 8/11/17/21 installed above)
ENV JENV_ROOT=/root/.jenv
ENV PATH="${JENV_ROOT}/shims:${JENV_ROOT}/bin:${PATH}"
RUN git clone --depth 1 https://github.com/jenv/jenv.git "${JENV_ROOT}" && \
    mkdir -p "${JENV_ROOT}/plugins" && \
    ln -s "${JENV_ROOT}/available-plugins/export" "${JENV_ROOT}/plugins/export" && \
    for v in 8 11 17 21; do jenv add "/usr/lib/jvm/java-${v}-openjdk-$(dpkg --print-architecture)"; done && \
    jenv global 17 && \
    jenv rehash && \
    jenv refresh-plugins && \
    echo 'eval "$(jenv init -)"' >> /root/.bashrc

VOLUME /root/.m2
VOLUME /root/.claude
VOLUME /tmp

WORKDIR /root

ENTRYPOINT [ "claude" ]
