# Surfbots Code Intelligence

Public release distribution for Surfbots Dev Platform: local semantic code intelligence, repository-scoped MCP tools, and persistent Development Memory for AI coding agents. This repository deliberately contains only the inspectable bootstrap entrypoint and release metadata. It is not a mirror of the private platform source.

## Install

Download the bootstrap, inspect it, then run a specific published release:

```bash
curl -fsSL https://raw.githubusercontent.com/franknaw/surfbots-code-intelligence/main/bootstrap.sh \
	-o /tmp/surfbots-bootstrap.sh
less /tmp/surfbots-bootstrap.sh
bash /tmp/surfbots-bootstrap.sh --version v0.2.0 --profile local-lightweight
```

The bootstrap downloads a pinned GitHub Release archive, verifies its mandatory SHA-256 checksum before extraction, installs into user-owned XDG paths, and starts the packaged local platform. It never clones private source.

## Local Profiles

`local-lightweight` is the default profile. It uses Qwen3 embedding at 1024 dimensions, BGE reranking, and Qwen2.5-Coder-1.5B Q4_K_M generation. `local-quality` keeps the same code and session-memory retrieval stack and selects Qwen2.5-Coder-3B Q4_K_M generation.

Switching local profiles changes only generation. Existing `code-index` and `session-memory` vectors remain compatible and do not require rebuilding.

## Releases

Each GitHub Release contains:

- `surfbots-dev-platform-vX.Y.Z.tar.gz`
- `surfbots-dev-platform-vX.Y.Z.sha256`
- `manifest.json`

Archives contain only the runtime, Helm charts, model service definitions, MCP server, client policy artifacts, and installation scripts. They exclude private Git history, credentials, `.env` files, canonical developer repositories, model weights, caches, virtual environments, tests, and private development documentation.

The platform requires Linux, Docker with non-root daemon access, Git, rsync, kubectl, k3d, Helm, Python 3, and at least 20 GiB of available disk. The installer validates requirements before deployment and does not silently install system packages or use `sudo`.