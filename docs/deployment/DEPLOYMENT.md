# Deploying Logging Updates to 192.168.66.3

## Method 1: Git (Recommended)

```bash
# On local machine
git add -A
git commit -m "feat: add public logging with file and HTTP endpoint"
git push

# On 192.168.66.3
cd /home/nev3r/projects/mcp-atlassian
git pull
./setup-logs.sh
# Restart the MCP server
```

## Method 2: Direct File Sync

```bash
# On local machine
./deploy-to-66.3.sh

# On 192.168.66.3
cd /home/nev3r/projects/mcp-atlassian
./setup-logs.sh
# Restart the MCP server
```

## Method 3: Manual Copy

Copy these files to 192.168.66.3:
- `src/mcp_atlassian/utils/logging.py`
- `src/mcp_atlassian/servers/main.py`
- `.env`
- `setup-logs.sh`

Then on 192.168.66.3:
```bash
cd /home/nev3r/projects/mcp-atlassian
chmod +x setup-logs.sh
./setup-logs.sh
# Restart the MCP server
```

## Accessing Logs

After deployment and server restart:

### Via HTTP:
```bash
# Get last 100 lines (default)
curl http://192.168.66.3:9000/logs

# Get last 50 lines
curl http://192.168.66.3:9000/logs?lines=50

# Pretty print JSON
curl -s http://192.168.66.3:9000/logs | jq .
```

### Via File:
```bash
# On 192.168.66.3
tail -f /var/log/mcp-atlassian/app.log

# Last 100 lines
tail -n 100 /var/log/mcp-atlassian/app.log

# Search logs
grep "ERROR" /var/log/mcp-atlassian/app.log
```

### From Browser:
Open: `http://192.168.66.3:9000/logs`

## Verify Deployment

```bash
# Check if log file exists
ssh nev3r@192.168.66.3 "ls -lh /var/log/mcp-atlassian/app.log"

# Check server is running
curl http://192.168.66.3:9000/healthz

# Check logs endpoint
curl http://192.168.66.3:9000/logs?lines=10
```
