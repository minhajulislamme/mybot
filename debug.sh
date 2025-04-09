#!/bin/bash
# Debug script for Binance trading bot

# Create logs directory if it doesn't exist
mkdir -p logs

# Run the bot with verbose output and capture all errors
echo "Starting bot in debug mode at $(date)" > logs/debug_run.log
echo "-------------------------------------" >> logs/debug_run.log

# If using virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "Using virtual environment" >> logs/debug_run.log
    which python >> logs/debug_run.log
    python -V >> logs/debug_run.log
fi

# Run with full traceback
echo "Running main.py with --small-account flag" >> logs/debug_run.log
python -u main.py --small-account 2>&1 | tee -a logs/debug_run.log

# Save exit code
EXIT_CODE=$?
echo "Exit code: $EXIT_CODE" >> logs/debug_run.log
echo "-------------------------------------" >> logs/debug_run.log

# Deactivate virtual environment if we activated it
if [ -d "venv" ]; then
    deactivate
fi

exit $EXIT_CODE