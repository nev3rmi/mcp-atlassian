# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Environment Setup
```bash
# Install dependencies
uv sync
uv sync --frozen --all-extras --dev

# Activate virtual environment
source .venv/bin/activate  # macOS/Linux
.venv\Scripts\activate.ps1  # Windows

# Set up pre-commit hooks
pre-commit install

# Configure environment
cp .env.example .env
```

### Testing
```bash
# Run all tests
uv run pytest

# Run with coverage
uv run pytest --cov=mcp_atlassian

# Run specific test file
uv run pytest tests/unit/jira/test_issues.py

# Run specific test
uv run pytest tests/unit/jira/test_issues.py::test_function_name

# Run integration tests (requires real Atlassian credentials)
uv run pytest tests/integration/
```

### Code Quality
```bash
# Run all pre-commit checks
pre-commit run --all-files

# Individual tools
ruff check .                    # Linting
ruff format .                   # Formatting
pyright                         # Type checking
```

### Running the Server
```bash
# Run locally with stdio transport (default)
uv run mcp-atlassian

# Run with verbose logging
uv run mcp-atlassian -v   # INFO level
uv run mcp-atlassian -vv  # DEBUG level

# Run with HTTP transport
uv run mcp-atlassian --transport sse --port 9000
uv run mcp-atlassian --transport streamable-http --port 9000

# OAuth setup wizard
uv run mcp-atlassian --oauth-setup -v

# Docker build
docker build -t mcp-atlassian .
```

## Architecture Overview

### Core Components

**MCP Server Architecture**: The project uses FastMCP to implement an MCP (Model Context Protocol) server that exposes Atlassian APIs as tools to AI assistants. The server supports multiple transports (stdio, SSE, streamable-http) and can run in both single-user and multi-user modes.

**Main Server** (`src/mcp_atlassian/servers/main.py`):
- Entry point that orchestrates both Jira and Confluence servers
- Handles lifecycle management via `main_lifespan()` context manager
- Manages configuration loading, authentication setup, and service initialization
- Implements tool filtering (via `ENABLED_TOOLS`) and read-only mode
- Uses `MainAppContext` to share configuration between sub-servers

**Sub-Servers**:
- `servers/jira.py`: Exposes all Jira operations as MCP tools
- `servers/confluence.py`: Exposes all Confluence operations as MCP tools
- Each sub-server registers its tools with the main FastMCP instance
- Tools are dynamically filtered based on configuration (read-only mode, enabled tools)

### Authentication System

**Three Authentication Methods** (in order of precedence):
1. **API Token/Basic Auth** (`username` + `api_token`): Standard for Cloud
2. **Personal Access Token (PAT)** (`personal_token`): Standard for Server/Data Center
3. **OAuth 2.0**: Cloud only, supports two modes:
   - Standard OAuth: Server manages tokens (stored via keyring or local file in `~/.mcp-atlassian/`)
   - BYOT (Bring Your Own Token): External system manages tokens, passed via headers or env vars

**Multi-Cloud OAuth**: When `ATLASSIAN_OAUTH_ENABLE=true`, the server accepts per-request authentication:
- Cloud: `Authorization: Bearer <token>` + `X-Atlassian-Cloud-Id: <cloud_id>`
- Server/DC: `Authorization: Token <pat>`
- Falls back to server-level authentication if headers not provided

**Configuration Classes**:
- `JiraConfig` / `ConfluenceConfig`: Load from environment, detect auth type, validate credentials
- Both support `.from_env()` class method and `.is_auth_configured()` validation
- OAuth configuration stored in separate `OAuthConfig` objects

### Client Layer

**Base Clients** (`jira/client.py`, `confluence/client.py`):
- Initialize `atlassian-python-api` clients (Jira/Confluence classes)
- Configure authentication based on config (basic, PAT, or OAuth)
- Set up session with SSL verification, proxy settings, and custom headers
- OAuth clients use special API URLs: `https://api.atlassian.com/ex/{jira|confluence}/{cloud_id}`

**Feature Modules**: Both services organize functionality into focused modules:
- `issues.py` / `pages.py`: Core CRUD operations
- `search.py`: JQL/CQL search implementations
- `comments.py`: Comment management
- `boards.py`, `sprints.py`, `epics.py`: Jira Agile-specific
- `spaces.py`, `labels.py`, `users.py`: Confluence-specific

### Data Models

**Pydantic Models** (`src/mcp_atlassian/models/`):
- Strongly-typed models for all API responses
- Separate packages for `jira` and `confluence` models
- Key models: `JiraIssue`, `JiraSearchResult`, `ConfluencePage`, `ConfluenceSearchResult`
- Models include helper methods like `to_simplified_dict()` for LLM consumption
- Shared base classes in `models/base.py`

