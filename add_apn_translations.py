#!/usr/bin/env python3
"""
Add all necessary APN notification translation keys to the database
"""
import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
import pymysql.cursors

# Database connection
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

# Translation keys and their values for all languages
translations = [
    # Push notifications disabled alert
    ("PUSH_NOTIFICATIONS_DISABLED", "en", "Push Notifications Disabled"),
    ("PUSH_NOTIFICATIONS_DISABLED", "ja", "プッシュ通知が無効です"),
    ("PUSH_NOTIFICATIONS_DISABLED", "es", "Notificaciones push deshabilitadas"),
    ("PUSH_NOTIFICATIONS_DISABLED", "fr", "Notifications push désactivées"),
    ("PUSH_NOTIFICATIONS_DISABLED", "de", "Push-Benachrichtigungen deaktiviert"),
    ("PUSH_NOTIFICATIONS_DISABLED", "ar", "تم تعطيل إشعارات الدفع"),
    ("PUSH_NOTIFICATIONS_DISABLED", "hi", "पुश सूचनाएं अक्षम हैं"),
    ("PUSH_NOTIFICATIONS_DISABLED", "pt", "Notificações por push desabilitadas"),
    ("PUSH_NOTIFICATIONS_DISABLED", "ru", "Push-уведомления отключены"),
    ("PUSH_NOTIFICATIONS_DISABLED", "sk", "Push notifikácie sú vypnuté"),
    ("PUSH_NOTIFICATIONS_DISABLED", "zh", "推送通知已禁用"),
    
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "en", "Push notifications are required for the app to function correctly. Please enable them in Settings."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "ja", "アプリが正常に機能するにはプッシュ通知が必要です。設定で有効にしてください。"),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "es", "Las notificaciones push son necesarias para que la aplicación funcione correctamente. Por favor habilítelas en Configuración."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "fr", "Les notifications push sont nécessaires pour que l'application fonctionne correctement. Veuillez les activer dans Paramètres."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "de", "Push-Benachrichtigungen sind erforderlich, damit die App korrekt funktioniert. Bitte aktivieren Sie sie in den Einstellungen."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "ar", "إشعارات الدفع مطلوبة لكي يعمل التطبيق بشكل صحيح. يرجى تفعيلها في الإعدادات."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "hi", "ऐप को सही तरीके से काम करने के लिए पुश सूचनाओं की आवश्यकता है। कृपया सेटिंग्स में उन्हें सक्षम करें।"),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "pt", "Notificações por push são necessárias para o aplicativo funcionar corretamente. Por favor, ative-as em Configurações."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "ru", "Push-уведомления необходимы для правильной работы приложения. Пожалуйста, включите их в Параметры."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "sk", "Push notifikácie sú potrebné na správne fungovanie aplikácie. Prosím aktivujte ich v Nastaveniach."),
    ("PUSH_NOTIFICATIONS_REQUIRED_MESSAGE", "zh", "推送通知是应用程序正常工作所必需的。请在设置中启用它们。"),
    
    # Location rejected
    ("LOCATION_REJECTED", "en", "Location Proposal Rejected"),
    ("LOCATION_REJECTED", "ja", "位置提案が却下されました"),
    ("LOCATION_REJECTED", "es", "Propuesta de ubicación rechazada"),
    ("LOCATION_REJECTED", "fr", "Proposition de lieu rejetée"),
    ("LOCATION_REJECTED", "de", "Standortvorschlag abgelehnt"),
    ("LOCATION_REJECTED", "ar", "تم رفض اقتراح الموقع"),
    ("LOCATION_REJECTED", "hi", "स्थान प्रस्ताव अस्वीकृत"),
    ("LOCATION_REJECTED", "pt", "Proposta de localização rejeitada"),
    ("LOCATION_REJECTED", "ru", "Предложение о местоположении отклонено"),
    ("LOCATION_REJECTED", "sk", "Návrh umiestnenia bol zamietnutý"),
    ("LOCATION_REJECTED", "zh", "位置提案被拒绝"),
    
    ("rejected_your_location_proposal", "en", "rejected your location proposal"),
    ("rejected_your_location_proposal", "ja", "あなたの位置提案を却下しました"),
    ("rejected_your_location_proposal", "es", "rechazó tu propuesta de ubicación"),
    ("rejected_your_location_proposal", "fr", "a rejeté votre proposition de lieu"),
    ("rejected_your_location_proposal", "de", "lehnte Ihren Standortvorschlag ab"),
    ("rejected_your_location_proposal", "ar", "رفضت اقتراح موقعك"),
    ("rejected_your_location_proposal", "hi", "ने आपके स्थान प्रस्ताव को अस्वीकार कर दिया"),
    ("rejected_your_location_proposal", "pt", "rejeitou sua proposta de localização"),
    ("rejected_your_location_proposal", "ru", "отклонил ваше предложение о местоположении"),
    ("rejected_your_location_proposal", "sk", "odmietnol váš návrh umiestnenia"),
    ("rejected_your_location_proposal", "zh", "拒绝了您的位置提案"),
    
    # Location proposed
    ("LOCATION_PROPOSED", "en", "New Location Proposed"),
    ("LOCATION_PROPOSED", "ja", "新しい位置が提案されました"),
    ("LOCATION_PROPOSED", "es", "Nueva ubicación propuesta"),
    ("LOCATION_PROPOSED", "fr", "Nouveau lieu proposé"),
    ("LOCATION_PROPOSED", "de", "Neuer Standort vorgeschlagen"),
    ("LOCATION_PROPOSED", "ar", "تم اقتراح موقع جديد"),
    ("LOCATION_PROPOSED", "hi", "नया स्थान प्रस्तावित"),
    ("LOCATION_PROPOSED", "pt", "Nova localização proposta"),
    ("LOCATION_PROPOSED", "ru", "Предложено новое местоположение"),
    ("LOCATION_PROPOSED", "sk", "Navrhnuté nové umiestnenie"),
    ("LOCATION_PROPOSED", "zh", "提议新位置"),
    
    ("proposed_new_meeting_location", "en", "proposed a new meeting location"),
    ("proposed_new_meeting_location", "ja", "新しい会議場所を提案しました"),
    ("proposed_new_meeting_location", "es", "propuso una nueva ubicación de reunión"),
    ("proposed_new_meeting_location", "fr", "a proposé un nouveau lieu de réunion"),
    ("proposed_new_meeting_location", "de", "schlug einen neuen Treffpunkt vor"),
    ("proposed_new_meeting_location", "ar", "اقترح موقع اجتماع جديد"),
    ("proposed_new_meeting_location", "hi", "ने एक नई बैठक का स्थान प्रस्तावित किया"),
    ("proposed_new_meeting_location", "pt", "propôs um novo local de reunião"),
    ("proposed_new_meeting_location", "ru", "предложил новое место встречи"),
    ("proposed_new_meeting_location", "sk", "navrhol nové miesto stretnutia"),
    ("proposed_new_meeting_location", "zh", "提议新的会议地点"),
    
    # Exchange marked complete
    ("EXCHANGE_MARKED_COMPLETE", "en", "Exchange Marked Complete"),
    ("EXCHANGE_MARKED_COMPLETE", "ja", "交換が完了としてマークされました"),
    ("EXCHANGE_MARKED_COMPLETE", "es", "Intercambio marcado como completado"),
    ("EXCHANGE_MARKED_COMPLETE", "fr", "Échange marqué comme complété"),
    ("EXCHANGE_MARKED_COMPLETE", "de", "Austausch als abgeschlossen markiert"),
    ("EXCHANGE_MARKED_COMPLETE", "ar", "تم وضع علامة على الصرف كمكتمل"),
    ("EXCHANGE_MARKED_COMPLETE", "hi", "विनिमय को पूर्ण के रूप में चिह्नित किया गया"),
    ("EXCHANGE_MARKED_COMPLETE", "pt", "Troca marcada como concluída"),
    ("EXCHANGE_MARKED_COMPLETE", "ru", "Обмен отмечен как завершенный"),
    ("EXCHANGE_MARKED_COMPLETE", "sk", "Výmena označená ako dokončená"),
    ("EXCHANGE_MARKED_COMPLETE", "zh", "交换标记为完成"),
]

# Insert translations
print("Adding APN notification translations...")
added = 0
updated = 0

for key, lang, value in translations:
    try:
        cursor.execute("""
            INSERT INTO translations (translation_key, language_code, translation_value)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE translation_value = %s
        """, (key, lang, value, value))
        
        if cursor.rowcount > 0:
            if cursor.lastrowid:
                added += 1
                print(f"✅ Added: {key} ({lang})")
            else:
                updated += 1
                print(f"🔄 Updated: {key} ({lang})")
    except Exception as e:
        print(f"❌ Error with {key} ({lang}): {e}")

db.commit()

print(f"\n✅ Done!")
print(f"   Added: {added}")
print(f"   Updated: {updated}")
print(f"   Total: {len(translations)}")

cursor.close()
db.close()
