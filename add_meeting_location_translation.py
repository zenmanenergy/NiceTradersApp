#!/usr/bin/env python3
import pymysql
import sys

# Database connection details
db_config = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders'
}

# New translations to add
new_translations = [
    # MEETING_LOCATION_REQUIRED translations
    ("MEETING_LOCATION_REQUIRED", "en", "Meeting location required"),
    ("MEETING_LOCATION_REQUIRED", "ja", "会議場所が必要"),
    ("MEETING_LOCATION_REQUIRED", "es", "Ubicación de reunión requerida"),
    ("MEETING_LOCATION_REQUIRED", "fr", "Lieu de réunion requis"),
    ("MEETING_LOCATION_REQUIRED", "de", "Treffpunkt erforderlich"),
    ("MEETING_LOCATION_REQUIRED", "ar", "موقع الاجتماع مطلوب"),
    ("MEETING_LOCATION_REQUIRED", "hi", "बैठक स्थान आवश्यक"),
    ("MEETING_LOCATION_REQUIRED", "pt", "Local da reunião obrigatório"),
    ("MEETING_LOCATION_REQUIRED", "ru", "Требуется место встречи"),
    ("MEETING_LOCATION_REQUIRED", "sk", "Vyžaduje sa miesto stretnutia"),
    ("MEETING_LOCATION_REQUIRED", "zh", "需要会议地点"),
]

try:
    # Connect to database
    db = pymysql.connect(**db_config)
    cursor = db.cursor()
    
    print("Adding translations to database...")
    
    added_count = 0
    for key, lang, value in new_translations:
        try:
            # Use INSERT ... ON DUPLICATE KEY UPDATE to handle existing entries
            cursor.execute(
                "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s",
                (key, lang, value, value)
            )
            added_count += 1
            print(f"✓ Added/Updated: {key} ({lang})")
        except Exception as e:
            print(f"✗ Error adding {key} ({lang}): {e}")
    
    db.commit()
    cursor.close()
    db.close()
    
    print(f"\n✅ Successfully added/updated {added_count} translations")
    
except pymysql.Error as e:
    print(f"Database error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
