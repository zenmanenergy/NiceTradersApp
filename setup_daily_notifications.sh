#!/bin/bash

# Setup script to configure daily notification task
# This schedules the daily reminders to run at 9 AM every day

echo "📅 Setting up daily notification cron job..."
echo "=============================================="
echo ""

# Get the absolute path to the Server directory
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/Server" && pwd )/run_daily_notifications.py"
PYTHON_BIN="$(cd "$(dirname "$0")/Server" && pwd)/venv/bin/python3"

# Create crontab entry
CRON_ENTRY="0 9 * * * $PYTHON_BIN $SCRIPT_PATH >> $(dirname "$0")/logs/daily_notifications.log 2>&1"

# Check if already in crontab
if crontab -l 2>/dev/null | grep -q "run_daily_notifications.py"; then
    echo "⚠️  Daily notification cron job already exists"
    echo ""
    echo "Current cron entries:"
    crontab -l 2>/dev/null | grep "run_daily_notifications"
else
    # Add to crontab
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "✅ Cron job installed successfully"
    echo ""
    echo "📋 Schedule: 9:00 AM daily"
    echo "🔧 Script: $SCRIPT_PATH"
    echo "📝 Logs: $(dirname "$0")/logs/daily_notifications.log"
    echo ""
    echo "To view/edit the cron job, run:"
    echo "  crontab -e"
    echo ""
    echo "To remove the cron job, run:"
    echo "  crontab -r"
fi

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$0")/logs"

echo ""
echo "=============================================="
echo "✅ Setup complete!"
