# Surfbots Code Intelligence

**Persistent semantic code intelligence for AI coding agents.**

Public release distribution for Surfbots Dev Platform: local semantic code intelligence, repository-scoped MCP tools, persistent Development Memory, and Development Supervision (refine_task and review_changes) for AI coding agents. This repository deliberately contains only the inspectable bootstrap entrypoint and release metadata. It is not a mirror of the private platform source.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![Version](https://img.shields.io/badge/version-v0.4.0-blue.svg)](https://github.com/franknaw/surfbots-code-intelligence/releases)

---

## Why It Exists

AI coding agents face a fundamental problem: **they forget repositories between sessions.**

Each time an agent starts, it must:

- Reread entire repositories from disk
- Recompute context from raw file content
- Rediscover symbol definitions and references
- Relearn code structure and relationships

This causes:

| Problem | Impact |
|---------|--------|
| **Context window pressure** | Large repositories exceed LLM context limits |
| **Weak repository continuity** | No persistent understanding across sessions |
| **Repeated semantic rediscovery** | Same queries re-learn from scratch |
| **Inefficient symbol lookup** | No indexed definitions/references |
| **No bounded retrieval** | Agents retrieve entire files instead of relevant snippets |

**Surfbots Code Intelligence** solves this by providing a persistent semantic understanding layer:

- **Indexed repositories** stored in Qdrant vector database
- **Semantic + hybrid search** combines embeddings with lexical search
- **Symbol discovery** via Tree-sitter parsing
- **Bounded file context** retrieval
- **Repository isolation** prevents cross-contamination
- **MCP-native access** for seamless AI agent integration

---

## Core Capabilities

### Repository Registration

Code Intelligence treats each repository as a first-class entity with a unique identity:

- Register any local directory or Git repository
- Repository identity persists across agent sessions
- Repository isolation ensures queries never leak context

```bash
# Register a repository
surfbots-dev repo add /path/to/repository

# List registered repositories
surfbots-dev repo list
```

### Managed Working-Tree Snapshot

The host tooling creates and maintains a controlled repository snapshot:

- **Canonical source**: Developer's working repository
- **Managed snapshot**: Isolated copy for indexing
- **Incremental sync**: Only changed files are re-indexed
- **Git-aware**: Uses `git ls-files` for accurate file detection

### Automatic / Incremental Indexing

Indexing is automatic and incremental:

- **File change detection**: Tracks SHA-256 file hashes
- **Incremental updates**: Only modified files are re-indexed
- **Repository isolation**: Changes in one repository don't affect others
- **Conflict-safe**: Retry-safe indexing that avoids duplicates

### Tree-Sitter Code Parsing

Code Intelligence parses source code with language-aware Tree-sitter:

- **Language support**: Python, TypeScript, JavaScript, Go, Rust, Java, Shell, YAML, JSON, Markdown
- **Symbol extraction**: Function definitions, class hierarchies, type signatures
- **Context chunking**: Intelligent chunking for optimal retrieval
- **File metadata**: Tracks language, extensions, and structure

### Semantic + Hybrid Search

The retrieval pipeline combines multiple search strategies:

```
User Query
    ↓
Embedding Model (Qwen/Qwen3-Embedding-0.6B, 1024-dim)
    ↓
Qdrant Vector Retrieval (cosine distance)
    ↓
Repository / Language / File Path Filter
    ↓
Bounded Results (configurable limit)
```

Search results are cached in-process with TTL, and cached entries automatically retire on reindex.

### Symbol Discovery

Find where symbols are defined in any repository:

```bash
# Find all definitions of 'login' in a repository
curl "http://localhost:8020/api/v1/symbols/search?repository_id=my-repo&query=login&limit=20"
```

| Feature | Description |
|---------|-------------|
| **Multi-language** | Supports Python, TypeScript, JavaScript, Go, Rust, Java, Shell |
| **Exact matching** | Uses regex patterns per language syntax |
| **Bounded results** | Configurable limit prevents overwhelming agents |
| **Repository-scoped** | Never returns results from other repositories |

### Reference Discovery

Find all usages of a symbol across a repository:

```bash
# Find all usages of 'User' class in a repository
curl "http://localhost:8020/api/v1/symbols/references?repository_id=my-repo&symbol=User&limit=50"
```

### File Context Retrieval

Retrieve bounded file content for AI agents:

```bash
# Get full file content
curl "http://localhost:8020/api/v1/files/content?repository_id=my-repo&path=src/main.py"

# Get specific line range
curl "http://localhost:8020/api/v1/files/range?repository_id=my-repo&path=src/main.py&start_line=1&end_line=50"
```

### Repository Isolation

Every query is scoped by `repository_id`:

- **Qdrant filtering**: Repository IDs stored as payload metadata
- **Cross-contamination prevention**: Queries never leak between repositories
- **Scalable**: Thousands of repositories supported with same Qdrant collection

### Qdrant Vector Index

Code Intelligence uses Qdrant for vector search:

| Feature | Detail |
|---------|--------|
| **Dimension** | 1024 (matches embedding model output) |
| **Distance** | Cosine |
| **Collection** | `code-index` (shared across repositories) |
| **Payload metadata** | `repository_id`, `file_path`, `language`, `chunk_index` |
| **Embedding model** | Qwen/Qwen3-Embedding-0.6B (1024-dim) |

---

## MCP Integration

Code Intelligence exposes 7 MCP tools for seamless AI agent integration:

| Tool | Purpose |
|------|---------|
| `search_code` | Search for code snippets across repositories |
| `get_file` | Retrieve file content by path |
| `get_file_range` | Get specific line range from file |
| `find_symbol` | Find where a symbol is defined |
| `find_references` | Find all usages of a symbol |
| `repository_status` | Get repository indexing status |
| `get_file` | Get file content by path |

All tools are namespaced by `repository_id` and respect isolation boundaries.

### Example Usage

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "search_code",
    "arguments": {
      "query": "find login function",
      "repository": "my-repo",
      "limit": 5
    }
  }
}
```

---

## Relationship to Surfbots Dev Platform

**Surfbots Code Intelligence** is the repository understanding and retrieval layer of the broader **Surfbots Dev Platform**:

| Component | Responsibility |
|-----------|----------------|
| **Code Intelligence** | Persistent semantic repository understanding, code search, symbol/reference discovery, bounded file retrieval |
| **Development Memory** | Durable engineering context across tasks (separate repository) |
| **Development Supervision** | Independent review and checkpoint workflow (separate repository) |
| **Model Services** | Local AI models for embedding, generation, and reranking |
| **Kubernetes/k3d Runtime** | Production-grade infrastructure |

Code Intelligence is **public and open-source**. Development Memory and Development Supervision are separate components with their own repositories.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Developer Repository                            │
│  (git checkout, working directory)                                 │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Surfbots Repository Manager                        │
│  - Canonical source: Developer's working tree                       │
│  - Managed snapshot: /workspace/repos/<repo_id>                     │
│  - Incremental sync: Only changed files                             │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          Code Indexer                                │
│  - Tree-sitter parsing (Python, TypeScript, etc.)                  │
│  - Incremental indexing (SHA-256 change detection)                 │
│  - Chunk generation (500 chars, 50 overlap)                        │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ├─────────────────────────────────────────┐
                              ▼                                         ▼
┌───────────────────────────────────────┐      ┌──────────────────────────────────┐
│        Embedding Service              │      │        Reranker Service          │
│  - Qwen/Qwen3-Embedding-0.6B         │      │  - BAAI/bge-reranker-v2-m3       │
│  - Output: 1024 dimensions           │      │  - Relevance scoring             │
└───────────────────────────────────────┘      └──────────────────────────────────┘
                              │                                         │
                              └─────────────────┬───────────────────────┘
                                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            Qdrant                                    │
│  - Collection: code-index                                            │
│  - Dimension: 1024                                                   │
│  - Payload metadata: repository_id, file_path, language            │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Code Search API                                │
│  - HTTP API: /api/v1/*                                              │
│  - Hybrid retrieval: embedding + filter + bounded results          │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          MCP Server                                  │
│  - Port 8023                                                         │
│  - 7 Code Intelligence tools                                        │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  Cline / AI Coding Agent                             │
│  - MCP integration                                                   │
│  - Persistent context across sessions                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Local-First / Privacy

Code Intelligence is designed for local, private operation:

- **Source repository remains under developer control** - No upload required
- **Indexing can run locally** - No external services required
- **Embeddings can remain local** - Qwen/Qwen3-Embedding-0.6B runs on CPU
- **Qdrant vector search is local** - No cloud dependency
- **Kubernetes services operate locally** - k3d cluster on localhost

Local profiles (`local-lightweight`, `local-quality`) use GGUF models that run on CPU without GPU.

---

## Installation

### Prerequisites

- **Linux** (x86_64, ARM64)
- **Docker** daemon with non-root access
- **kubectl** v1.26+
- **k3d** v5.0+
- **Helm** v3.10+
- **Git** v2.30+
- **rsync** v3.2+
- **curl** v7.68+
- **Python** 3.11+

### Minimum Hardware

- **CPU**: 4 modern 64-bit cores minimum, 8+ recommended
- **RAM**: 16 GB minimum, 32 GB recommended
- **Disk**: 20 GB free space minimum
- **GPU**: Not required for local-lightweight profile

### Install Script

Download and run the bootstrap script:

```bash
# Download the bootstrap script
curl -fsSL https://raw.githubusercontent.com/franknaw/surfbots-code-intelligence/main/bootstrap.sh \\
  -o /tmp/surfbots-bootstrap.sh

