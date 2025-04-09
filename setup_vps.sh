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

# Define variables - using /root/mybot as this is where your bot seems to be located on the VPS
BOT_DIR="/root/mybot"
SERVICE_NAME="binancebot"
LOG_DIR="$BOT_DIR/logs"

echo "Setting up Binance trading bot"
echo "Bot directory: $BOT_DIR"

# Create bot directory if it doesn't exist
mkdir -p "$BOT_DIR"
mkdir -p "$LOG_DIR"

# Update package list
apt-get update

# Install system dependencies
apt-get install -y python3 python3-pip python3-venv python3-dev git supervisor

# Check if Python 3 is installed
if ! command -v python3 &>/dev/null; then
    echo "ERROR: Python 3 not found even after installation attempt!"
    exit 1
else
    echo "Python 3 installed: $(python3 -V)"
fi

# Copy all files from current directory to BOT_DIR if running from a different location
if [ "$(pwd)" != "$BOT_DIR" ]; then
    echo "Copying files to $BOT_DIR"
    cp -r . "$BOT_DIR"
fi

# Create python virtual environment
echo "Creating Python virtual environment..."
if [ ! -d "$BOT_DIR/venv" ]; then
    python3 -m venv "$BOT_DIR/venv"
fi

# Activate virtual environment and install requirements
echo "Installing Python dependencies..."
source "$BOT_DIR/venv/bin/activate"

# Upgrade pip
python -m pip install --upgrade pip

# Install wheel package to avoid build errors
pip install wheel

# Install all required packages
pip install -r "$BOT_DIR/requirements.txt"

# List all installed packages for verification
echo "Installed packages:"
pip list

# Test import of key packages
echo "Testing key package imports..."
python -c "import schedule; import python_binance; import numpy; import pandas; import websocket; print('All key packages imported successfully!')" || echo "Warning: Not all packages imported successfully. Check logs for details."

deactivate

# Create the systemd service file
echo "Creating systemd service file..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Binance Trading Bot
After=network.target

[Service]
User=root
WorkingDirectory=$BOT_DIR
ExecStart=$BOT_DIR/venv/bin/python3 $BOT_DIR/main.py --small-account
Restart=on-failure
RestartSec=30
StandardOutput=append:$BOT_DIR/logs/bot_service.log
StandardError=append:$BOT_DIR/logs/bot_service_error.log
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Make scripts executable
chmod +x "$BOT_DIR/main.py" 2>/dev/null || echo "Warning: main.py not executable, may not be needed"
chmod +x "$BOT_DIR/debug.sh"

# Set permissions
chown -R root:root "$BOT_DIR"

# Reload systemd configuration
systemctl daemon-reload

# Enable the service
systemctl enable "$SERVICE_NAME"

# Create a service checker script
cat > "$BOT_DIR/check_service.sh" << 'EOF'
#!/bin/bash
# Script to check and restart the bot service if it's down

SERVICE_NAME="binancebot"
LOG_FILE="/root/mybot/logs/service_checker.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Checking service status" >> "$LOG_FILE"

# Check if service is running
if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "$(date): Service is down, attempting to restart" >> "$LOG_FILE"
    systemctl restart "$SERVICE_NAME"
    sleep 10
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "$(date): Service successfully restarted" >> "$LOG_FILE"
    else
        echo "$(date): Failed to restart service" >> "$LOG_FILE"
        # Get last 20 lines of journal for the service
        journalctl -u "$SERVICE_NAME" -n 20 >> "$LOG_FILE"
    fi
else
    echo "$(date): Service is running correctly" >> "$LOG_FILE"
fi
EOF

chmod +x "$BOT_DIR/check_service.sh"

# Add to crontab to run every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /root/mybot/check_service.sh") | crontab -

# Add a daily restart to prevent memory leaks (4 AM)
(crontab -l 2>/dev/null; echo "0 4 * * * systemctl restart binancebot") | crontab -

echo "======================================"
echo "Setup completed!"
echo ""
echo "Starting the service now..."
systemctl start "$SERVICE_NAME"
systemctl status "$SERVICE_NAME"
echo ""
echo "Useful commands:"
echo "- Check bot status: systemctl status $SERVICE_NAME"
echo "- View logs: journalctl -u $SERVICE_NAME -f"
echo "- View debug logs: cat $BOT_DIR/logs/bot_service.log"
echo "- Run in debug mode: cd $BOT_DIR && ./debug.sh"
echo "- Restart bot: systemctl restart $SERVICE_NAME"
echo "======================================"