# dockerfile-claude

A ready-to-use Docker image for running [Claude Code](https://www.anthropic.com/claude-code) with a batteries-included development toolchain.

Images are built for `linux/amd64` and `linux/arm64/v8`, and published to GitHub Container Registry as [`ghcr.io/jjeffcaii/claude`](https://github.com/jjeffcaii/dockerfile-claude/pkgs/container/claude).

## What's inside

Based on `ubuntu:jammy`, with:

- **Claude Code** (installed globally via Bun, set as the entrypoint)
- **Go** 1.24 + golangci-lint, gopls, staticcheck, gofumpt
- **Rust** (rustup)
- **Node.js** (latest LTS) + **Bun**, managed by Volta
- **Java** (OpenJDK 17) + Maven
- **Python 3** + pip, venv, uv
- Common CLI tools: git, curl, wget, jq, ripgrep, fzf, vim, imagemagick, etc.

## Usage

Run Claude Code in your project directory:

```bash
docker run -it --rm \
  -v ~/.claude:/root/.claude \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/jjeffcaii/claude
```

- `-v ~/.claude:/root/.claude` persists Claude Code credentials and settings across runs.
- Mount `~/.m2` as well (`-v ~/.m2:/root/.m2`) to reuse your local Maven repository for Java projects.

Arguments after the image name are passed straight to the `claude` CLI:

```bash
docker run -it --rm \
  -v ~/.claude:/root/.claude \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/jjeffcaii/claude --help
```

## Build locally

```bash
docker build -t claude .
```

## License

See [LICENSE](LICENSE).