# Inspect the script before running
less /tmp/surfbots-bootstrap.sh

# Run with a specific release version and profile
bash /tmp/surfbots-bootstrap.sh \\
  --version v0.2.0 \\
  --profile local-lightweight
```

The bootstrap script:

1. Downloads the release archive from GitHub
2. Verifies SHA-256 checksum
3. Extracts to XDG data directory
4. Installs runtime components
5. Starts Kubernetes cluster (k3d)
6. Deploys all services

### Post-Installation

Verify installation:

```bash
# Check platform status
surfbots-admin status

# Check service URLs
surfbots-admin urls

# Verify Qdrant is running
curl http://localhost:6333
```

---

## Usage

### End-to-End Workflow

1. **Install Platform** (see Installation)

2. **Start Platform**

```bash
# Verify services are running
surfbots-admin status

# Port-forward services (in separate terminals)
./surfbots-admin.sh qdrant
./surfbots-admin.sh mcp
./surfbots-admin.sh api
```

3. **Register Repository**

```bash
# Register a local repository
surfbots-dev repo add /path/to/your/repository

# List registered repositories
surfbots-dev repo list
```

4. **Index Repository**

```bash
# Trigger indexing
surfbots-dev repo index your-repository-name

# Check indexing status
surfbots-dev status
```

5. **Connect MCP Client**

Configure your MCP-capable agent (Cline, Claude Dev, etc.) to connect to:

```
http://localhost:8023
```

6. **Search Code**

```bash
# Using HTTP API
curl -X POST http://localhost:8020/api/v1/search \\
  -H "Content-Type: application/json" \\
  -d '{
    "query": "find login function",
    "repository_id": "your-repository-name",
    "limit": 5
  }'

