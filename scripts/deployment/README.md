# Deployment Scripts

This directory contains scripts for deploying mcp-atlassian to servers.

## Scripts

### `deploy.sh` ⭐ **RECOMMENDED**
**Purpose**: Complete deployment to 192.168.66.3 with validation

**Features**:
- Uses sshpass for authentication
- Syncs entire codebase via rsync
- Configures logging automatically
- Restarts server
- Verifies deployment (health, logs, process)
- Comprehensive status reporting

**Usage**:
```bash
export SSHPASS='your-password'
./scripts/deployment/deploy.sh
```

**Requirements**:
- `sshpass` installed
- SSH access to target server
- Target server must have Python environment set up

**What it does**:
1. Syncs codebase to `/Users/uvoadmin/mcp-atlassian`
2. Creates log directory `/tmp/mcp-atlassian-logs`
3. Adds `LOG_FILE` to `.env` if not present
4. Stops existing server process
5. Starts new server with HTTP transport on port 9000
6. Verifies health endpoint, logs endpoint, and process

---

### `setup-logs.sh`
**Purpose**: Initialize log directory with proper permissions

**Features**:
- Creates `/var/log/mcp-atlassian` directory
- Sets appropriate permissions
- Provides usage instructions

**Usage**:
```bash
./scripts/deployment/setup-logs.sh
```

**Note**: Uses `sudo` for `/var/log` access. For non-root deployments, logs are configured to use `/tmp/mcp-atlassian-logs/` instead.

---

## Deployment Targets

### 192.168.66.3 (Primary)
- **User**: uvoadmin
- **Path**: /Users/uvoadmin/mcp-atlassian
- **Port**: 9000
- **Transport**: streamable-http
- **Logs**: /tmp/mcp-atlassian-logs/app.log
- **Endpoints**:
  - Health: http://192.168.66.3:9000/healthz
  - Logs: http://192.168.66.3:9000/logs
  - MCP: http://192.168.66.3:9000/mcp

---

## Manual Deployment

If automatic deployment fails, see: [`docs/deployment/MANUAL_DEPLOYMENT_66.3.md`](../../docs/deployment/MANUAL_DEPLOYMENT_66.3.md)

---

## Troubleshooting

### SSH Authentication Fails
```bash
# Test connection
export SSHPASS='your-password'
sshpass -e ssh uvoadmin@192.168.66.3 "whoami"

# If fails, check:
# 1. Password is correct
# 2. SSH server allows password authentication
# 3. User account is not locked
```

### Server Won't Start
```bash
# Check startup log on server
ssh uvoadmin@192.168.66.3 "tail -50 /tmp/mcp-server-startup.log"

# Common issues:
# 1. Port 9000 already in use: `lsof -i :9000`
# 2. Missing dependencies: `cd /path && uv sync`
# 3. .env misconfigured: `cat .env | grep -E 'JIRA_URL|CONFLUENCE_URL'`
```

### Logs Not Working
```bash
# Verify LOG_FILE in .env
ssh uvoadmin@192.168.66.3 "grep LOG_FILE /Users/uvoadmin/mcp-atlassian/.env"

# Check log directory exists
ssh uvoadmin@192.168.66.3 "ls -lh /tmp/mcp-atlassian-logs/"

# Restart server to reload .env
./scripts/deployment/deploy.sh
```

---

## Version History

**v2 (2025-10-08)** - `deploy.sh`
- Complete automated deployment
- Verification and health checks
- Proper error handling
- Works with uvoadmin user on 66.3

**v1 (deprecated)** - Multiple fragmented scripts
- `deploy-66.3.sh`, `deploy-to-66.3.sh`, `deploy-with-sshpass.sh`
- Removed in favor of single unified script

---

**See also**: [`docs/deployment/`](../../docs/deployment/) for deployment documentation
