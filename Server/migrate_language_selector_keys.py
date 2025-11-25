#!/usr/bin/env python3
"""
Migrate Language Selector Keys to Database
Inserts translation keys for the Language Selector view
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
import json
from datetime import datetime

# Translation keys and their English values
LANGUAGE_SELECTOR_KEYS = {
    "LANGUAGE": "Language",
    "CURRENT_LANGUAGE": "Current Language",
    "SELECT_LANGUAGE": "Select Language",
    "LANGUAGE_PREFERENCE_AUTO_SAVED": "Your language preference is automatically saved",
    "LANGUAGE_CHANGED_TO": "Language changed to",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {  # Spanish
        "LANGUAGE": "Idioma",
        "CURRENT_LANGUAGE": "Idioma Actual",
        "SELECT_LANGUAGE": "Seleccionar Idioma",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "Tu preferencia de idioma se guarda automáticamente",
        "LANGUAGE_CHANGED_TO": "Idioma cambiado a",
    },
    "fr": {  # French
        "LANGUAGE": "Langue",
        "CURRENT_LANGUAGE": "Langue actuelle",
        "SELECT_LANGUAGE": "Sélectionner la langue",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "Votre préférence de langue est automatiquement enregistrée",
        "LANGUAGE_CHANGED_TO": "Langue changée en",
    },
    "de": {  # German
        "LANGUAGE": "Sprache",
        "CURRENT_LANGUAGE": "Aktuelle Sprache",
        "SELECT_LANGUAGE": "Sprache auswählen",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "Ihre Spracheinstellung wird automatisch gespeichert",
        "LANGUAGE_CHANGED_TO": "Sprache geändert zu",
    },
    "pt": {  # Portuguese
        "LANGUAGE": "Idioma",
        "CURRENT_LANGUAGE": "Idioma Atual",
        "SELECT_LANGUAGE": "Selecionar Idioma",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "Sua preferência de idioma é salva automaticamente",
        "LANGUAGE_CHANGED_TO": "Idioma alterado para",
    },
    "ja": {  # Japanese
        "LANGUAGE": "言語",
        "CURRENT_LANGUAGE": "現在の言語",
        "SELECT_LANGUAGE": "言語を選択",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "言語設定は自動的に保存されます",
        "LANGUAGE_CHANGED_TO": "言語が次に変更されました",
    },
    "zh": {  # Chinese
        "LANGUAGE": "语言",
        "CURRENT_LANGUAGE": "当前语言",
        "SELECT_LANGUAGE": "选择语言",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "您的语言偏好设置会自动保存",
        "LANGUAGE_CHANGED_TO": "语言已更改为",
    },
    "ru": {  # Russian
        "LANGUAGE": "Язык",
        "CURRENT_LANGUAGE": "Текущий язык",
        "SELECT_LANGUAGE": "Выберите язык",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "Ваши языковые предпочтения автоматически сохраняются",
        "LANGUAGE_CHANGED_TO": "Язык изменен на",
    },
    "ar": {  # Arabic
        "LANGUAGE": "اللغة",
        "CURRENT_LANGUAGE": "اللغة الحالية",
        "SELECT_LANGUAGE": "اختر اللغة",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "يتم حفظ تفضيل اللغة الخاص بك تلقائياً",
        "LANGUAGE_CHANGED_TO": "تم تغيير اللغة إلى",
    },
    "hi": {  # Hindi
        "LANGUAGE": "भाषा",
        "CURRENT_LANGUAGE": "वर्तमान भाषा",
        "SELECT_LANGUAGE": "भाषा चुनें",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "आपकी भाषा पसंद स्वचालित रूप से सहेजी जाती है",
        "LANGUAGE_CHANGED_TO": "भाषा में बदल गई",
    },
    "sk": {  # Slovak
        "LANGUAGE": "Jazyk",
        "CURRENT_LANGUAGE": "Aktuálny jazyk",
        "SELECT_LANGUAGE": "Vyberte jazyk",
        "LANGUAGE_PREFERENCE_AUTO_SAVED": "Vaša jazyková preferencia sa automaticky uloží",
        "LANGUAGE_CHANGED_TO": "Jazyk zmenený na",
    },
}


def migrate():
    """Insert or update language selector keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Insert English translations first
        print("📝 Inserting English translations...")
        for key, value in LANGUAGE_SELECTOR_KEYS.items():
            # Check if key already exists
            check_query = """
                SELECT id FROM translations 
                WHERE translation_key = %s AND language_code = 'en'
            """
            cursor.execute(check_query, (key,))
            result = cursor.fetchone()
            
            if result:
                # Update existing
                update_query = """
                    UPDATE translations 
                    SET translation_value = %s, updated_at = NOW()
                    WHERE translation_key = %s AND language_code = 'en'
                """
                cursor.execute(update_query, (value, key))
                print(f"  ✏️  Updated: {key}")
            else:
                # Insert new
                insert_query = """
                    INSERT INTO translations 
                    (translation_key, translation_value, language_code, created_at, updated_at)
                    VALUES (%s, %s, 'en', NOW(), NOW())
                """
                cursor.execute(insert_query, (key, value))
                print(f"  ✅ Inserted: {key}")
        
        connection.commit()
        
        # Insert translations for other languages
        for language_code, translations in TRANSLATIONS.items():
            print(f"\n📝 Inserting {language_code.upper()} translations...")
            for key, value in translations.items():
                # Check if key already exists for this language
                check_query = """
                    SELECT id FROM translations 
                    WHERE translation_key = %s AND language_code = %s
                """
                cursor.execute(check_query, (key, language_code))
                result = cursor.fetchone()
                
                if result:
                    # Update existing
                    update_query = """
                        UPDATE translations 
                        SET translation_value = %s, updated_at = NOW()
                        WHERE translation_key = %s AND language_code = %s
                    """
                    cursor.execute(update_query, (value, key, language_code))
                    print(f"  ✏️  Updated: {key}")
                else:
                    # Insert new
                    insert_query = """
                        INSERT INTO translations 
                        (translation_key, translation_value, language_code, created_at, updated_at)
                        VALUES (%s, %s, %s, NOW(), NOW())
                    """
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
