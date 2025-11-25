#!/usr/bin/env python3
"""
Migration script to add ContactView messaging translation keys
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

TRANSLATION_KEYS = {
    "NO_MESSAGES_YET_CONTACT": "No messages yet",
    "START_CONVERSATION": "Start the conversation!",
    "TYPE_MESSAGE": "Type your message...",
    "YOU_LABEL": "You",
}

LANGUAGE_TRANSLATIONS = {
    "es": {
        "NO_MESSAGES_YET_CONTACT": "Sin mensajes todavía",
        "START_CONVERSATION": "¡Comienza la conversación!",
        "TYPE_MESSAGE": "Escribe tu mensaje...",
        "YOU_LABEL": "Tú",
    },
    "fr": {
        "NO_MESSAGES_YET_CONTACT": "Pas de messages pour le moment",
        "START_CONVERSATION": "Commencez la conversation!",
        "TYPE_MESSAGE": "Tapez votre message...",
        "YOU_LABEL": "Vous",
    },
    "de": {
        "NO_MESSAGES_YET_CONTACT": "Noch keine Nachrichten",
        "START_CONVERSATION": "Starten Sie die Unterhaltung!",
        "TYPE_MESSAGE": "Geben Sie Ihre Nachricht ein...",
        "YOU_LABEL": "Du",
    },
    "pt": {
        "NO_MESSAGES_YET_CONTACT": "Sem mensagens ainda",
        "START_CONVERSATION": "Comece a conversa!",
        "TYPE_MESSAGE": "Digite sua mensagem...",
        "YOU_LABEL": "Você",
    },
    "ja": {
        "NO_MESSAGES_YET_CONTACT": "メッセージなし",
        "START_CONVERSATION": "会話を始めましょう！",
        "TYPE_MESSAGE": "メッセージを入力...",
        "YOU_LABEL": "あなた",
    },
    "zh": {
        "NO_MESSAGES_YET_CONTACT": "还没有消息",
        "START_CONVERSATION": "开始对话！",
        "TYPE_MESSAGE": "输入您的消息...",
        "YOU_LABEL": "你",
    },
    "ru": {
        "NO_MESSAGES_YET_CONTACT": "Нет сообщений",
        "START_CONVERSATION": "Начните разговор!",
        "TYPE_MESSAGE": "Введите ваше сообщение...",
        "YOU_LABEL": "Вы",
    },
    "ar": {
        "NO_MESSAGES_YET_CONTACT": "لا توجد رسائل حتى الآن",
        "START_CONVERSATION": "ابدأ المحادثة!",
        "TYPE_MESSAGE": "اكتب رسالتك...",
        "YOU_LABEL": "أنت",
    },
    "hi": {
        "NO_MESSAGES_YET_CONTACT": "अभी कोई संदेश नहीं",
        "START_CONVERSATION": "बातचीत शुरू करें!",
        "TYPE_MESSAGE": "अपना संदेश टाइप करें...",
        "YOU_LABEL": "आप",
    },
    "sk": {
        "NO_MESSAGES_YET_CONTACT": "Zatiaľ žiadne správy",
        "START_CONVERSATION": "Začnite rozhovor!",
        "TYPE_MESSAGE": "Napíšte správu...",
        "YOU_LABEL": "Vy",
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