### Preprocessing Layer

**Content Processors** (`src/mcp_atlassian/preprocessing/`):
- `JiraPreprocessor`: Converts Jira wiki/ADF to markdown, simplifies issue data
- `ConfluencePreprocessor`: Converts Confluence storage format to markdown
- Both implement `BasePreprocessor` interface
- Used to make content more digestible for LLMs

### Configuration & Environment

**Environment Variables**: Comprehensive configuration via env vars (see `.env.example`):
- Service URLs and credentials
- Filtering: `JIRA_PROJECTS_FILTER`, `CONFLUENCE_SPACES_FILTER`
- Operational: `READ_ONLY_MODE`, `ENABLED_TOOLS`, `TRANSPORT`, `PORT`
- Network: Proxy settings (global + per-service), custom headers, SSL verification
- Logging: `MCP_VERBOSE`, `MCP_VERY_VERBOSE`, `MCP_LOGGING_STDOUT`

**Utilities** (`src/mcp_atlassian/utils/`):
- `oauth.py`, `oauth_setup.py`: OAuth flow and token management
- `ssl.py`: SSL verification configuration
- `logging.py`: Sensitive data masking in logs
- `tools.py`: Tool filtering logic
- `environment.py`: Service detection and configuration

### Testing Structure

**Test Organization**:
- `tests/unit/`: Unit tests with mocked API calls
- `tests/integration/`: Integration tests requiring real credentials
- `tests/fixtures/`: Shared mock data and fixtures
- `tests/utils/`: Test utilities (factories, assertions, base classes)

**Key Test Patterns**:
- Use `conftest.py` for shared fixtures
- Mock `atlassian-python-api` client responses
- Integration tests use `TEST_REAL_API` environment variable
- OAuth tests use separate fixtures in `test_client_oauth.py` files

## Important Technical Notes

### FastMCP Tool Registration
Tools are registered via decorators on the sub-servers. The tool's read/write nature is determined by its name prefix or explicit categorization. Always check `should_include_tool()` logic in `utils/tools.py` when adding new tools.

### OAuth Token Management
OAuth tokens are stored using Python's `keyring` library (falls back to local file). The token refresh happens automatically in `utils/oauth.py` via `configure_oauth_session()`. For BYOT mode, no refresh occurs.

### Cloud vs Server/Data Center Detection
Automatically detected by checking if URL contains `atlassian.net`. Cloud instances use different API endpoints and authentication. OAuth only works with Cloud.

### Markdown Conversion
Both Jira (ADF/Wiki) and Confluence (Storage Format) content is converted to markdown for better LLM consumption. This happens in the preprocessing layer but can be bypassed if needed.

### Custom Headers & Proxies
Both services support per-service custom headers (`JIRA_CUSTOM_HEADERS`, `CONFLUENCE_CUSTOM_HEADERS`) and proxy settings. Format: `X-Header1=value1,X-Header2=value2`. Service-specific proxy vars override global ones.

### Error Handling
Custom exception: `MCPAtlassianAuthenticationError` in `exceptions.py`. All authentication failures should raise this. Other errors typically propagate from `atlassian-python-api`.

### n8n and HTTP Transport Compatibility

**Issue**: When using n8n or other MCP clients with HTTP transport (SSE/streamable-http), complex parameters like `additional_fields` or `fields` may be serialized as JSON strings instead of native Python dictionaries.

**Solution**: The MCP tool functions in `servers/jira.py` now accept both:
- Native Python dictionaries: `{"priority": {"name": "High"}}`
- JSON strings: `'{"priority": {"name": "High"}}'`

Tools affected:
- `create_issue` (parameter: `additional_fields`)
- `update_issue` (parameters: `fields`, `additional_fields`)
- `transition_issue` (parameter: `fields`)
- `create_issue_link` (parameter: `comment_visibility`)

The parsing logic automatically detects JSON strings and deserializes them before processing. This ensures compatibility with n8n workflows and other HTTP-based MCP clients while maintaining backward compatibility with Claude Code (stdio transport).

## Code Style Guidelines

- Python 3.10+ with type annotations (prefer `str | None` over `Optional[str]`)
- Line length: 88 characters (Black/Ruff default)
- Use Google-style docstrings
- Type checking: `pyright` (preferred over mypy)
- Formatting: `ruff format` (replaces Black)
- Linting: `ruff` with config in `pyproject.toml`
- Pre-commit hooks enforce all style requirements
