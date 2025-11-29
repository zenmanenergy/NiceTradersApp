#!/bin/bash

# Auto-Translate All Languages Script
# Runs auto_translate_missing.py for each language to translate i18n data
# Automatically confirms all translations without prompting

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Auto-Translate All Languages${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Navigate to project root and activate virtual environment
cd "$PROJECT_ROOT"

if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Virtual environment not found at $PROJECT_ROOT/.venv${NC}"
    exit 1
fi

echo -e "${YELLOW}Activating virtual environment...${NC}"
source .venv/bin/activate

# Check if googletrans is installed
python -c "import googletrans" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Installing googletrans-py...${NC}"
    pip install googletrans-py
    echo ""
fi

# Navigate to Server directory
cd Server

# Languages to translate (must match those in auto_translate_missing.py)
LANGUAGES=("ja" "es" "fr" "de" "ar" "hi" "pt" "ru" "sk" "zh")

echo -e "${BLUE}Starting auto-translation for all languages...${NC}"
echo ""

TOTAL_TRANSLATED=0

for LANG in "${LANGUAGES[@]}"; do
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Translating: $LANG${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Pipe "y" to auto-confirm the translation prompt
    echo "y" | python auto_translate_missing.py "$LANG"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully processed $LANG${NC}"
    else
        echo -e "${RED}❌ Error processing $LANG${NC}"
    fi
    
    echo ""
done

echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ Auto-translation complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Languages translated: ${#LANGUAGES[@]}"
echo "  ar (Arabic), de (German), es (Spanish), fr (French)"
echo "  hi (Hindi), ja (Japanese), pt (Portuguese), ru (Russian)"
echo "  sk (Slovak), zh (Chinese)"
echo ""

