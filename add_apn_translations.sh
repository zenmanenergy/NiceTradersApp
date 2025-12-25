#!/bin/bash

# Script to add APN notification translations to the database
# This adds all necessary translation keys for push notification messages

echo "🌍 Adding APN Notification Translations..."
echo "=========================================="

# Change to the Server directory
cd "$(dirname "$0")/Server"

# Run the Python script with the virtual environment
if [ -f "venv/bin/python3" ]; then
    venv/bin/python3 ../add_apn_translations.py
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Successfully added APN translations!"
        echo "   The following translation keys were added:"
        echo "   - PUSH_NOTIFICATIONS_DISABLED"
        echo "   - PUSH_NOTIFICATIONS_REQUIRED_MESSAGE"
        echo "   - LOCATION_REJECTED"
        echo "   - LOCATION_PROPOSED"
        echo "   - EXCHANGE_MARKED_COMPLETE"
        echo ""
        echo "All translations are available in 11 languages:"
        echo "   English (en), Japanese (ja), Spanish (es), French (fr),"
        echo "   German (de), Arabic (ar), Hindi (hi), Portuguese (pt),"
        echo "   Russian (ru), Slovak (sk), Chinese (zh)"
    else
        echo ""
        echo "❌ Error running translation script"
        exit 1
    fi
else
    echo "❌ Virtual environment not found at venv/bin/python3"
    exit 1
fi
