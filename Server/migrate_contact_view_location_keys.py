#!/usr/bin/env python3
"""
Migration script to add ContactView location/meeting translation keys
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

TRANSLATION_KEYS = {
    "MEETING_COORDINATION": "Meeting Coordination",
    "MEETING_AGREED": "✅ Meeting Agreed",
    "NO_MEETING_SCHEDULED": "⏳ No meeting scheduled yet",
    "PROPOSE_MEETING_DETAILS": "Propose Meeting Details",
    "DATE": "Date *",
    "TIME": "Time *",
    "OPTIONAL_MESSAGE": "Optional Message",
    "SEND_PROPOSAL": "Send Proposal",
    "GENERAL_AREA": "General Area",
    "SPECIFIC_MEETING_LOCATIONS": "Specific meeting locations should be agreed upon through proposals above.",
}

LANGUAGE_TRANSLATIONS = {
    "es": {
        "MEETING_COORDINATION": "Coordinación de Reunión",
        "MEETING_AGREED": "✅ Reunión Acordada",
        "NO_MEETING_SCHEDULED": "⏳ Sin reunión programada aún",
        "PROPOSE_MEETING_DETAILS": "Proponer Detalles de Reunión",
        "DATE": "Fecha *",
        "TIME": "Hora *",
        "OPTIONAL_MESSAGE": "Mensaje Opcional",
        "SEND_PROPOSAL": "Enviar Propuesta",
        "GENERAL_AREA": "Área General",
        "SPECIFIC_MEETING_LOCATIONS": "Las ubicaciones de reunión específicas deben acordarse a través de propuestas anteriores.",
    },
    "fr": {
        "MEETING_COORDINATION": "Coordination de Réunion",
        "MEETING_AGREED": "✅ Réunion Convenue",
        "NO_MEETING_SCHEDULED": "⏳ Aucune réunion programmée pour le moment",
        "PROPOSE_MEETING_DETAILS": "Proposer les Détails de la Réunion",
        "DATE": "Date *",
        "TIME": "Heure *",
        "OPTIONAL_MESSAGE": "Message Facultatif",
        "SEND_PROPOSAL": "Envoyer la Proposition",
        "GENERAL_AREA": "Zone Générale",
        "SPECIFIC_MEETING_LOCATIONS": "Les lieux de réunion spécifiques doivent être convenus à travers les propositions ci-dessus.",
    },
    "de": {
        "MEETING_COORDINATION": "Treffenkoordination",
        "MEETING_AGREED": "✅ Treffen Vereinbart",
        "NO_MEETING_SCHEDULED": "⏳ Noch kein Treffen geplant",
        "PROPOSE_MEETING_DETAILS": "Treffendetails Vorschlagen",
        "DATE": "Datum *",
        "TIME": "Zeit *",
        "OPTIONAL_MESSAGE": "Optionale Nachricht",
        "SEND_PROPOSAL": "Vorschlag Senden",
        "GENERAL_AREA": "Allgemeiner Bereich",
        "SPECIFIC_MEETING_LOCATIONS": "Spezifische Treffpunkte sollten durch die obigen Vorschläge vereinbart werden.",
    },
    "pt": {
        "MEETING_COORDINATION": "Coordenação da Reunião",
        "MEETING_AGREED": "✅ Reunião Acordada",
        "NO_MEETING_SCHEDULED": "⏳ Nenhuma reunião programada ainda",
        "PROPOSE_MEETING_DETAILS": "Propor Detalhes da Reunião",
        "DATE": "Data *",
        "TIME": "Hora *",
        "OPTIONAL_MESSAGE": "Mensagem Opcional",
        "SEND_PROPOSAL": "Enviar Proposta",
        "GENERAL_AREA": "Área Geral",
        "SPECIFIC_MEETING_LOCATIONS": "As localizações específicas da reunião devem ser acordadas através das propostas acima.",
    },
    "ja": {
        "MEETING_COORDINATION": "会議調整",
        "MEETING_AGREED": "✅ 会議が合意されました",
        "NO_MEETING_SCHEDULED": "⏳ まだ会議はスケジュールされていません",
        "PROPOSE_MEETING_DETAILS": "会議の詳細を提案する",
        "DATE": "日付 *",
        "TIME": "時間 *",
        "OPTIONAL_MESSAGE": "オプションメッセージ",
        "SEND_PROPOSAL": "提案を送信",
        "GENERAL_AREA": "一般エリア",
        "SPECIFIC_MEETING_LOCATIONS": "特定の会議場所は、上記の提案を通じて合意する必要があります。",
    },
    "zh": {
        "MEETING_COORDINATION": "会议协调",
        "MEETING_AGREED": "✅ 会议已同意",
        "NO_MEETING_SCHEDULED": "⏳ 尚未安排会议",
        "PROPOSE_MEETING_DETAILS": "提议会议详情",
        "DATE": "日期 *",
        "TIME": "时间 *",
        "OPTIONAL_MESSAGE": "可选消息",
        "SEND_PROPOSAL": "发送提议",
        "GENERAL_AREA": "一般区域",
        "SPECIFIC_MEETING_LOCATIONS": "应通过上述提议商定具体的会议地点。",
    },
    "ru": {
        "MEETING_COORDINATION": "Координация Встречи",
        "MEETING_AGREED": "✅ Встреча Согласована",
        "NO_MEETING_SCHEDULED": "⏳ Встреча еще не запланирована",
        "PROPOSE_MEETING_DETAILS": "Предложить Детали Встречи",
        "DATE": "Дата *",
        "TIME": "Время *",
        "OPTIONAL_MESSAGE": "Опциональное Сообщение",
        "SEND_PROPOSAL": "Отправить Предложение",
        "GENERAL_AREA": "Общая Площадь",
        "SPECIFIC_MEETING_LOCATIONS": "Конкретные места встреч должны быть согласованы посредством предложений выше.",
    },
    "ar": {
        "MEETING_COORDINATION": "تنسيق الاجتماع",
        "MEETING_AGREED": "✅ تم الاتفاق على الاجتماع",
        "NO_MEETING_SCHEDULED": "⏳ لم يتم جدولة أي اجتماع حتى الآن",
        "PROPOSE_MEETING_DETAILS": "اقترح تفاصيل الاجتماع",
        "DATE": "التاريخ *",
        "TIME": "الوقت *",
        "OPTIONAL_MESSAGE": "رسالة اختيارية",
        "SEND_PROPOSAL": "إرسال الاقتراح",
        "GENERAL_AREA": "المنطقة العامة",
        "SPECIFIC_MEETING_LOCATIONS": "يجب الاتفاق على مواقع الاجتماع المحددة من خلال الاقتراحات المذكورة أعلاه.",
    },
    "hi": {
        "MEETING_COORDINATION": "बैठक समन्वय",
        "MEETING_AGREED": "✅ बैठक सहमत",
        "NO_MEETING_SCHEDULED": "⏳ अभी तक कोई बैठक शेड्यूल नहीं की गई",
        "PROPOSE_MEETING_DETAILS": "बैठक विवरण का प्रस्ताव",
        "DATE": "तारीख *",
        "TIME": "समय *",
        "OPTIONAL_MESSAGE": "वैकल्पिक संदेश",
        "SEND_PROPOSAL": "प्रस्ताव भेजें",
        "GENERAL_AREA": "सामान्य क्षेत्र",
        "SPECIFIC_MEETING_LOCATIONS": "विशिष्ट बैठक स्थान ऊपर दिए गए प्रस्तावों के माध्यम से सहमत होने चाहिए।",
    },
    "sk": {
        "MEETING_COORDINATION": "Koordinácia Stretnutia",
        "MEETING_AGREED": "✅ Stretnutie Dohodnuté",
        "NO_MEETING_SCHEDULED": "⏳ Žiadne stretnutie zatiaľ nenaplánované",
        "PROPOSE_MEETING_DETAILS": "Navrhnúť Detaily Stretnutia",
        "DATE": "Dátum *",
        "TIME": "Čas *",
        "OPTIONAL_MESSAGE": "Voliteľná Správa",
        "SEND_PROPOSAL": "Poslať Návrh",
        "GENERAL_AREA": "Všeobecná Oblasť",
        "SPECIFIC_MEETING_LOCATIONS": "Konkrétne miesta stretnutí by mali byť dohodnuté prostredníctvom vyššie uvedených návrhov.",
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
                english_count += 1
                print(f"✅ Inserted {key}")
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
            connection.commit()
            language_results[lang] = inserted_count
            if inserted_count > 0:
                print(f"✅ {lang}: {inserted_count} keys inserted")
        
        print(f"\n✅ Migration completed!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    sys.exit(main())
