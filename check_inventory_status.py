#!/usr/bin/env python3
"""
Test the inventory endpoint and check status
"""
import os
import sys

# Check if inventory file exists
project_root = os.path.dirname(os.path.abspath(__file__))
inventory_file = os.path.join(project_root, 'translation_inventory.json')

print("=" * 60)
print("Inventory File Status Check")
print("=" * 60)
print(f"Project root: {project_root}")
print(f"Inventory file path: {inventory_file}")
print(f"File exists: {os.path.exists(inventory_file)}")

if os.path.exists(inventory_file):
    stat = os.stat(inventory_file)
    print(f"File size: {stat.st_size:,} bytes")
    print(f"File is readable: {os.access(inventory_file, os.R_OK)}")
    print(f"File modified: {stat.st_mtime}")
    
    # Try to load it
    import json
    try:
        with open(inventory_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"\n✅ File is valid JSON")
        print(f"   Views: {len(data.get('iosViews', {}))}")
        print(f"   Total keys: {data.get('statistics', {}).get('totalKeys', 'N/A')}")
        print(f"   Languages: {len(data.get('languages', []))}")
    except Exception as e:
        print(f"\n❌ Error loading JSON: {e}")
else:
    print(f"\n❌ File NOT found!")
    print(f"\nChecking parent directories:")
    for i in range(5):
        check_dir = os.path.dirname(os.path.abspath(__file__))
        for _ in range(i):
            check_dir = os.path.dirname(check_dir)
        print(f"  {check_dir}")
        if os.path.exists(os.path.join(check_dir, 'translation_inventory.json')):
            print(f"    ✅ Found inventory here!")

print("\n" + "=" * 60)
