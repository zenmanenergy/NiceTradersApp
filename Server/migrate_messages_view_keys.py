#!/usr/bin/env python3
"""
Migration script to add missing MessagesView translation keys
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

TRANSLATION_KEYS = {
    "LOADING_MESSAGES": "Loading messages...",
    "PURCHASE_CONTACT_ACCESS": "Purchase contact access to start chatting with traders",
    "NO_MESSAGES_YET": "No messages yet",
}

LANGUAGE_TRANSLATIONS = {
    "es": {
        "LOADING_MESSAGES": "Cargando mensajes...",
        "PURCHASE_CONTACT_ACCESS": "Compra acceso a contacto para comenzar a chatear con comerciantes",
        "NO_MESSAGES_YET": "Sin mensajes todavía",
    },
    "fr": {
        "LOADING_MESSAGES": "Chargement des messages...",
        "PURCHASE_CONTACT_ACCESS": "Achetez l'accès aux contacts pour commencer à discuter avec les commerçants",
        "NO_MESSAGES_YET": "Pas de messages pour le moment",
    },
    "de": {
        "LOADING_MESSAGES": "Nachrichten werden geladen...",
        "PURCHASE_CONTACT_ACCESS": "Kaufen Sie Kontaktzugriff, um mit Händlern zu chatten",
        "NO_MESSAGES_YET": "Noch keine Nachrichten",
    },
    "pt": {
        "LOADING_MESSAGES": "Carregando mensagens...",
        "PURCHASE_CONTACT_ACCESS": "Compre acesso a contato para começar a conversar com traders",
        "NO_MESSAGES_YET": "Sem mensagens ainda",
    },
    "ja": {
        "LOADING_MESSAGES": "メッセージを読み込み中...",
        "PURCHASE_CONTACT_ACCESS": "連絡先へのアクセスを購入してトレーダーとチャットを開始する",
        "NO_MESSAGES_YET": "メッセージなし",
    },
    "zh": {
        "LOADING_MESSAGES": "正在加载消息...",
        "PURCHASE_CONTACT_ACCESS": "购买联系人访问权限以开始与交易者聊天",
        "NO_MESSAGES_YET": "还没有消息",
    },
    "ru": {
        "LOADING_MESSAGES": "Загрузка сообщений...",
        "PURCHASE_CONTACT_ACCESS": "Купите доступ к контактам, чтобы начать чат с трейдерами",
        "NO_MESSAGES_YET": "Нет сообщений",
    },
    "ar": {
        "LOADING_MESSAGES": "جاري تحميل الرسائل...",
        "PURCHASE_CONTACT_ACCESS": "شراء إمكانية الوصول إلى جهات الاتصال لبدء الدردشة مع التجار",
        "NO_MESSAGES_YET": "لا توجد رسائل حتى الآن",
    },
    "hi": {
        "LOADING_MESSAGES": "संदेश लोड हो रहे हैं...",
        "PURCHASE_CONTACT_ACCESS": "व्यापारियों के साथ चैट करना शुरू करने के लिए संपर्क पहुंच खरीदें",
        "NO_MESSAGES_YET": "अभी कोई संदेश नहीं",
    },
    "sk": {
        "LOADING_MESSAGES": "Načítavanie správ...",
        "PURCHASE_CONTACT_ACCESS": "Kúpte si prístup ku kontaktom a začnite chatovať s obchodníkmi",
        "NO_MESSAGES_YET": "Zatiaľ žiadne správy",
    },
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
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
