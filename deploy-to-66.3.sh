#!/bin/bash
# Deploy logging updates to 192.168.66.3

SERVER="192.168.66.3"
USER="nev3r"
REMOTE_PATH="/home/nev3r/projects/mcp-atlassian"

echo "Deploying logging updates to $SERVER..."

# Option 1: Using rsync (recommended)
echo "Using rsync to sync files..."
rsync -avz --progress \
  src/mcp_atlassian/utils/logging.py \
  src/mcp_atlassian/servers/main.py \
  .env \
  setup-logs.sh \
  ${USER}@${SERVER}:${REMOTE_PATH}/

echo ""
echo "Files synced. Now run on the remote server:"
echo "  ssh ${USER}@${SERVER}"
echo "  cd ${REMOTE_PATH}"
echo "  ./setup-logs.sh"
echo "  # Then restart your MCP server"
