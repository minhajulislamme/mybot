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

# If using virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "Using virtual environment" >> logs/debug_run.log
    which $PYTHON_CMD >> logs/debug_run.log
    $PYTHON_CMD -V >> logs/debug_run.log
fi

# Run with full traceback
echo "Running main.py with --small-account flag" >> logs/debug_run.log
$PYTHON_CMD -u main.py --small-account 2>&1 | tee -a logs/debug_run.log

# Save exit code
EXIT_CODE=$?
echo "Exit code: $EXIT_CODE" >> logs/debug_run.log
echo "-------------------------------------" >> logs/debug_run.log

# Deactivate virtual environment if we activated it
if [ -d "venv" ]; then
    deactivate
fi

exit $EXIT_CODE