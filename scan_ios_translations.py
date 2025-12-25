#!/usr/bin/env python3
"""
Scan iOS Swift files for localization calls and extract translation keys.
Generates JSON inventory of all views and their translation keys.
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict
from datetime import datetime

# Configuration
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
IOS_PROJECT_PATH = os.path.join(PROJECT_ROOT, "Client/IOS/Nice Traders/Nice Traders")
OUTPUT_FILE = os.path.join(PROJECT_ROOT, "ios_translation_inventory.json")

# Regex patterns for finding localization calls
PATTERNS = [
    r'localizationManager\.localize\("([^"]+)"\)',  # localizationManager.localize("KEY")
    r'localize\("([^"]+)"\)',                         # localize("KEY") - shorthand
    r'LocalizationManager\.shared\.localize\("([^"]+)"\)',  # Full path
]

def extract_view_name_from_path(file_path):
    """Extract view name from file path"""
    basename = os.path.basename(file_path)
    # Remove .swift extension
    view_name = basename.replace('.swift', '')
    return view_name

def scan_swift_file(file_path):
    """Scan a single Swift file for localization keys"""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return set()
    
    keys = set()
    for pattern in PATTERNS:
        matches = re.findall(pattern, content)
        keys.update(matches)
    
    return keys

def scan_ios_project():
    """Scan entire iOS project for translation keys"""
    views = {}
    
    print(f"Scanning iOS project at: {IOS_PROJECT_PATH}")
    
    for root, dirs, files in os.walk(IOS_PROJECT_PATH):
        # Skip build directories and Pods
        dirs[:] = [d for d in dirs if d not in ['Pods', 'build', '.git', '.swiftpm']]
        
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                view_name = extract_view_name_from_path(file_path)
                
                keys = scan_swift_file(file_path)
                
                if keys:  # Only include if it has translation keys
                    # Get relative path for display
                    rel_path = os.path.relpath(file_path, IOS_PROJECT_PATH)
                    
                    views[view_name] = {
                        "viewId": view_name,
                        "viewType": "iOS",
                        "viewPath": rel_path,
                        "translationKeys": sorted(list(keys)),
                        "keyCount": len(keys)
                    }
                    print(f"  ✓ {view_name}: {len(keys)} keys")
    
    return views

def main():
    print("=" * 60)
    print("iOS Translation Scanner")
    print("=" * 60)
    
    ios_views = scan_ios_project()
    
    print(f"\n✓ Found {len(ios_views)} iOS views with translations")
    
    # Save to JSON
    output = {
        "platform": "iOS",
        "scanDate": datetime.now().isoformat(),
        "viewCount": len(ios_views),
        "totalKeys": sum(v['keyCount'] for v in ios_views.values()),
        "views": ios_views
    }
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ Saved to: {OUTPUT_FILE}")
    print(f"\n📊 Summary:")
    print(f"   Views: {output['viewCount']}")
    print(f"   Total unique keys: {output['totalKeys']}")
    print(f"   Scan date: {output['scanDate']}")

if __name__ == "__main__":
    main()
