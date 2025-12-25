#!/usr/bin/env python3
"""Translate new keys using Google Cloud Translate"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
import pymysql.cursors
import os
from google.cloud import translate_v3

# Database connection
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)

cursor = db.cursor()

# New keys to translate
new_keys = [
    'ACCEPT', 'ACCEPTING', 'AGREED', 'ALL_PERMISSIONS_GRANTED', 
    'BACK_TO_MESSAGES', 'BOTH_PERMISSIONS_REQUIRED', 'LOCATION_ACCESS',
    'LOCATION_ACCESS_DESC', 'LOCATION_DETECTION_FAILED', 'LOCATION_PROPOSAL_SENT',
    'MEETING', 'MY_NEGOTIATIONS', 'NOTE', 'NO_ACTIVE_NEGOTIATIONS',
    'PERMISSION_DENIED', 'PUSH_NOTIFICATIONS_DESC', 'REQUIRED_PERMISSIONS',
    'REQUIRED_PERMISSIONS_DESC', 'TRANSACTION_HISTORY'
]

target_languages = ['ja', 'es', 'fr', 'de', 'ar', 'hi', 'pt', 'ru', 'sk', 'zh']

# Initialize Google Translate
translate_client = translate_v3.TranslationServiceClient()
project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'nicetraders')
parent = f"projects/{project_id}/locations/global"

print("🌐 Translating new keys using Google Cloud Translate...\n")

total_added = 0

for key in new_keys:
    # Get English value
    cursor.execute(
        "SELECT translation_value FROM translations WHERE translation_key = %s AND language_code = 'en'",
        (key,)
    )
    result = cursor.fetchone()
    
    if not result:
        print(f"⏭️  Skipped {key} (no English value)")
        continue
    
    english_text = result['translation_value']
    print(f"\n📝 Translating {key}: '{english_text}'")
    
    for lang_code in target_languages:
        try:
            response = translate_client.translate_text(
                request={
                    "parent": parent,
                    "contents": [english_text],
                    "mime_type": "text/plain",
                    "source_language_code": "en",
                    "target_language_code": lang_code,
                }
            )
            
            translated_text = response.translations[0].translated_text
            
            cursor.execute(
                "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s",
                (key, lang_code, translated_text, translated_text)
            )
            
            print(f"  ✅ {lang_code}: {translated_text}")
            total_added += 1
            
        except Exception as e:
            print(f"  ❌ {lang_code}: {str(e)}")

db.commit()

# Get final count
cursor.execute("SELECT COUNT(*) as total FROM translations")
total = cursor.fetchone()['total']

db.close()

print(f"\n{'='*60}")
print(f"✅ Translation complete!")
print(f"   Total translations added: {total_added}")
print(f"   Total translations in database: {total}")
print(f"{'='*60}")
