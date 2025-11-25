#!/usr/bin/env python3
"""
Migrate Search Currency Keys to Database
Inserts translation keys for the Search Currency view
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
SEARCH_CURRENCY_KEYS = {
    "SEARCH_CURRENCY": "Search Currency",
    "FIND_CURRENCY_EXCHANGE": "Find Currency Exchange",
    "WHAT_CURRENCY_DO_YOU_HAVE": "What currency do you have?",
    "SELECT_CURRENCY": "Select currency",
    "WHAT_CURRENCY_DO_YOU_WANT": "What currency do you want?",
    "HOW_FAR_WILLING_TO_TRAVEL": "How far are you willing to travel?",
    "SEARCH_LISTINGS": "Search",
    "RECENT_LISTINGS": "Recent Listings",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {  # Spanish
        "SEARCH_CURRENCY": "Buscar Moneda",
        "FIND_CURRENCY_EXCHANGE": "Encontrar Intercambio de Moneda",
        "WHAT_CURRENCY_DO_YOU_HAVE": "¿Qué moneda tienes?",
        "SELECT_CURRENCY": "Seleccionar moneda",
        "WHAT_CURRENCY_DO_YOU_WANT": "¿Qué moneda quieres?",
        "HOW_FAR_WILLING_TO_TRAVEL": "¿Qué tan lejos estás dispuesto a viajar?",
        "SEARCH_LISTINGS": "Buscar",
        "RECENT_LISTINGS": "Listados Recientes",
    },
    "fr": {  # French
        "SEARCH_CURRENCY": "Rechercher la devise",
        "FIND_CURRENCY_EXCHANGE": "Trouver un échange de devises",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Quelle devise avez-vous?",
        "SELECT_CURRENCY": "Sélectionner la devise",
        "WHAT_CURRENCY_DO_YOU_WANT": "Quelle devise voulez-vous?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Jusqu'où êtes-vous disposé à voyager?",
        "SEARCH_LISTINGS": "Rechercher",
        "RECENT_LISTINGS": "Annonces récentes",
    },
    "de": {  # German
        "SEARCH_CURRENCY": "Währung durchsuchen",
        "FIND_CURRENCY_EXCHANGE": "Währungswechsel finden",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Welche Währung haben Sie?",
        "SELECT_CURRENCY": "Währung auswählen",
        "WHAT_CURRENCY_DO_YOU_WANT": "Welche Währung möchten Sie?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Wie weit sind Sie bereit zu reisen?",
        "SEARCH_LISTINGS": "Suchen",
        "RECENT_LISTINGS": "Aktuelle Angebote",
    },
    "pt": {  # Portuguese
        "SEARCH_CURRENCY": "Pesquisar Moeda",
        "FIND_CURRENCY_EXCHANGE": "Encontrar Câmbio de Moeda",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Que moeda você tem?",
        "SELECT_CURRENCY": "Selecionar moeda",
        "WHAT_CURRENCY_DO_YOU_WANT": "Que moeda você quer?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Até que distância você está disposto a viajar?",
        "SEARCH_LISTINGS": "Pesquisar",
        "RECENT_LISTINGS": "Anúncios Recentes",
    },
    "ja": {  # Japanese
        "SEARCH_CURRENCY": "通貨を検索",
        "FIND_CURRENCY_EXCHANGE": "通貨交換を検索",
        "WHAT_CURRENCY_DO_YOU_HAVE": "どの通貨を持っていますか？",
        "SELECT_CURRENCY": "通貨を選択",
        "WHAT_CURRENCY_DO_YOU_WANT": "どの通貨が欲しいですか？",
        "HOW_FAR_WILLING_TO_TRAVEL": "どのくらい遠くまで旅行できますか？",
        "SEARCH_LISTINGS": "検索",
        "RECENT_LISTINGS": "最近のリスティング",
    },
    "zh": {  # Chinese
        "SEARCH_CURRENCY": "搜索货币",
        "FIND_CURRENCY_EXCHANGE": "找到货币交换",
        "WHAT_CURRENCY_DO_YOU_HAVE": "你有什么货币？",
        "SELECT_CURRENCY": "选择货币",
        "WHAT_CURRENCY_DO_YOU_WANT": "你想要什么货币？",
        "HOW_FAR_WILLING_TO_TRAVEL": "您愿意旅行多远？",
        "SEARCH_LISTINGS": "搜索",
        "RECENT_LISTINGS": "最近列表",
    },
    "ru": {  # Russian
        "SEARCH_CURRENCY": "Поиск валюты",
        "FIND_CURRENCY_EXCHANGE": "Найти обмен валюты",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Какая у вас валюта?",
        "SELECT_CURRENCY": "Выберите валюту",
        "WHAT_CURRENCY_DO_YOU_WANT": "Какую валюту вы хотите?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Как далеко вы готовы путешествовать?",
        "SEARCH_LISTINGS": "Поиск",
        "RECENT_LISTINGS": "Последние объявления",
    },
    "ar": {  # Arabic
        "SEARCH_CURRENCY": "البحث عن العملة",
        "FIND_CURRENCY_EXCHANGE": "البحث عن صرف العملات",
        "WHAT_CURRENCY_DO_YOU_HAVE": "ما العملة التي لديك؟",
        "SELECT_CURRENCY": "اختر العملة",
        "WHAT_CURRENCY_DO_YOU_WANT": "ما العملة التي تريدها؟",
        "HOW_FAR_WILLING_TO_TRAVEL": "إلى أي مدى أنت مستعد للسفر؟",
        "SEARCH_LISTINGS": "بحث",
        "RECENT_LISTINGS": "الإدراجات الأخيرة",
    },
    "hi": {  # Hindi
        "SEARCH_CURRENCY": "मुद्रा खोजें",
        "FIND_CURRENCY_EXCHANGE": "मुद्रा विनिमय खोजें",
        "WHAT_CURRENCY_DO_YOU_HAVE": "आपके पास कौन सी मुद्रा है?",
        "SELECT_CURRENCY": "मुद्रा चुनें",
        "WHAT_CURRENCY_DO_YOU_WANT": "आप कौन सी मुद्रा चाहते हैं?",
        "HOW_FAR_WILLING_TO_TRAVEL": "आप कितनी दूर यात्रा करने को तैयार हैं?",
        "SEARCH_LISTINGS": "खोजें",
        "RECENT_LISTINGS": "हाल ही की सूचियां",
    },
    "sk": {  # Slovak
        "SEARCH_CURRENCY": "Hľadať menu",
        "FIND_CURRENCY_EXCHANGE": "Nájsť výmenu mien",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Akú menu máte?",
        "SELECT_CURRENCY": "Vyberte menu",
        "WHAT_CURRENCY_DO_YOU_WANT": "Akú menu chcete?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Ako ďaleko ste ochotní cestovať?",
        "SEARCH_LISTINGS": "Hľadať",
        "RECENT_LISTINGS": "Nedávne inzeráty",
    },
}


def migrate():
    """Insert or update search currency keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Insert English translations first
        print("📝 Inserting English translations...")
        for key, value in SEARCH_CURRENCY_KEYS.items():
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
