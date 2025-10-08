#!/bin/bash
# Deploy mcp-atlassian to 192.168.66.3 with logging support

SERVER="192.168.66.3"
USER="nev3r"
REMOTE_PATH="/home/nev3r/projects/mcp-atlassian"

echo "🚀 Deploying mcp-atlassian to $SERVER..."
echo ""

# Step 1: Sync codebase
echo "📦 Step 1: Syncing codebase..."
rsync -avz --progress \
  --exclude '.git' \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  --exclude '.venv' \
  --exclude 'node_modules' \
  --exclude '.pytest_cache' \
  ./ ${USER}@${SERVER}:${REMOTE_PATH}/

if [ $? -ne 0 ]; then
    echo "❌ Failed to sync codebase"
    exit 1
fi

echo "✅ Codebase synced successfully"
echo ""

# Step 2: Setup on remote server
echo "🔧 Step 2: Setting up on remote server..."
ssh ${USER}@${SERVER} "bash -s" << 'ENDSSH'
cd /home/nev3r/projects/mcp-atlassian

# Create log directory
echo "📁 Creating log directory..."
mkdir -p /tmp/mcp-atlassian-logs
chmod 755 /tmp/mcp-atlassian-logs

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  Warning: .env file not found. Please configure it manually."
else
    # Add LOG_FILE to .env if not present
    if ! grep -q "LOG_FILE=" .env; then
        echo "" >> .env
        echo "# Logging Configuration" >> .env
        echo "LOG_FILE=/tmp/mcp-atlassian-logs/app.log" >> .env
        echo "✅ Added LOG_FILE to .env"
    else
        echo "✅ LOG_FILE already configured in .env"
    fi
fi

# Install/update dependencies
echo "📚 Installing dependencies..."
if command -v uv &> /dev/null; then
    uv sync --frozen
    echo "✅ Dependencies installed with uv"
else
    echo "⚠️  uv not found, skipping dependency installation"
fi

echo "✅ Setup complete on remote server"
ENDSSH

if [ $? -ne 0 ]; then
    echo "❌ Failed to setup on remote server"
    exit 1
fi

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. SSH to the server: ssh ${USER}@${SERVER}"
echo "2. Navigate to: cd ${REMOTE_PATH}"
echo "3. Check the server status (if running as systemd service):"
echo "   sudo systemctl status mcp-atlassian"
echo ""
echo "4. Or restart manually:"
echo "   # Stop any running instance"
echo "   pkill -f 'mcp-atlassian'"
echo ""
echo "   # Start with logging"
echo "   uv run mcp-atlassian --transport streamable-http --port 9000 -vv &"
echo ""
echo "5. Verify logs endpoint:"
echo "   curl http://192.168.66.3:9000/logs"
echo "   curl http://192.168.66.3:9000/healthz"
echo ""
