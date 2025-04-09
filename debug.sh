#!/bin/bash
# Debug script for Binance trading bot

# Create logs directory if it doesn't exist
mkdir -p logs

# Run the bot with verbose output and capture all errors
echo "Starting bot in debug mode at $(date)" > logs/debug_run.log
echo "-------------------------------------" >> logs/debug_run.log

# Check if Python is installed
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
    echo "Using Python 3: $(which python3)" >> logs/debug_run.log
    $PYTHON_CMD -V >> logs/debug_run.log
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
    echo "Using Python: $(which python)" >> logs/debug_run.log
    $PYTHON_CMD -V >> logs/debug_run.log
else
    echo "ERROR: Python not found! Please install Python 3" >> logs/debug_run.log
    echo "Try running: apt-get update && apt-get install -y python3 python3-pip python3-venv" >> logs/debug_run.log
    echo "ERROR: Python not found! Please install Python 3"
    echo "Try running: apt-get update && apt-get install -y python3 python3-pip python3-venv"
    exit 1
fi

# Install pip if not already available
echo "Checking for pip..." >> logs/debug_run.log
if ! command -v pip3 &>/dev/null && ! command -v pip &>/dev/null; then
    echo "Installing pip..." >> logs/debug_run.log
    apt-get update -y && apt-get install -y python3-pip
fi

# Determine pip command to use
if command -v pip3 &>/dev/null; then
    PIP_CMD="pip3"
elif command -v pip &>/dev/null; then
    PIP_CMD="pip"
else
    echo "ERROR: pip not found even after installation attempt!" >> logs/debug_run.log
    echo "ERROR: pip not found even after installation attempt!"
    exit 1
fi

echo "Using pip: $(which $PIP_CMD)" >> logs/debug_run.log

# If using virtual environment
if [ -d "venv" ]; then
    echo "Virtual environment found, activating..." >> logs/debug_run.log
    source venv/bin/activate
    echo "Using virtual environment" >> logs/debug_run.log
    which $PYTHON_CMD >> logs/debug_run.log
    $PYTHON_CMD -V >> logs/debug_run.log
    PIP_CMD="pip"  # In activated venv, we use pip directly
else
    echo "No virtual environment found, creating one..." >> logs/debug_run.log
    $PYTHON_CMD -m venv venv
    source venv/bin/activate
    PIP_CMD="pip"  # In activated venv, we use pip directly
    echo "Virtual environment created and activated" >> logs/debug_run.log
fi

# Install required packages
echo "Installing required packages..." >> logs/debug_run.log
$PIP_CMD install --upgrade pip
$PIP_CMD install -r requirements.txt
echo "Package installation completed" >> logs/debug_run.log

# List installed packages for debugging
echo "Installed packages:" >> logs/debug_run.log
$PIP_CMD list >> logs/debug_run.log

# Run with full traceback
echo "Running main.py with --small-account flag" >> logs/debug_run.log
$PYTHON_CMD -u main.py --small-account 2>&1 | tee -a logs/debug_run.log

# Save exit code
EXIT_CODE=$?
echo "Exit code: $EXIT_CODE" >> logs/debug_run.log
echo "-------------------------------------" >> logs/debug_run.log

# Deactivate virtual environment if we activated it
if [ -n "$VIRTUAL_ENV" ]; then
    deactivate
fi

exit $EXIT_CODE