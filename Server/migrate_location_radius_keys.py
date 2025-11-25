#!/usr/bin/env python3
"""
Migrate Location Radius Options Keys to Database
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
LOCATION_RADIUS_KEYS = {
    "WITHIN_1_MILE": "Within 1 mile",
    "WITHIN_3_MILES": "Within 3 miles",
    "WITHIN_5_MILES": "Within 5 miles",
    "WITHIN_10_MILES": "Within 10 miles",
    "WITHIN_25_MILES": "Within 25 miles",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {
        "WITHIN_1_MILE": "Dentro de 1 milla",
        "WITHIN_3_MILES": "Dentro de 3 millas",
        "WITHIN_5_MILES": "Dentro de 5 millas",
        "WITHIN_10_MILES": "Dentro de 10 millas",
        "WITHIN_25_MILES": "Dentro de 25 millas",
    },
    "fr": {
        "WITHIN_1_MILE": "À moins d'1 km",
        "WITHIN_3_MILES": "À moins de 5 km",
        "WITHIN_5_MILES": "À moins de 8 km",
        "WITHIN_10_MILES": "À moins de 16 km",
        "WITHIN_25_MILES": "À moins de 40 km",
    },
    "de": {
        "WITHIN_1_MILE": "Innerhalb von 1 Meile",
        "WITHIN_3_MILES": "Innerhalb von 3 Meilen",
        "WITHIN_5_MILES": "Innerhalb von 5 Meilen",
        "WITHIN_10_MILES": "Innerhalb von 10 Meilen",
        "WITHIN_25_MILES": "Innerhalb von 25 Meilen",
    },
    "pt": {
        "WITHIN_1_MILE": "Dentro de 1 milha",
        "WITHIN_3_MILES": "Dentro de 3 milhas",
        "WITHIN_5_MILES": "Dentro de 5 milhas",
        "WITHIN_10_MILES": "Dentro de 10 milhas",
        "WITHIN_25_MILES": "Dentro de 25 milhas",
    },
    "ja": {
        "WITHIN_1_MILE": "1マイル以内",
        "WITHIN_3_MILES": "3マイル以内",
        "WITHIN_5_MILES": "5マイル以内",
        "WITHIN_10_MILES": "10マイル以内",
        "WITHIN_25_MILES": "25マイル以内",
    },
    "zh": {
        "WITHIN_1_MILE": "1英里以内",
        "WITHIN_3_MILES": "3英里以内",
        "WITHIN_5_MILES": "5英里以内",
        "WITHIN_10_MILES": "10英里以内",
        "WITHIN_25_MILES": "25英里以内",
    },
    "ru": {
        "WITHIN_1_MILE": "В пределах 1 мили",
        "WITHIN_3_MILES": "В пределах 3 миль",
        "WITHIN_5_MILES": "В пределах 5 миль",
        "WITHIN_10_MILES": "В пределах 10 миль",
        "WITHIN_25_MILES": "В пределах 25 миль",
    },
    "ar": {
        "WITHIN_1_MILE": "في حدود 1 ميل",
        "WITHIN_3_MILES": "في حدود 3 أميال",
        "WITHIN_5_MILES": "في حدود 5 أميال",
        "WITHIN_10_MILES": "في حدود 10 أميال",
        "WITHIN_25_MILES": "في حدود 25 ميل",
    },
    "hi": {
        "WITHIN_1_MILE": "1 मील के भीतर",
        "WITHIN_3_MILES": "3 मील के भीतर",
        "WITHIN_5_MILES": "5 मील के भीतर",
        "WITHIN_10_MILES": "10 मील के भीतर",
        "WITHIN_25_MILES": "25 मील के भीतर",
    },
    "sk": {
        "WITHIN_1_MILE": "V rámci 1 míly",
        "WITHIN_3_MILES": "V rámci 3 míľ",
        "WITHIN_5_MILES": "V rámci 5 míľ",
        "WITHIN_10_MILES": "V rámci 10 míľ",
        "WITHIN_25_MILES": "V rámci 25 míľ",
    },
}


def migrate():
    """Insert or update location radius keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Insert English translations first
        print("📝 Inserting English translations...")
        for key, value in LOCATION_RADIUS_KEYS.items():
            check_query = "SELECT id FROM translations WHERE translation_key = %s AND language_code = 'en'"
            cursor.execute(check_query, (key,))
            result = cursor.fetchone()
            
            if result:
                update_query = "UPDATE translations SET translation_value = %s, updated_at = NOW() WHERE translation_key = %s AND language_code = 'en'"
                cursor.execute(update_query, (value, key))
                print(f"  ✏️  Updated: {key}")
            else:
                insert_query = "INSERT INTO translations (translation_key, translation_value, language_code, created_at, updated_at) VALUES (%s, %s, 'en', NOW(), NOW())"
                cursor.execute(insert_query, (key, value))
                print(f"  ✅ Inserted: {key}")
        
        connection.commit()
        
        # Insert translations for other languages
        for language_code, translations in TRANSLATIONS.items():
            print(f"\n📝 Inserting {language_code.upper()} translations...")
            for key, value in translations.items():
                check_query = "SELECT id FROM translations WHERE translation_key = %s AND language_code = %s"
                cursor.execute(check_query, (key, language_code))
                result = cursor.fetchone()
                
                if result:
                    update_query = "UPDATE translations SET translation_value = %s, updated_at = NOW() WHERE translation_key = %s AND language_code = %s"
                    cursor.execute(update_query, (value, key, language_code))
                    print(f"  ✏️  Updated: {key}")
                else:
                    insert_query = "INSERT INTO translations (translation_key, translation_value, language_code, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW())"
                    cursor.execute(insert_query, (key, value, language_code))
                    print(f"  ✅ Inserted: {key}")
            
            connection.commit()
        
        print("\n✅ Migration completed successfully!")
        return True
        
    except Exception as e:
        connection.rollback()
        print(f"\n❌ Error during migration: {str(e)}")
        return False
    finally:
        connection.close()


if __name__ == "__main__":
    success = migrate()
    sys.exit(0 if success else 1)
