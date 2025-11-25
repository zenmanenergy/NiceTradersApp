#!/usr/bin/env python3
"""
Migrate Messages View Keys to Database
Inserts translation keys for the Messages view
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
MESSAGES_KEYS = {
    "MESSAGES": "Messages",
    "NO_CONVERSATIONS_YET": "No Conversations Yet",
    "PURCHASE_CONTACT_TO_START_CHATTING": "Purchase contact access to start chatting with traders",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {  # Spanish
        "MESSAGES": "Mensajes",
        "NO_CONVERSATIONS_YET": "Sin Conversaciones Aún",
        "PURCHASE_CONTACT_TO_START_CHATTING": "Compra acceso de contacto para comenzar a chatear con comerciantes",
    },
    "fr": {  # French
        "MESSAGES": "Messages",
        "NO_CONVERSATIONS_YET": "Aucune Conversation Encore",
        "PURCHASE_CONTACT_TO_START_CHATTING": "Achetez l'accès aux contacts pour commencer à discuter avec les commerçants",
    },
    "de": {  # German
        "MESSAGES": "Nachrichten",
        "NO_CONVERSATIONS_YET": "Noch Keine Konversationen",
        "PURCHASE_CONTACT_TO_START_CHATTING": "Kaufen Sie Kontaktzugang, um mit Händlern zu chatten",
    },
    "pt": {  # Portuguese
        "MESSAGES": "Mensagens",
        "NO_CONVERSATIONS_YET": "Sem Conversas Ainda",
        "PURCHASE_CONTACT_TO_START_CHATTING": "Compre acesso de contato para começar a conversar com traders",
    },
    "ja": {  # Japanese
        "MESSAGES": "メッセージ",
        "NO_CONVERSATIONS_YET": "まだ会話がありません",
        "PURCHASE_CONTACT_TO_START_CHATTING": "トレーダーとのチャットを始めるには、連絡先アクセスを購入してください",
    },
    "zh": {  # Chinese
        "MESSAGES": "消息",
        "NO_CONVERSATIONS_YET": "还没有对话",
        "PURCHASE_CONTACT_TO_START_CHATTING": "购买联系人访问权限以与交易者开始聊天",
    },
    "ru": {  # Russian
        "MESSAGES": "Сообщения",
        "NO_CONVERSATIONS_YET": "Еще нет разговоров",
        "PURCHASE_CONTACT_TO_START_CHATTING": "Купите доступ к контактам, чтобы начать чат с трейдерами",
    },
    "ar": {  # Arabic
        "MESSAGES": "الرسائل",
        "NO_CONVERSATIONS_YET": "لا توجد محادثات حتى الآن",
        "PURCHASE_CONTACT_TO_START_CHATTING": "شراء الوصول إلى جهات الاتصال للبدء في الدردشة مع المتداولين",
    },
    "hi": {  # Hindi
        "MESSAGES": "संदेश",
        "NO_CONVERSATIONS_YET": "अभी तक कोई बातचीत नहीं",
        "PURCHASE_CONTACT_TO_START_CHATTING": "व्यापारियों के साथ चैट करना शुरू करने के लिए संपर्क एक्सेस खरीदें",
    },
    "sk": {  # Slovak
        "MESSAGES": "Správy",
        "NO_CONVERSATIONS_YET": "Zatiaľ Žiadne Konverzácie",
        "PURCHASE_CONTACT_TO_START_CHATTING": "Kúpte si prístup k kontaktom a začnite chát s obchodníkmi",
    },
}


def migrate():
    """Insert or update messages keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Insert English translations first
        print("📝 Inserting English translations...")
        for key, value in MESSAGES_KEYS.items():
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
