#!/bin/bash
# Setup public log directory for MCP Atlassian

LOG_DIR="/var/log/mcp-atlassian"

echo "Setting up logging directory: $LOG_DIR"

# Create log directory
sudo mkdir -p "$LOG_DIR"

# Set permissions so the application can write
sudo chown -R $USER:$USER "$LOG_DIR"
sudo chmod -R 755 "$LOG_DIR"

echo "✓ Log directory created: $LOG_DIR"
echo "✓ Permissions set for user: $USER"
echo ""
echo "Log file will be: $LOG_DIR/app.log"
echo ""
echo "To view logs:"
echo "  tail -f $LOG_DIR/app.log"
echo ""
echo "Via HTTP (when server is running):"
echo "  curl http://192.168.66.3:9000/logs"
echo "  curl http://192.168.66.3:9000/logs?lines=50"
