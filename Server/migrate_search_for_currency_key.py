#!/usr/bin/env python3
"""
Migration script to add SEARCHING_FOR_CURRENCY key
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

TRANSLATION_KEYS = {
    "SEARCHING_FOR_CURRENCY": "Searching for currency listings...",
}

LANGUAGE_TRANSLATIONS = {
    "es": {"SEARCHING_FOR_CURRENCY": "Buscando listados de moneda..."},
    "fr": {"SEARCHING_FOR_CURRENCY": "Recherche de listes de devises..."},
    "de": {"SEARCHING_FOR_CURRENCY": "Suche nach Währungsangeboten..."},
    "pt": {"SEARCHING_FOR_CURRENCY": "Procurando listagens de moeda..."},
    "ja": {"SEARCHING_FOR_CURRENCY": "通貨リストを検索中..."},
    "zh": {"SEARCHING_FOR_CURRENCY": "正在搜索货币列表..."},
    "ru": {"SEARCHING_FOR_CURRENCY": "Поиск предложений валют..."},
    "ar": {"SEARCHING_FOR_CURRENCY": "البحث عن قوائم العملات..."},
    "hi": {"SEARCHING_FOR_CURRENCY": "मुद्रा लिस्टिंग खोज रहे हैं..."},
    "sk": {"SEARCHING_FOR_CURRENCY": "Hľadanie listín mien..."},
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # English
        cursor.execute("""
            INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s)
        """, ('SEARCHING_FOR_CURRENCY', 'en', 'Searching for currency listings...', datetime.now(), datetime.now()))
        connection.commit()
        print("✅ English: SEARCHING_FOR_CURRENCY")
        
        # Other languages
        for lang, translations in LANGUAGE_TRANSLATIONS.items():
            cursor.execute("""
                INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
            """, ('SEARCHING_FOR_CURRENCY', lang, translations['SEARCHING_FOR_CURRENCY'], datetime.now(), datetime.now()))
            connection.commit()
            print(f"✅ {lang}: SEARCHING_FOR_CURRENCY")
        
        print("\n✅ Migration completed!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    sys.exit(main())
