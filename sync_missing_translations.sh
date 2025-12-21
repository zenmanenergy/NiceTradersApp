#!/bin/bash

# Script to compare English translations with other languages and populate missing translations
# Optionally uses Google Translate API to auto-translate missing keys

set -e

cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server

# Run Python script to handle the translation sync
venv/bin/python3 << 'EOF'
import pymysql
import pymysql.cursors
import os
import sys

# Database connection
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)

# Supported languages
LANGUAGES = ['en', 'ja', 'es', 'fr', 'de', 'ar', 'hi', 'pt', 'ru', 'sk', 'zh']

# Try to initialize Google Translate client
HAS_GOOGLE = False
try:
    from google.cloud import translate_v3
    translate_client = translate_v3.TranslationServiceClient()
    project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'nicetraders')
    parent = f"projects/{project_id}/locations/global"
    HAS_GOOGLE = True
    print("✅ Google Translate API is configured\n")
except ImportError:
    print("⚠️  google-cloud-translate not installed")
    print("   Install with: pip install google-cloud-translate")
    print("   Continuing with manual entry mode...\n")
except Exception as e:
    print(f"⚠️  Google Translate API not available: {e}\n")

cursor = db.cursor()

# Get all English translation keys
cursor.execute(
    "SELECT DISTINCT translation_key FROM translations WHERE language_code = 'en' ORDER BY translation_key"
)
english_keys = [row['translation_key'] for row in cursor.fetchall()]

print(f"📊 Found {len(english_keys)} English translation keys")

# Check each language for missing translations
missing_count = 0
added_count = 0

for lang in LANGUAGES:
    if lang == 'en':
        continue
    
    print(f"\n🔍 Checking {lang.upper()}...")
    
    # Get existing translations for this language
    cursor.execute(
        "SELECT translation_key FROM translations WHERE language_code = %s",
        (lang,)
    )
    existing_keys = {row['translation_key'] for row in cursor.fetchall()}
    
    # Find missing keys
    missing_keys = set(english_keys) - existing_keys
    
    if not missing_keys:
        print(f"   ✅ {lang.upper()} has all translations")
        continue
    
    print(f"   ⚠️  Missing {len(missing_keys)} translations in {lang.upper()}")
    missing_count += len(missing_keys)
    
    # For each missing key, get English text and translate
    for key in sorted(missing_keys):
        cursor.execute(
            "SELECT translation_value FROM translations WHERE translation_key = %s AND language_code = 'en'",
            (key,)
        )
        result = cursor.fetchone()
        
        if not result:
            continue
        
        english_text = result['translation_value']
        translated_text = english_text
        
        # Try to use Google Translate API if available
        if HAS_GOOGLE:
            try:
                response = translate_client.translate_text(
                    request={
                        "parent": parent,
                        "contents": [english_text],
                        "mime_type": "text/plain",
                        "source_language_code": "en",
                        "target_language_code": lang,
                    }
                )
                translated_text = response.translations[0].translated_text
                source = "Google Translate"
            except Exception as e:
                print(f"   ❌ Error translating '{key}' to {lang}: {e}")
                print(f"      Using English as fallback")
                translated_text = english_text
                source = "Fallback (English)"
        else:
            source = "Manual (English)"
        
        # Insert into database
        try:
            cursor.execute(
                """INSERT INTO translations (translation_key, language_code, translation_value)
                   VALUES (%s, %s, %s)
                   ON DUPLICATE KEY UPDATE translation_value = %s""",
                (key, lang, translated_text, translated_text)
            )
            added_count += 1
            print(f"   ✓ {key} -> {lang.upper()} ({source})")
        except Exception as e:
            print(f"   ❌ Failed to insert {key} ({lang}): {e}")

# Commit all changes
db.commit()

print(f"\n" + "="*50)
print(f"✅ Sync Complete!")
print(f"   Missing translations found: {missing_count}")
print(f"   Translations added: {added_count}")
print(f"="*50)

cursor.close()
db.close()
EOF

echo "✨ Translation sync complete!"
