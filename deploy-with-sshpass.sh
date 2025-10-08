#!/bin/bash
# Deploy mcp-atlassian to 192.168.66.3 using sshpass

SERVER="192.168.66.3"
USER="nev3r"
REMOTE_PATH="/home/nev3r/projects/mcp-atlassian"

# Check if password is provided
if [ -z "$SSHPASS" ]; then
    echo "Please provide SSH password:"
    read -s SSHPASS
    export SSHPASS
fi

echo "🚀 Deploying mcp-atlassian to $SERVER..."
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
  --exclude '/tmp' \
  -e "ssh -o StrictHostKeyChecking=no" \
  ./ ${USER}@${SERVER}:${REMOTE_PATH}/

if [ $? -ne 0 ]; then
    echo "❌ Failed to sync codebase"
    exit 1
fi

echo "✅ Codebase synced successfully"
echo ""

# Step 2: Setup and restart on remote server
echo "🔧 Step 2: Setting up and restarting server on 66.3..."
sshpass -e ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "bash -s" << 'ENDSSH'
cd /home/nev3r/projects/mcp-atlassian

echo "📁 Creating log directory..."
mkdir -p /tmp/mcp-atlassian-logs
chmod 755 /tmp/mcp-atlassian-logs

echo "⚙️  Configuring .env..."
if ! grep -q "LOG_FILE=" .env 2>/dev/null; then
    echo "" >> .env
    echo "# Logging Configuration" >> .env
    echo "LOG_FILE=/tmp/mcp-atlassian-logs/app.log" >> .env
    echo "✅ Added LOG_FILE to .env"
else
    echo "✅ LOG_FILE already configured in .env"
fi

echo "🔄 Stopping existing server..."
pkill -f 'mcp-atlassian' 2>/dev/null || echo "No existing process found"
sleep 2

echo "🚀 Starting new server..."
nohup /home/nev3r/.local/bin/uv run mcp-atlassian --transport streamable-http --port 9000 -vv > /tmp/mcp-server-startup.log 2>&1 &

sleep 3

echo "✅ Server started"
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
else
    echo "❌ FAILED"
    echo "Response: $LOGS"
fi

# Check log file on remote
echo -n "Checking log file on server... "
sshpass -e ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "ls -lh /tmp/mcp-atlassian-logs/app.log 2>/dev/null" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ OK"
    LOG_SIZE=$(sshpass -e ssh -o StrictHostKeyChecking=no ${USER}@${SERVER} "ls -lh /tmp/mcp-atlassian-logs/app.log 2>/dev/null | awk '{print \$5}'")
    echo "   Log file size: $LOG_SIZE"
else
    echo "⚠️  Not created yet (will be created on first request)"
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📊 Server Status:"
echo "  - Health: http://192.168.66.3:9000/healthz"
echo "  - Logs:   http://192.168.66.3:9000/logs?lines=50"
echo ""
echo "📝 View logs in real-time:"
echo "  curl -s http://192.168.66.3:9000/logs?lines=100 | jq -r '.logs'"
echo ""
echo "🔧 SSH to server:"
echo "  sshpass -e ssh ${USER}@${SERVER}"
echo ""
