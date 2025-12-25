#!/usr/bin/env python3
"""
Create comprehensive translation inventory by combining:
1. iOS views and their translation keys (from iOS scanner output)
2. All translations from database for all languages

Output: Single JSON file with complete inventory for the localization editor
"""

import json
import pymysql
from datetime import datetime

IOS_INVENTORY_FILE = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/ios_translation_inventory.json"
DB_HOST = 'localhost'
DB_USER = 'stevenelson'
DB_PASSWORD = 'mwitcitw711'
DB_NAME = 'nicetraders'
OUTPUT_FILE = "/Users/stevenelson/Documents/GitHub/NiceTradersApp/translation_inventory.json"

def load_ios_inventory():
    """Load the iOS inventory from scanner output"""
    with open(IOS_INVENTORY_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def get_database_translations():
    """Get all translations from database"""
    db = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    
    # Get all translations
    cursor.execute("""
        SELECT translation_key, language_code, translation_value, updated_at
        FROM translations
        ORDER BY translation_key, language_code
    """)
    
    rows = cursor.fetchall()
    cursor.close()
    db.close()
    
    # Organize by key, then by language
    translations = {}
    for row in rows:
        key = row['translation_key']
        if key not in translations:
            translations[key] = {}
        translations[key][row['language_code']] = {
            'value': row['translation_value'],
            'lastModified': row['updated_at'].isoformat() if row['updated_at'] else None
        }
    
    return translations

def get_supported_languages():
    """Get list of all supported languages"""
    db = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    
    cursor.execute("SELECT DISTINCT language_code FROM translations ORDER BY language_code")
    results = cursor.fetchall()
    cursor.close()
    db.close()
    
    return [row['language_code'] for row in results]

def build_inventory():
    """Build comprehensive inventory"""
    print("=" * 70)
    print("Building Comprehensive Translation Inventory")
    print("=" * 70)
    
    print("\n1. Loading iOS views inventory...")
    ios_data = load_ios_inventory()
    ios_views = ios_data['views']
    print(f"   ✓ Loaded {len(ios_views)} iOS views")
    
    print("\n2. Loading database translations...")
    db_translations = get_database_translations()
    print(f"   ✓ Loaded {len(db_translations)} translation keys from database")
    
    print("\n3. Getting supported languages...")
    languages = get_supported_languages()
    print(f"   ✓ Found {len(languages)} languages: {', '.join(languages)}")
    
    print("\n4. Building view → keys mapping...")
    # Map each translation key to the views that use it
    key_to_views = {}
    for view_id, view_data in ios_views.items():
        for key in view_data['translationKeys']:
            if key not in key_to_views:
                key_to_views[key] = []
            key_to_views[key].append({
                'viewId': view_id,
                'viewType': 'iOS',
                'viewPath': view_data['viewPath']
            })
    
    print(f"   ✓ Mapped keys to views")
    
    print("\n5. Building complete key inventory...")
    keys_inventory = []
    
    for key in sorted(db_translations.keys()):
        key_data = db_translations[key]
        
        # Get English value (primary)
        english_value = key_data.get('en', {}).get('value', '(NOT TRANSLATED)')
        
        # Get all language translations
        translations_by_lang = {}
        for lang in languages:
            if lang in key_data:
                translations_by_lang[lang] = {
                    'value': key_data[lang]['value'],
                    'lastModified': key_data[lang]['lastModified']
                }
            else:
                translations_by_lang[lang] = {
                    'value': None,
                    'lastModified': None,
                    'missing': True
                }
        
        # Find which views use this key
        used_in_views = key_to_views.get(key, [])
        
        keys_inventory.append({
            'key': key,
            'englishValue': english_value,
            'usedInViews': used_in_views,
            'usageCount': len(used_in_views),
            'translations': translations_by_lang
        })
    
    print(f"   ✓ Built inventory for {len(keys_inventory)} keys")
    
    # Check for orphaned keys (in database but not used in any view)
    orphaned_keys = [k['key'] for k in keys_inventory if k['usageCount'] == 0]
    
    # Build final output
    inventory = {
        'generatedAt': datetime.now().isoformat(),
        'statistics': {
            'totalKeys': len(keys_inventory),
            'iosViews': len(ios_views),
            'supportedLanguages': len(languages),
            'languageCodes': languages,
            'orphanedKeys': len(orphaned_keys),
            'missingTranslations': sum(
                sum(1 for lang_data in k['translations'].values() if lang_data.get('missing'))
                for k in keys_inventory
            )
        },
        'languages': languages,
        'iosViews': ios_views,
        'keys': keys_inventory,
        'orphanedKeys': orphaned_keys
    }
    
    # Save to file
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(inventory, f, indent=2, ensure_ascii=False)
    
    print(f"\n✓ Saved comprehensive inventory to: {OUTPUT_FILE}")
    
    # Print summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"Total translation keys: {inventory['statistics']['totalKeys']}")
    print(f"iOS views with translations: {inventory['statistics']['iosViews']}")
    print(f"Supported languages: {inventory['statistics']['supportedLanguages']}")
    print(f"Language codes: {', '.join(languages)}")
    print(f"Orphaned keys (not used in any view): {inventory['statistics']['orphanedKeys']}")
    print(f"Missing translations: {inventory['statistics']['missingTranslations']}")
    
    if orphaned_keys:
        print(f"\nOrphaned keys (first 10):")
        for key in orphaned_keys[:10]:
            print(f"  - {key}")

if __name__ == "__main__":
    build_inventory()