# Using MCP
curl -X POST http://localhost:8023/mcp \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "search_code",
      "arguments": {
        "query": "find login function",
        "repository": "your-repository-name",
        "limit": 5
      }
    }
  }'
```

7. **Inspect Symbols**

```bash
# Find symbol definitions
curl "http://localhost:8020/api/v1/symbols/search?repository_id=your-repository-name&query=login&limit=20"

# Find symbol references
curl "http://localhost:8020/api/v1/symbols/references?repository_id=your-repository-name&symbol=User&limit=50"
```

8. **Retrieve Bounded Context**

```bash
# Get full file
curl "http://localhost:8020/api/v1/files/content?repository_id=your-repository-name&path=src/main.py"

# Get line range
curl "http://localhost:8020/api/v1/files/range?repository_id=your-repository-name&path=src/main.py&start_line=1&end_line=50"
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SURFBOTS_INFERENCE_PROFILE` | `local-lightweight` | Model profile (local-lightweight, local-quality) |
| `XDG_DATA_HOME` | `$HOME/.local/share` | Data directory |
| `XDG_STATE_HOME` | `$HOME/.local/state` | State directory |

### Qdrant Configuration

| Setting | Value |
|---------|-------|
| Port | 6333 (port-forwarded) |
| Collection | `code-index` |
| Dimension | 1024 |
| Distance | Cosine |

### Model Configuration

| Service | Model | Dimension |
|---------|-------|-----------|
| Embedding | `Qwen/Qwen3-Embedding-0.6B` | 1024 |
| Reranking | `BAAI/bge-reranker-v2-m3` | - |
| Generation | `Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF` (Q4_K_M) | - |

---

## Release Information

**Version**: v0.4.0  \
**Release Type**: Initial public release  \
**Status**: Local development, not externally published

### GitHub Releases

Each release contains:

- `surfbots-dev-platform-vX.Y.Z.tar.gz` - Runtime archive
- `surfbots-dev-platform-vX.Y.Z.sha256` - Checksum file
- `manifest.json` - Build metadata

### Release Components

- `scripts/install-runtime.sh` - Runtime installation
- `charts/` - Helm charts
- `models/` - Model definitions
- `mcp-server/` - MCP server
- `code-indexer/` - Code indexer
- `code-search-api/` - Code search API
- `model-embedding/` - Embedding service
- `model-reranker/` - Reranker service
- `qdrant/` - Qdrant configuration

---

## Troubleshooting

### Repository Not Indexed

**Symptom**: `No managed snapshot for <repo_id>`

**Diagnosis**:

```bash
# Check registered repositories
surfbots-dev repo list

