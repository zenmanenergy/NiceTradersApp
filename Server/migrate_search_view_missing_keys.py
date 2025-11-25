#!/usr/bin/env python3
"""
Migration script to add missing SearchView translation keys
Adds 4 missing translation keys for SearchView.swift localization
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

# Translation keys and their English values
TRANSLATION_KEYS = {
    "WHAT_CURRENCY_HAVE": "What currency do you have?",
    "WHAT_CURRENCY_WANT": "What currency do you want?",
    "HOW_FAR_TRAVEL": "How far are you willing to travel?",
    "ONE_HUNDRED_MILES": "100 miles",
}

# Language translations
LANGUAGE_TRANSLATIONS = {
    "es": {
        "WHAT_CURRENCY_HAVE": "¿Qué moneda tienes?",
        "WHAT_CURRENCY_WANT": "¿Qué moneda quieres?",
        "HOW_FAR_TRAVEL": "¿Qué tan lejos estás dispuesto a viajar?",
        "ONE_HUNDRED_MILES": "100 millas",
    },
    "fr": {
        "WHAT_CURRENCY_HAVE": "Quelle devise avez-vous?",
        "WHAT_CURRENCY_WANT": "Quelle devise voulez-vous?",
        "HOW_FAR_TRAVEL": "Jusqu'où êtes-vous prêt à voyager?",
        "ONE_HUNDRED_MILES": "100 miles",
    },
    "de": {
        "WHAT_CURRENCY_HAVE": "Welche Währung haben Sie?",
        "WHAT_CURRENCY_WANT": "Welche Währung möchten Sie?",
        "HOW_FAR_TRAVEL": "Wie weit sind Sie bereit zu reisen?",
        "ONE_HUNDRED_MILES": "100 Meilen",
    },
    "pt": {
        "WHAT_CURRENCY_HAVE": "Que moeda você tem?",
        "WHAT_CURRENCY_WANT": "Que moeda você quer?",
        "HOW_FAR_TRAVEL": "Até que distância você está disposto a viajar?",
        "ONE_HUNDRED_MILES": "100 milhas",
    },
    "ja": {
        "WHAT_CURRENCY_HAVE": "どの通貨を持っていますか？",
        "WHAT_CURRENCY_WANT": "どの通貨が欲しいですか？",
        "HOW_FAR_TRAVEL": "どのくらい遠くまで旅行する意思がありますか？",
        "ONE_HUNDRED_MILES": "100マイル",
    },
    "zh": {
        "WHAT_CURRENCY_HAVE": "您有什么货币？",
        "WHAT_CURRENCY_WANT": "您想要什么货币？",
        "HOW_FAR_TRAVEL": "您愿意旅行多远？",
        "ONE_HUNDRED_MILES": "100英里",
    },
    "ru": {
        "WHAT_CURRENCY_HAVE": "Какая у вас валюта?",
        "WHAT_CURRENCY_WANT": "Какую валюту вы хотите?",
        "HOW_FAR_TRAVEL": "Как далеко вы готовы путешествовать?",
        "ONE_HUNDRED_MILES": "100 миль",
    },
    "ar": {
        "WHAT_CURRENCY_HAVE": "ما العملة التي لديك؟",
        "WHAT_CURRENCY_WANT": "ما العملة التي تريدها؟",
        "HOW_FAR_TRAVEL": "إلى أي مدى أنت على استعداد للسفر؟",
        "ONE_HUNDRED_MILES": "100 ميل",
    },
    "hi": {
        "WHAT_CURRENCY_HAVE": "आपके पास कौन सी मुद्रा है?",
        "WHAT_CURRENCY_WANT": "आप कौन सी मुद्रा चाहते हैं?",
        "HOW_FAR_TRAVEL": "आप कितनी दूर यात्रा करने के लिए तैयार हैं?",
        "ONE_HUNDRED_MILES": "100 मील",
    },
    "sk": {
        "WHAT_CURRENCY_HAVE": "Akú menu máte?",
        "WHAT_CURRENCY_WANT": "Akú menu chcete?",
        "HOW_FAR_TRAVEL": "Ako ďaleko ste ochotní cestovať?",
        "ONE_HUNDRED_MILES": "100 míľ",
    },
    "en": {
        # English defaults to the TRANSLATION_KEYS dict values above
    }
}

def main():
    """Execute migration"""
    print("🔄 Starting SearchView missing translation keys migration...\n")
    
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Get English translations first
        english_count = 0
        for key, english_value in TRANSLATION_KEYS.items():
            cursor.execute("""
                INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (key, 'en', english_value, datetime.now(), datetime.now()))
            
            if cursor.rowcount > 0:
                print(f"✅ Inserted {key}: {english_value}")
                english_count += 1
        
        connection.commit()
        print(f"\n✅ English: {english_count} keys inserted\n")
        
        # Insert translations for all other languages
        language_results = {}
        for language_code, translations in LANGUAGE_TRANSLATIONS.items():
            if language_code == 'en':
                continue
            
            inserted_count = 0
            for key, value in translations.items():
                cursor.execute("""
                    INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (key, language_code, value, datetime.now(), datetime.now()))
                
                if cursor.rowcount > 0:
                    inserted_count += 1
                    print(f"✅ Inserted {key} ({language_code}): {value}")
            
            connection.commit()
            language_results[language_code] = inserted_count
            if inserted_count > 0:
                print(f"✅ {language_code}: {inserted_count} keys inserted\n")
        
        # Print summary
        print("\n" + "="*60)
        print("✅ Migration completed successfully!")
        print("="*60)
        print(f"\nSummary:")
        for lang, count in sorted(language_results.items()):
            if count > 0:
                print(f"  {lang}: {count} keys")
        
    except Exception as e:
        print(f"❌ Error during migration: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
