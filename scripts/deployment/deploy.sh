#!/bin/bash
# Deploy mcp-atlassian to 192.168.66.3 using sshpass (uvoadmin user)

SERVER="192.168.66.3"
USER="uvoadmin"
REMOTE_PATH="/Users/uvoadmin/mcp-atlassian"
PASSWORD="${SSHPASS:-1234@Qwer}"

export SSHPASS="$PASSWORD"

echo "🚀 Deploying mcp-atlassian to $SERVER (user: $USER)..."
echo ""

# Step 1: Sync codebase
echo "📦 Step 1: Syncing codebase via rsync..."
sshpass -e rsync -avz --progress \
  --exclude '.git' \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  --exclude '.venv' \
  --exclude 'node_modules' \
  --exclude '.pytest_cache' \
  --exclude 'tmp/' \
  -e "ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no" \
  ./ ${USER}@${SERVER}:${REMOTE_PATH}/

if [ $? -ne 0 ]; then
    echo "❌ Failed to sync codebase"
    exit 1
fi

echo "✅ Codebase synced successfully"
echo ""

# Step 2: Setup and restart on remote server
echo "🔧 Step 2: Setting up and restarting server on 66.3..."
sshpass -e ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no ${USER}@${SERVER} "bash -s" << 'ENDSSH'
cd /Users/uvoadmin/mcp-atlassian

echo "📁 Creating log directory..."
mkdir -p /tmp/mcp-atlassian-logs
chmod 755 /tmp/mcp-atlassian-logs

echo "⚙️  Configuring .env..."
if [ ! -f .env ]; then
    echo "⚠️  .env not found, creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
    fi
fi

if ! grep -q "LOG_FILE=" .env 2>/dev/null; then
    echo "" >> .env
    echo "# Logging Configuration" >> .env
    echo "LOG_FILE=/tmp/mcp-atlassian-logs/app.log" >> .env
    echo "✅ Added LOG_FILE to .env"
else
    echo "✅ LOG_FILE already configured in .env"
fi

echo "🔄 Stopping existing server..."
pkill -f 'mcp-atlassian' 2>/dev/null && echo "Stopped existing process" || echo "No existing process found"
sleep 2

echo "🚀 Starting new server..."
# Check if uv is available
if command -v uv &> /dev/null; then
    nohup uv run mcp-atlassian --transport streamable-http --port 9000 --host 0.0.0.0 -vv > /tmp/mcp-server-startup.log 2>&1 &
    echo "Started with uv"
elif [ -f .venv/bin/python ]; then
    nohup .venv/bin/python -m mcp_atlassian --transport streamable-http --port 9000 --host 0.0.0.0 -vv > /tmp/mcp-server-startup.log 2>&1 &
    echo "Started with venv python"
else
    echo "❌ No uv or venv found"
    exit 1
fi

sleep 3
echo "✅ Server started"

# Show startup log
echo ""
echo "📋 Startup log:"
tail -20 /tmp/mcp-server-startup.log

ENDSSH

if [ $? -ne 0 ]; then
    echo "❌ Failed to setup/restart server on 66.3"
    exit 1
fi

echo ""
echo "⏳ Waiting for server to be ready..."
sleep 5

# Step 3: Verify deployment
echo ""
echo "🔍 Step 3: Verifying deployment..."

# Test health endpoint
echo -n "Testing /healthz endpoint... "
HEALTH=$(curl -s http://192.168.66.3:9000/healthz 2>/dev/null)
if echo "$HEALTH" | grep -q "ok"; then
    echo "✅ OK"
else
    echo "❌ FAILED"
    echo "Response: $HEALTH"
fi

# Test logs endpoint
echo -n "Testing /logs endpoint... "
LOGS=$(curl -s http://192.168.66.3:9000/logs?lines=1 2>/dev/null)
if echo "$LOGS" | grep -q "log_file"; then
    echo "✅ OK"
    echo "   Sample: $(echo "$LOGS" | jq -r '.log_file' 2>/dev/null)"
else
    echo "⚠️  Endpoint available but no logs yet"
    echo "   Response: $LOGS"
fi

# Check log file on remote
echo -n "Checking log file on server... "
LOG_CHECK=$(sshpass -e ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no ${USER}@${SERVER} "ls -lh /tmp/mcp-atlassian-logs/app.log 2>&1")
if echo "$LOG_CHECK" | grep -q "No such file"; then
    echo "⚠️  Not created yet (will be created on first request)"
else
    echo "✅ OK"
    LOG_SIZE=$(echo "$LOG_CHECK" | awk '{print $5}')
    echo "   Log file size: $LOG_SIZE"
fi

# Check server process
echo -n "Checking server process... "
PROCESS=$(sshpass -e ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no ${USER}@${SERVER} "ps aux | grep '[m]cp-atlassian' | head -1")
if [ -n "$PROCESS" ]; then
    echo "✅ Running"
    PID=$(echo "$PROCESS" | awk '{print $2}')
    echo "   PID: $PID"
else
    echo "❌ Not running!"
    echo "   Check startup log on server: /tmp/mcp-server-startup.log"
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📊 Server Status:"
echo "  - Health: http://192.168.66.3:9000/healthz"
echo "  - Logs:   http://192.168.66.3:9000/logs?lines=50"
echo ""
echo "📝 Quick Commands:"
echo "  # View logs"
echo "  curl -s http://192.168.66.3:9000/logs?lines=100 | jq -r '.logs'"
echo ""
echo "  # Check health"
echo "  curl http://192.168.66.3:9000/healthz"
echo ""
echo "  # SSH to server"
echo "  sshpass -e ssh uvoadmin@192.168.66.3"
echo ""
echo "  # View startup log"
echo "  ssh uvoadmin@192.168.66.3 'tail -50 /tmp/mcp-server-startup.log'"
echo ""
