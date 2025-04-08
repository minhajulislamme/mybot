#!/bin/bash
# Setup script for Binance trading bot on DigitalOcean VPS
# This script will install dependencies and set up the systemd service

# Exit immediately if a command exits with a non-zero status
set -e

# Display commands being executed
set -x

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Try using sudo."
    exit 1
fi

# Define variables
USERNAME=$(logname)
BOT_DIR="$(pwd)"
SERVICE_NAME="binancebot"

echo "Setting up Binance trading bot for user: $USERNAME"
echo "Bot directory: $BOT_DIR"

# Update package list
apt-get update

# Install system dependencies
apt-get install -y python3 python3-pip python3-venv git supervisor

# Create python virtual environment
echo "Creating Python virtual environment..."
if [ ! -d "$BOT_DIR/venv" ]; then
    python3 -m venv "$BOT_DIR/venv"
fi

# Activate virtual environment and install requirements
echo "Installing Python dependencies..."
source "$BOT_DIR/venv/bin/activate"
pip install --upgrade pip
pip install -r "$BOT_DIR/requirements.txt"
deactivate

# Create log directory if it doesn't exist
mkdir -p "$BOT_DIR/logs"

# Create the systemd service file
echo "Creating systemd service file..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Binance Trading Bot
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$BOT_DIR
ExecStart=$BOT_DIR/venv/bin/python $BOT_DIR/main.py --small-account
Restart=always
RestartSec=10
StandardOutput=append:$BOT_DIR/logs/bot_service.log
StandardError=append:$BOT_DIR/logs/bot_service_error.log
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Make script executable
chmod +x "$BOT_DIR/main.py"

# Set permissions
chown -R "$USERNAME:$USERNAME" "$BOT_DIR"

# Reload systemd configuration
systemctl daemon-reload

# Enable and start the service
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

echo "Checking service status..."
systemctl status "$SERVICE_NAME"

echo "======================================"
echo "Setup completed!"
echo "The bot is now running as a system service."
echo ""
echo "Useful commands:"
echo "- Check bot status: systemctl status $SERVICE_NAME"
echo "- View logs: journalctl -u $SERVICE_NAME -f"
echo "- Restart bot: systemctl restart $SERVICE_NAME"
echo "- Stop bot: systemctl stop $SERVICE_NAME"
echo "======================================"