# Manual Deployment to 192.168.66.3

## Current Status
- ✅ Code changes committed (commit: `7869382`)
- ✅ /logs endpoint added
- ✅ File logging support implemented
- ⚠️ Automatic deployment failed (SSH authentication issue)

## Manual Deployment Steps

### Step 1: SSH to 192.168.66.3
```bash
ssh nev3r@192.168.66.3
```

### Step 2: Navigate to Project Directory
```bash
cd /home/nev3r/projects/mcp-atlassian
```

### Step 3: Pull Latest Changes
```bash
git fetch origin
git pull origin main
```

Expected output:
```
From https://github.com/your-repo/mcp-atlassian
 * branch            main       -> FETCH_HEAD
Updating d919f29..48fc904
Fast-forward
 src/mcp_atlassian/servers/main.py    | 38 ++++++++++++++++++
 src/mcp_atlassian/utils/logging.py   | 20 ++++++++--
 .env.example                          |  3 ++
 3 files changed, 58 insertions(+), 3 deletions(-)
```

### Step 4: Update Dependencies (if needed)
```bash
uv sync --frozen
```

### Step 5: Configure Logging
```bash
# Create log directory
mkdir -p /tmp/mcp-atlassian-logs
chmod 755 /tmp/mcp-atlassian-logs

# Add to .env if not present
echo "" >> .env
echo "# Logging Configuration" >> .env
echo "LOG_FILE=/tmp/mcp-atlassian-logs/app.log" >> .env
```

Or manually edit `.env` and add:
```bash
# Logging Configuration
LOG_FILE=/tmp/mcp-atlassian-logs/app.log
```

### Step 6: Restart the Server

#### Option A: If Running as Systemd Service
```bash
sudo systemctl restart mcp-atlassian
sudo systemctl status mcp-atlassian
```

#### Option B: If Running Manually
```bash
# Find and kill existing process
ps aux | grep mcp-atlassian
kill <PID>

# Start new process with logging
uv run mcp-atlassian --transport streamable-http --port 9000 -vv &

# Or use nohup for persistence
nohup uv run mcp-atlassian --transport streamable-http --port 9000 -vv > /tmp/mcp-server.log 2>&1 &
```

#### Option C: If Running in tmux/screen
```bash
# Attach to session
tmux attach -t mcp-atlassian
# or
screen -r mcp-atlassian

# Stop with Ctrl+C
# Start new process
uv run mcp-atlassian --transport streamable-http --port 9000 -vv

# Detach: Ctrl+B then D (tmux) or Ctrl+A then D (screen)
```

### Step 7: Verify Deployment

#### Test Health Endpoint
```bash
curl http://192.168.66.3:9000/healthz
```

Expected output:
```json
{"status":"ok"}
```

#### Test Logs Endpoint
```bash
curl http://192.168.66.3:9000/logs?lines=10
```

Expected output:
```json
{
  "log_file": "/tmp/mcp-atlassian-logs/app.log",
  "total_lines": 100,
  "showing_lines": 10,
  "logs": "2025-10-08 14:00:00 - INFO - mcp-atlassian - Server started...\n..."
}
```

#### Check Log File Directly
```bash
# View last 50 lines
tail -n 50 /tmp/mcp-atlassian-logs/app.log

# Follow logs in real-time
tail -f /tmp/mcp-atlassian-logs/app.log
```

### Step 8: Test with Tony Agent

From n8n or your local machine, test Tony:
```bash
# Test via Tony tools
mcp__tony_tools__Call_Tony_Tools_({
  sessionID: "test-deployment-66.3",
  chatInput: "Get issue FE-151"
})
```

Check logs:
```bash
curl http://192.168.66.3:9000/logs?lines=20
```

## Verification Checklist

- [ ] Code pulled from git (commit 48fc904 or later)
- [ ] Dependencies updated
- [ ] .env file has LOG_FILE=/tmp/mcp-atlassian-logs/app.log
- [ ] Log directory created: /tmp/mcp-atlassian-logs
- [ ] Server restarted
- [ ] Health endpoint responds: `curl http://192.168.66.3:9000/healthz`
- [ ] Logs endpoint responds: `curl http://192.168.66.3:9000/logs`
- [ ] Log file exists: `ls -lh /tmp/mcp-atlassian-logs/app.log`
- [ ] Logs are being written: `tail /tmp/mcp-atlassian-logs/app.log`
- [ ] Tony agent works without timeout

## Troubleshooting

### Issue: Server won't start
```bash
# Check if port is already in use
lsof -i :9000

# Check logs for errors
tail -50 /tmp/mcp-atlassian-logs/app.log

# Check stderr output
cat /tmp/mcp-server.log  # if using nohup
```

### Issue: Logs endpoint returns 404
```bash
# Verify server version
curl http://192.168.66.3:9000/healthz

# Check git commit
cd /home/nev3r/projects/mcp-atlassian
git log --oneline -1
```

Should show commit `7869382` or later.

### Issue: Log file not being created
```bash
# Check environment variable
cat .env | grep LOG_FILE

# Check directory permissions
ls -ld /tmp/mcp-atlassian-logs

# Restart server to reload .env
pkill -f mcp-atlassian
uv run mcp-atlassian --transport streamable-http --port 9000 -vv &
```

### Issue: Permission denied on log directory
```bash
# Fix permissions
sudo chown -R nev3r:nev3r /tmp/mcp-atlassian-logs
chmod 755 /tmp/mcp-atlassian-logs
```

## Success Indicators

When everything is working correctly, you should see:

1. **Health endpoint**:
   ```bash
   $ curl http://192.168.66.3:9000/healthz
   {"status":"ok"}
   ```

2. **Logs endpoint**:
   ```bash
   $ curl http://192.168.66.3:9000/logs?lines=5 | jq .
   {
     "log_file": "/tmp/mcp-atlassian-logs/app.log",
     "total_lines": 247,
     "showing_lines": 5,
     "logs": "..."
   }
   ```

3. **Log file growing**:
   ```bash
   $ watch -n 1 'ls -lh /tmp/mcp-atlassian-logs/app.log'
   # File size should increase as requests come in
   ```

4. **Tony agent works**:
   - No more timeout errors
   - Can retrieve large issues
   - Logs show all MCP tool calls

## Changes Deployed

### New Features
1. **HTTP Logs Endpoint** (`/logs`)
   - View logs via HTTP GET request
   - Query parameter: `?lines=N` to limit output
   - Returns JSON with log file info and content

2. **File Logging Support**
   - Environment variable: `LOG_FILE`
   - Creates parent directories automatically
   - Appends to existing log file
   - Includes timestamps in log format

3. **Enhanced Logging Format**
   - Added timestamps: `YYYY-MM-DD HH:MM:SS`
   - Format: `timestamp - LEVEL - logger_name - message`

### Files Modified
- `src/mcp_atlassian/servers/main.py` - Added /logs endpoint
- `src/mcp_atlassian/utils/logging.py` - Added file handler and timestamp
- `.env` - Added LOG_FILE configuration

### Commits
- `7869382` - feat: add /logs endpoint for retrieving application logs
- `48fc904` - chore: remove deprecated main.json configuration file

## Contact

If you encounter any issues during deployment:
1. Check the troubleshooting section above
2. Review server logs: `tail -f /tmp/mcp-atlassian-logs/app.log`
3. Verify n8n connectivity: `curl http://192.168.66.3:9000/healthz`

---

**Deployment Date**: 2025-10-08
**Version**: commit 48fc904 and later
**Server**: 192.168.66.3:9000