# Check indexer status
kubectl logs -n surfbots-dev-platform -l app=code-indexer
```

**Fix**: Re-register repository

```bash
surfbots-dev repo add /path/to/repository
surfbots-dev repo index repository-name
```

### Stale Index

**Symptom**: Search returns outdated results

**Fix**: Reindex repository

```bash
surfbots-dev repo reindex repository-name
```

### MCP Unavailable

**Symptom**: `Connection refused` on port 8023

**Diagnosis**:

```bash
# Check MCP server status
kubectl logs -n surfbots-dev-platform -l app=mcp-server

# Verify port-forward
curl http://localhost:8023
```

### Code Search API Unavailable

**Symptom**: HTTP 503 on `/api/v1/*` endpoints

**Diagnosis**:

```bash
# Check code-search-api status
kubectl logs -n surfbots-dev-platform -l app=code-search-api

# Verify port-forward
curl http://localhost:8020
```

### Qdrant Unavailable

**Symptom**: Vector search returns errors

**Diagnosis**:

```bash
# Check Qdrant status
kubectl get pods -n surfbots-dev-platform | grep qdrant

# Verify port-forward
curl http://localhost:6333
```

### Local Port-Forward Issue

**Diagnosis**:

```bash
# Check port-forward status
kubectl get pods -n surfbots-dev-platform

# Restart port-forwards
./surfbots-admin.sh qdrant
./surfbots-admin.sh mcp
./surfbots-admin.sh api
```

### Context-Window Pressure

**Symptom**: Agent receives truncated responses

**Fix**: Use bounded retrieval

```bash
# Retrieve specific line ranges instead of full files
curl "http://localhost:8020/api/v1/files/range?repository_id=my-repo&path=src/main.py&start_line=1&end_line=100"

# Use search with limit parameter
curl -X POST http://localhost:8020/api/v1/search \\
  -d '{"query":"find login","limit":5}'
```

### Agent Repeatedly Reading Entire Files

**Symptom**: High context usage, slow responses

**Fix**: Ensure agent uses bounded retrieval tools:

- `get_file_range` instead of `get_file`
- `search_code` with `limit` parameter
- `find_symbol` for symbol definitions
- `find_references` for symbol usages

---

## Development / Architecture Notes

### Indexing Pipeline

1. **Repository Registration** → Unique `repository_id` generated
2. **Snapshot Creation** → `git ls-files` → file list
3. **File Parsing** → Tree-sitter → AST + metadata
4. **Chunk Generation** → 500 chars, 50 overlap
5. **Embedding** → Qwen/Qwen3-Embedding-0.6B → 1024-dim vector
6. **Qdrant Upsert** → `code-index` collection with payload metadata

### Repository Isolation

- **Qdrant filter**: `repository_id` in payload
- **No per-repo collections**: Single `code-index` collection
- **Cross-contamination prevention**: Query filter always includes `repository_id`

### Incremental Indexing

- **File hash**: SHA-256 of file content
- **Change detection**: Compare hash with stored value
- **Only changed files**: Re-index only modified files
- **Conflict-safe**: Idempotent upserts prevent duplicates

### Search Pipeline

1. **Query embedding** → Qwen/Qwen3-Embedding-0.6B
2. **Vector retrieval** → Qdrant with repository filter
3. **File path filter** → Client-side substring match
4. **Bounded results** → Configurable limit
5. **Response formatting** → Agent-ready JSON

---

## Status and Scope

### What Code Intelligence Does Today

✅ **Repository indexing** with Tree-sitter parsing
✅ **Semantic search** with Qdrant vector database
✅ **Symbol discovery** via language-aware parsing
✅ **Reference discovery** via regex scanning
✅ **Bounded file retrieval** for agents
✅ **Repository isolation** with payload filtering
✅ **Incremental updates** via file hash tracking
✅ **MCP integration** for AI agents
✅ **Local model profiles** (Qwen, BGE)
✅ **Kubernetes runtime** with k3d

### What Belongs to the Broader Dev Platform

- **Development Memory** - Durable engineering context (separate repository)
- **Development Supervision** - Independent review workflow (separate repository)

### Known Limitations

- No fuzzy symbol matching (exact matching only)
- No cross-repository search (isolation by design)
- No binary file indexing (text files only)
- No real-time sync (manual indexing required)

---

## Contributing

This is the initial public release of Surfbots Code Intelligence.

### Support

- GitHub Issues: Report bugs and request features
- Documentation: See [surfbots-dev-platform](https://github.com/surfbots/surfbots-dev-platform) for platform documentation

### License

Apache 2.0 - See LICENSE file for details.

---

**Version**: v0.4.0  \
**Repository**: [franknaw/surfbots-code-intelligence](https://github.com/franknaw/surfbots-code-intelligence)
