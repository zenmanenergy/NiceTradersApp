#!/usr/bin/env python3
"""
Migration script to add MEETING_LOCATION_PLACEHOLDER translation key
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

TRANSLATION_KEYS = {
    "MEETING_LOCATION_PLACEHOLDER": "e.g., Starbucks on 5th Street",
}

LANGUAGE_TRANSLATIONS = {
    "es": {
        "MEETING_LOCATION_PLACEHOLDER": "p. ej., Starbucks en la calle 5",
    },
    "fr": {
        "MEETING_LOCATION_PLACEHOLDER": "p. ex., Starbucks sur la 5e Avenue",
    },
    "de": {
        "MEETING_LOCATION_PLACEHOLDER": "z. B., Starbucks in der 5. Straße",
    },
    "pt": {
        "MEETING_LOCATION_PLACEHOLDER": "p. ex., Starbucks na 5ª Avenida",
    },
    "ja": {
        "MEETING_LOCATION_PLACEHOLDER": "例）5番街のスターバックス",
    },
    "zh": {
        "MEETING_LOCATION_PLACEHOLDER": "例如：第五大街的星巴克",
    },
    "ru": {
        "MEETING_LOCATION_PLACEHOLDER": "например, Starbucks на 5-й улице",
    },
    "ar": {
        "MEETING_LOCATION_PLACEHOLDER": "مثلاً: ستاربكس بشارع الخمسة",
    },
    "hi": {
        "MEETING_LOCATION_PLACEHOLDER": "उदाहरण के लिए: 5वीं सड़क पर स्टारबक्स",
    },
    "sk": {
        "MEETING_LOCATION_PLACEHOLDER": "napr. Starbucks na 5. ulici",
    },
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("=== MEETING LOCATION PLACEHOLDER KEY MIGRATION ===\n")
        
        # English
        english_count = 0
        for key, value in TRANSLATION_KEYS.items():
            cursor.execute("""
                INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (key, 'en', value, datetime.now(), datetime.now()))
            if cursor.rowcount > 0:
                print(f"✅ Inserted {key}: {value}")
                english_count += 1
        connection.commit()
        print(f"\n✅ English: {english_count} keys inserted\n")
        
        # Other languages
        language_results = {}
        for lang, translations in LANGUAGE_TRANSLATIONS.items():
            inserted_count = 0
            for key, value in translations.items():
                cursor.execute("""
                    INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (key, lang, value, datetime.now(), datetime.now()))
                if cursor.rowcount > 0:
                    inserted_count += 1
                    print(f"✅ Inserted {key} ({lang}): {value}")
            connection.commit()
            language_results[lang] = inserted_count
            if inserted_count > 0:
                print(f"✅ {lang}: {inserted_count} keys inserted\n")
        
        print("✅ Migration completed!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    sys.exit(main())
