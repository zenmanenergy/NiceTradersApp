#!/bin/bash

# Sync Fallback Translations Script
# Syncs hardcoded fallback translations from iOS to database
# Works on both Mac and Ubuntu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Sync Fallback Translations${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Try to find and activate virtual environment in Server directory
VENV_PATH=""

# Check common locations in Server directory
if [ -d "$SCRIPT_DIR/.venv" ]; then
    VENV_PATH="$SCRIPT_DIR/.venv"
elif [ -d "$SCRIPT_DIR/venv" ]; then
    VENV_PATH="$SCRIPT_DIR/venv"
fi

if [ -z "$VENV_PATH" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    echo -e "${YELLOW}Checked locations:${NC}"
    echo "  - $SCRIPT_DIR/.venv"
    echo "  - $SCRIPT_DIR/venv"
    echo ""
    echo -e "${YELLOW}Please create a virtual environment:${NC}"
    echo "  cd $SCRIPT_DIR"
    echo "  python3 -m venv venv"
    exit 1
fi

echo -e "${YELLOW}Using virtual environment: $VENV_PATH${NC}"
echo -e "${YELLOW}Activating virtual environment...${NC}"
source "$VENV_PATH/bin/activate"

# Run the sync script
echo ""
python sync_fallback_translations.py

# Deactivate venv
deactivate
