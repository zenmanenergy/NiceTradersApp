#!/usr/bin/env python3
"""
Fix all hardcoded paths in Python files by replacing absolute paths with relative path resolution
This allows scripts to work on any deployment without modification
"""

import os
import re
from pathlib import Path

# Define files to fix and their hardcoded paths
FILES_TO_FIX = [
    # Root directory Python files
    ("/Users/stevenelson/Documents/GitHub/NiceTradersApp/scan_ios_translations.py", [
        ('IOS_PROJECT_PATH = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders"',
         'PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))\nIOS_PROJECT_PATH = os.path.join(PROJECT_ROOT, "Client/IOS/Nice Traders/Nice Traders")'),
        ('OUTPUT_FILE = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/ios_translation_inventory.json"',
         'OUTPUT_FILE = os.path.join(PROJECT_ROOT, "ios_translation_inventory.json")'),
    ]),
    ("/Users/stevenelson/Documents/GitHub/NiceTradersApp/build_translation_inventory.py", [
        ('IOS_INVENTORY_FILE = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/ios_translation_inventory.json"',
         'PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))\nIOS_INVENTORY_FILE = os.path.join(PROJECT_ROOT, "ios_translation_inventory.json")'),
        ('OUTPUT_FILE = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/translation_inventory.json"',
         'OUTPUT_FILE = os.path.join(PROJECT_ROOT, "translation_inventory.json")'),
    ]),
    ("/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/migrate_localization_schema.py", [
        ('inventory_file = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/translation_inventory.json"',
         'script_dir = os.path.dirname(os.path.abspath(__file__))\nproject_root = os.path.dirname(script_dir)\ninventory_file = os.path.join(project_root, "translation_inventory.json")'),
    ]),
    ("/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/export_schema.py", [
        ('output_path = \'/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/database_schema.sql\'',
         'script_dir = os.path.dirname(os.path.abspath(__file__))\noutput_path = os.path.join(script_dir, "database_schema.sql")'),
    ]),
    ("/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/reorder_schema.py", [
        ('schema = read_schema(\'/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/database_schema.sql\')',
         'script_dir = os.path.dirname(os.path.abspath(__file__))\nschema = read_schema(os.path.join(script_dir, "database_schema.sql"))'),
        ('with open(\'/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/database_schema_ordered.sql\', \'w\') as f:',
         'with open(os.path.join(script_dir, "database_schema_ordered.sql"), \'w\') as f:'),
    ]),
]

def fix_file(filepath, replacements):
    """Fix hardcoded paths in a file"""
    print(f"\nProcessing: {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ⚠️  File not found: {filepath}")
        return False
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    for old_path, new_path in replacements:
        if old_path in content:
            content = content.replace(old_path, new_path)
            print(f"  ✓ Replaced hardcoded path")
        else:
            print(f"  ⚠️  Pattern not found: {old_path}")
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✅ File updated")
        return True
    else:
        print(f"  ℹ️  No changes made")
        return False

print("=" * 60)
print("Fixing Hardcoded Paths in Project")
print("=" * 60)

fixed_count = 0
for filepath, replacements in FILES_TO_FIX:
    if fix_file(filepath, replacements):
        fixed_count += 1

print("\n" + "=" * 60)
print(f"✅ Complete! Fixed {fixed_count} file(s)")
print("=" * 60)
