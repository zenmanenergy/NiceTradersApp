#!/usr/bin/env python3
"""
Migrate Create Listing Keys to Database
Inserts translation keys for the Create Listing view (final step)
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
CREATE_LISTING_KEYS = {
    "CREATE_LISTING": "Create Listing",
    "PASO_3_DE_3": "Step 3 of 3",
    "REVIEW_YOUR_LISTING": "Review your listing",
    "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Make sure everything looks correct",
    "MARKET_RATE": "Market rate",
    "LOCATION_COLON": "Location:",
    "DETECTED": "Detected",
    "MEETING_COLON": "Meeting:",
    "PUBLIC_PLACES_ONLY": "Public places only",
    "AVAILABLE_UNTIL_COLON": "Available until:",
    "PREVIOUS": "Previous",
    "HOME": "Home",
    "SEARCH": "Search",
    "LISTING": "Listing",
    "MESSAGES": "Messages",
    "LOGOUT": "Logout",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {  # Spanish
        "CREATE_LISTING": "Crear Listado",
        "PASO_3_DE_3": "Paso 3 de 3",
        "REVIEW_YOUR_LISTING": "Revisa tu listado",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Asegúrate de que todo se vea correcto",
        "MARKET_RATE": "Tasa de mercado",
        "LOCATION_COLON": "Ubicación:",
        "DETECTED": "Detectado",
        "MEETING_COLON": "Encuentro:",
        "PUBLIC_PLACES_ONLY": "Solo lugares públicos",
        "AVAILABLE_UNTIL_COLON": "Disponible hasta:",
        "PREVIOUS": "Anterior",
        "HOME": "Inicio",
        "SEARCH": "Buscar",
        "LISTING": "Listar",
        "MESSAGES": "Mensajes",
        "LOGOUT": "Cerrar sesión",
    },
    "fr": {  # French
        "CREATE_LISTING": "Créer une annonce",
        "PASO_3_DE_3": "Étape 3 sur 3",
        "REVIEW_YOUR_LISTING": "Révisez votre annonce",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Assurez-vous que tout semble correct",
        "MARKET_RATE": "Taux du marché",
        "LOCATION_COLON": "Localisation:",
        "DETECTED": "Détecté",
        "MEETING_COLON": "Réunion:",
        "PUBLIC_PLACES_ONLY": "Lieux publics uniquement",
        "AVAILABLE_UNTIL_COLON": "Disponible jusqu'au:",
        "PREVIOUS": "Précédent",
        "HOME": "Accueil",
        "SEARCH": "Rechercher",
        "LISTING": "Annonce",
        "MESSAGES": "Messages",
        "LOGOUT": "Se déconnecter",
    },
    "de": {  # German
        "CREATE_LISTING": "Angebot erstellen",
        "PASO_3_DE_3": "Schritt 3 von 3",
        "REVIEW_YOUR_LISTING": "Überprüfen Sie Ihr Angebot",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Stellen Sie sicher, dass alles korrekt aussieht",
        "MARKET_RATE": "Marktkurs",
        "LOCATION_COLON": "Standort:",
        "DETECTED": "Erkannt",
        "MEETING_COLON": "Treffen:",
        "PUBLIC_PLACES_ONLY": "Nur öffentliche Plätze",
        "AVAILABLE_UNTIL_COLON": "Verfügbar bis:",
        "PREVIOUS": "Zurück",
        "HOME": "Startseite",
        "SEARCH": "Suchen",
        "LISTING": "Angebot",
        "MESSAGES": "Nachrichten",
        "LOGOUT": "Abmelden",
    },
    "pt": {  # Portuguese
        "CREATE_LISTING": "Criar Anúncio",
        "PASO_3_DE_3": "Passo 3 de 3",
        "REVIEW_YOUR_LISTING": "Revise seu anúncio",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Certifique-se de que tudo parece correto",
        "MARKET_RATE": "Taxa de mercado",
        "LOCATION_COLON": "Localização:",
        "DETECTED": "Detectado",
        "MEETING_COLON": "Encontro:",
        "PUBLIC_PLACES_ONLY": "Apenas lugares públicos",
        "AVAILABLE_UNTIL_COLON": "Disponível até:",
        "PREVIOUS": "Anterior",
        "HOME": "Início",
        "SEARCH": "Pesquisar",
        "LISTING": "Anúncio",
        "MESSAGES": "Mensagens",
        "LOGOUT": "Sair",
    },
    "ja": {  # Japanese
        "CREATE_LISTING": "リスティングを作成",
        "PASO_3_DE_3": "ステップ3の3",
        "REVIEW_YOUR_LISTING": "リスティングを確認",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "すべてが正しく見えることを確認してください",
        "MARKET_RATE": "市場レート",
        "LOCATION_COLON": "場所:",
        "DETECTED": "検出されました",
        "MEETING_COLON": "会議:",
        "PUBLIC_PLACES_ONLY": "公共の場所のみ",
        "AVAILABLE_UNTIL_COLON": "利用可能期限:",
        "PREVIOUS": "前へ",
        "HOME": "ホーム",
        "SEARCH": "検索",
        "LISTING": "リスティング",
        "MESSAGES": "メッセージ",
        "LOGOUT": "ログアウト",
    },
    "zh": {  # Chinese
        "CREATE_LISTING": "创建列表",
        "PASO_3_DE_3": "第3步，共3步",
        "REVIEW_YOUR_LISTING": "查看您的列表",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "确保一切看起来正确",
        "MARKET_RATE": "市场汇率",
        "LOCATION_COLON": "位置:",
        "DETECTED": "已检测到",
        "MEETING_COLON": "会议:",
        "PUBLIC_PLACES_ONLY": "仅公共场所",
        "AVAILABLE_UNTIL_COLON": "可用期限:",
        "PREVIOUS": "上一步",
        "HOME": "主页",
        "SEARCH": "搜索",
        "LISTING": "列表",
        "MESSAGES": "消息",
        "LOGOUT": "登出",
    },
    "ru": {  # Russian
        "CREATE_LISTING": "Создать объявление",
        "PASO_3_DE_3": "Шаг 3 из 3",
        "REVIEW_YOUR_LISTING": "Проверьте объявление",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Убедитесь, что все выглядит правильно",
        "MARKET_RATE": "Рыночный курс",
        "LOCATION_COLON": "Местоположение:",
        "DETECTED": "Обнаружено",
        "MEETING_COLON": "Встреча:",
        "PUBLIC_PLACES_ONLY": "Только общественные места",
        "AVAILABLE_UNTIL_COLON": "Доступно до:",
        "PREVIOUS": "Назад",
        "HOME": "Главная",
        "SEARCH": "Поиск",
        "LISTING": "Объявление",
        "MESSAGES": "Сообщения",
        "LOGOUT": "Выход",
    },
    "ar": {  # Arabic
        "CREATE_LISTING": "إنشاء إدراج",
        "PASO_3_DE_3": "الخطوة 3 من 3",
        "REVIEW_YOUR_LISTING": "راجع إدراجك",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "تأكد من أن كل شيء يبدو صحيحًا",
        "MARKET_RATE": "سعر السوق",
        "LOCATION_COLON": "الموقع:",
        "DETECTED": "تم اكتشافه",
        "MEETING_COLON": "الاجتماع:",
        "PUBLIC_PLACES_ONLY": "الأماكن العامة فقط",
        "AVAILABLE_UNTIL_COLON": "متاح حتى:",
        "PREVIOUS": "السابق",
        "HOME": "الصفحة الرئيسية",
        "SEARCH": "بحث",
        "LISTING": "الإدراج",
        "MESSAGES": "الرسائل",
        "LOGOUT": "تسجيل الخروج",
    },
    "hi": {  # Hindi
        "CREATE_LISTING": "सूची बनाएं",
        "PASO_3_DE_3": "चरण 3 का 3",
        "REVIEW_YOUR_LISTING": "अपनी सूची की समीक्षा करें",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "सुनिश्चित करें कि सब कुछ सही दिख रहा है",
        "MARKET_RATE": "बाजार दर",
        "LOCATION_COLON": "स्थान:",
        "DETECTED": "पहचाना गया",
        "MEETING_COLON": "बैठक:",
        "PUBLIC_PLACES_ONLY": "केवल सार्वजनिक स्थान",
        "AVAILABLE_UNTIL_COLON": "उपलब्ध तक:",
        "PREVIOUS": "पिछला",
        "HOME": "होम",
        "SEARCH": "खोज",
        "LISTING": "सूची",
        "MESSAGES": "संदेश",
        "LOGOUT": "लॉग आउट",
    },
    "sk": {  # Slovak
        "CREATE_LISTING": "Vytvoriť inzerát",
        "PASO_3_DE_3": "Krok 3 z 3",
        "REVIEW_YOUR_LISTING": "Skontrolujte svoj inzerát",
        "MAKE_SURE_EVERYTHING_LOOKS_CORRECT": "Ubezpečte sa, že všetko vyzerá správne",
        "MARKET_RATE": "Trhová sadzba",
        "LOCATION_COLON": "Poloha:",
        "DETECTED": "Zistené",
        "MEETING_COLON": "Stretnutie:",
        "PUBLIC_PLACES_ONLY": "Iba verejné miesta",
        "AVAILABLE_UNTIL_COLON": "Dostupné do:",
        "PREVIOUS": "Predchádzajúci",
        "HOME": "Domov",
        "SEARCH": "Hľadať",
        "LISTING": "Inzerát",
        "MESSAGES": "Správy",
        "LOGOUT": "Odhlásiť sa",
    },
}


def migrate():
    """Insert or update create listing keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Insert English translations first
        print("📝 Inserting English translations...")
        for key, value in CREATE_LISTING_KEYS.items():
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
