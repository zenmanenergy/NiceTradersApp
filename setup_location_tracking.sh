#!/bin/bash

# Location Tracking System - Quick Setup Guide
# Run this script to complete location tracking setup

echo "🗺️  Nice Traders Location Tracking Setup"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Database Migration
echo -e "${BLUE}Step 1: Running database migration...${NC}"
cd "$(dirname "$0")/Server"

if command -v python3 &> /dev/null; then
    python3 migrate_location_tracking.py
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database migration successful${NC}"
    else
        echo -e "${YELLOW}✗ Database migration failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Python3 not found in PATH${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Verify LocationTrackingService.py${NC}"
if [ -f "Meeting/LocationTrackingService.py" ]; then
    echo -e "${GREEN}✓ LocationTrackingService.py found${NC}"
    echo "  - update_user_location()"
    echo "  - get_other_user_location()"
    echo "  - get_tracking_status()"
    echo "  - calculate_distance()"
else
    echo -e "${YELLOW}✗ LocationTrackingService.py not found${NC}"
fi

echo ""
echo -e "${BLUE}Step 3: Verify Meeting endpoints${NC}"
if grep -q "Location/Update" Meeting/Meeting.py; then
    echo -e "${GREEN}✓ Location endpoints added to Meeting.py${NC}"
    echo "  - POST /Meeting/Location/Update"
    echo "  - GET /Meeting/Location/Get"
    echo "  - GET /Meeting/Location/Status"
else
    echo -e "${YELLOW}✗ Location endpoints not found in Meeting.py${NC}"
fi

echo ""
cd - > /dev/null

echo -e "${BLUE}Step 4: Verify iOS Files${NC}"
IOS_PATH="Client/IOS/Nice\ Traders/Nice\ Traders"

if [ -f "$IOS_PATH/UserLocationManager.swift" ]; then
    echo -e "${GREEN}✓ UserLocationManager.swift found${NC}"
else
    echo -e "${YELLOW}✗ UserLocationManager.swift not found${NC}"
fi

if [ -f "$IOS_PATH/ExchangeMapView.swift" ]; then
    echo -e "${GREEN}✓ ExchangeMapView.swift found${NC}"
else
    echo -e "${YELLOW}✗ ExchangeMapView.swift not found${NC}"
fi

echo ""
echo -e "${BLUE}Step 5: Verify Localizations${NC}"
LANG_COUNT=$(find "$IOS_PATH" -name "Localizable.strings" | wc -l)
echo -e "${GREEN}✓ Found $LANG_COUNT localization files${NC}"

echo ""
echo "========================================"
echo -e "${GREEN}Setup verification complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. In Xcode: Add Maps capability to NiceTradersApp target"
echo "2. In Info.plist: Add NSLocationWhenInUseUsageDescription"
echo "3. Update RespondToMeeting.py to trigger location tracking"
echo "4. Link ExchangeMapView to meeting acceptance flow"
echo "5. Test with two devices/simulators in meeting scenario"
echo ""
echo "📍 See docs/LOCATION_TRACKING.md for full documentation"
