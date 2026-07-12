FROM ubuntu:jammy

ARG GO_VERSION=1.24.4

RUN apt-get update -y && \
    apt-get install -y curl wget git unzip zip ca-certificates build-essential dnsutils telnet vim ripgrep fzf netcat-openbsd jq \
        openjdk-17-jdk maven \
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
RUN bun i -g @anthropic-ai/claude-code

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

VOLUME /root/.m2
VOLUME /root/.claude
VOLUME /tmp

WORKDIR /root

ENTRYPOINT [ "claude" ]
