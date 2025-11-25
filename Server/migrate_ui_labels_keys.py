#!/usr/bin/env python3
"""
Migration script to add high-priority UI label localization keys across all views.
Focus: ExchangeRatesView, SearchView, ContactDetailView, ProfileView, ListingMapView
"""

import sys
from datetime import datetime

sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Define all strings to add with translations for all 11 languages
UI_LABELS_STRINGS = {
    # ExchangeRatesView (10 strings)
    "EXCHANGE_RATES": {
        "en": "Exchange Rates",
        "es": "Tasas de Cambio",
        "fr": "Taux de Change",
        "de": "Wechselkurse",
        "pt": "Taxas de Câmbio",
        "ja": "為替レート",
        "zh": "汇率",
        "ru": "Обменные курсы",
        "ar": "أسعار الصرف",
        "hi": "विनिमय दरें",
        "sk": "Výmenné kurzy"
    },
    "CURRENCY_CONVERTER": {
        "en": "Currency Converter",
        "es": "Convertidor de Divisas",
        "fr": "Convertisseur de Devises",
        "de": "Währungsumrechner",
        "pt": "Conversor de Moedas",
        "ja": "通貨換算機",
        "zh": "货币转换器",
        "ru": "Конвертер валют",
        "ar": "محول العملات",
        "hi": "मुद्रा परिवर्तक",
        "sk": "Prevodník mien"
    },
    "AMOUNT": {
        "en": "Amount",
        "es": "Cantidad",
        "fr": "Montant",
        "de": "Betrag",
        "pt": "Valor",
        "ja": "金額",
        "zh": "金额",
        "ru": "Сумма",
        "ar": "المبلغ",
        "hi": "राशि",
        "sk": "Suma"
    },
    "FROM": {
        "en": "From",
        "es": "De",
        "fr": "De",
        "de": "Von",
        "pt": "De",
        "ja": "から",
        "zh": "从",
        "ru": "От",
        "ar": "من",
        "hi": "से",
        "sk": "Od"
    },
    "TO": {
        "en": "To",
        "es": "Para",
        "fr": "À",
        "de": "Zu",
        "pt": "Para",
        "ja": "へ",
        "zh": "到",
        "ru": "К",
        "ar": "إلى",
        "hi": "को",
        "sk": "Do"
    },
    "CONVERT": {
        "en": "Convert",
        "es": "Convertir",
        "fr": "Convertir",
        "de": "Konvertieren",
        "pt": "Converter",
        "ja": "変換",
        "zh": "转换",
        "ru": "Конвертировать",
        "ar": "تحويل",
        "hi": "परिवर्तित करें",
        "sk": "Konvertovať"
    },
    "RESULT": {
        "en": "Result",
        "es": "Resultado",
        "fr": "Résultat",
        "de": "Ergebnis",
        "pt": "Resultado",
        "ja": "結果",
        "zh": "结果",
        "ru": "Результат",
        "ar": "النتيجة",
        "hi": "परिणाम",
        "sk": "Výsledok"
    },
    "CURRENT_RATES": {
        "en": "Current Rates",
        "es": "Tasas Actuales",
        "fr": "Taux Actuels",
        "de": "Aktuelle Sätze",
        "pt": "Taxas Atuais",
        "ja": "現在のレート",
        "zh": "当前汇率",
        "ru": "Текущие курсы",
        "ar": "الأسعار الحالية",
        "hi": "वर्तमान दरें",
        "sk": "Aktuálne sadzby"
    },
    "NO_RATES_AVAILABLE": {
        "en": "No rates available",
        "es": "Sin tasas disponibles",
        "fr": "Aucune tarif disponible",
        "de": "Keine Sätze verfügbar",
        "pt": "Sem taxas disponíveis",
        "ja": "利用可能なレートはありません",
        "zh": "没有可用的汇率",
        "ru": "Нет доступных курсов",
        "ar": "لا توجد أسعار متاحة",
        "hi": "कोई दरें उपलब्ध नहीं",
        "sk": "Žiadne dostupné sadzby"
    },
    "TAP_REFRESH_RATES": {
        "en": "Tap refresh to load exchange rates",
        "es": "Toca actualizar para cargar las tasas de cambio",
        "fr": "Appuyez sur actualiser pour charger les taux de change",
        "de": "Tippen Sie auf Aktualisieren, um Wechselkurse zu laden",
        "pt": "Toque em atualizar para carregar as taxas de câmbio",
        "ja": "更新をタップして為替レートを読み込みます",
        "zh": "点击刷新加载汇率",
        "ru": "Нажмите обновить, чтобы загрузить обменные курсы",
        "ar": "اضغط على تحديث لتحميل أسعار الصرف",
        "hi": "विनिमय दरें लोड करने के लिए रिफ्रेश टैप करें",
        "sk": "Klepnutím na aktualizovať načítajte výmenné kurzy"
    },
    
    # SearchView (8 strings)
    "SEARCH_CURRENCY": {
        "en": "Search Currency",
        "es": "Buscar Moneda",
        "fr": "Rechercher une Devise",
        "de": "Währung Suchen",
        "pt": "Pesquisar Moeda",
        "ja": "通貨を検索",
        "zh": "搜索货币",
        "ru": "Поиск валюты",
        "ar": "البحث عن عملة",
        "hi": "मुद्रा खोजें",
        "sk": "Hľadať menu"
    },
    "SELECT_CURRENCY": {
        "en": "Select currency",
        "es": "Seleccionar moneda",
        "fr": "Sélectionner une devise",
        "de": "Währung wählen",
        "pt": "Selecionar moeda",
        "ja": "通貨を選択",
        "zh": "选择货币",
        "ru": "Выберите валюту",
        "ar": "اختر العملة",
        "hi": "मुद्रा चुनें",
        "sk": "Vyberte menu"
    },
    "TRY_ADJUSTING_SEARCH": {
        "en": "Try adjusting your search or check back later for new listings.",
        "es": "Intenta ajustar tu búsqueda o regresa más tarde para nuevos anuncios.",
        "fr": "Essayez d'ajuster votre recherche ou revenez plus tard pour de nouvelles annonces.",
        "de": "Versuchen Sie, Ihre Suche anzupassen, oder überprüfen Sie später neue Inserate.",
        "pt": "Tente ajustar sua pesquisa ou volte mais tarde para novos anúncios.",
        "ja": "検索を調整するか、後で戻って新しいリストを確認してください。",
        "zh": "尝试调整您的搜索或稍后回来查看新列表。",
        "ru": "Попробуйте отрегулировать поиск или вернитесь позже для новых объявлений.",
        "ar": "حاول تعديل البحث الخاص بك أو العودة لاحقًا للإعلانات الجديدة.",
        "hi": "अपनी खोज को समायोजित करने का प्रयास करें या नई सूचियों के लिए बाद में वापस आएं।",
        "sk": "Skúste upraviť vyhľadávanie alebo sa vráťte neskôr na nové zoznamy."
    },
    "MEETING_LABEL": {
        "en": "Meeting:",
        "es": "Reunión:",
        "fr": "Réunion:",
        "de": "Treffen:",
        "pt": "Reunião:",
        "ja": "会議:",
        "zh": "会议:",
        "ru": "Встреча:",
        "ar": "الاجتماع:",
        "hi": "बैठक:",
        "sk": "Schôdza:"
    },
    "AVAILABLE_UNTIL": {
        "en": "Available until:",
        "es": "Disponible hasta:",
        "fr": "Disponible jusqu'au:",
        "de": "Verfügbar bis:",
        "pt": "Disponível até:",
        "ja": "利用可能な期間:",
        "zh": "可用至:",
        "ru": "Доступно до:",
        "ar": "متاح حتى:",
        "hi": "तक उपलब्ध:",
        "sk": "Dostupné do:"
    },
    "CONTACT_TRADER": {
        "en": "Contact Trader",
        "es": "Contactar Comerciante",
        "fr": "Contacter le Commerçant",
        "de": "Kontakt Händler",
        "pt": "Contate o Comerciante",
        "ja": "トレーダーに連絡",
        "zh": "联系交易者",
        "ru": "Связаться с трейдером",
        "ar": "الاتصال بالتاجر",
        "hi": "व्यापारी से संपर्क करें",
        "sk": "Kontaktovať obchodníka"
    },
    
    # ContactDetailView (10 strings)
    "EXCHANGE_DETAILS": {
        "en": "Exchange Details",
        "es": "Detalles del Cambio",
        "fr": "Détails de l'Échange",
        "de": "Austauschdetails",
        "pt": "Detalhes da Troca",
        "ja": "交換の詳細",
        "zh": "交换详情",
        "ru": "Детали обмена",
        "ar": "تفاصيل التبادل",
        "hi": "विनिमय विवरण",
        "sk": "Podrobnosti výmeny"
    },
    "TRADER_INFORMATION": {
        "en": "Trader Information",
        "es": "Información del Comerciante",
        "fr": "Informations du Commerçant",
        "de": "Händlerinformationen",
        "pt": "Informações do Comerciante",
        "ja": "トレーダー情報",
        "zh": "交易者信息",
        "ru": "Информация торговца",
        "ar": "معلومات التاجر",
        "hi": "व्यापारी की जानकारी",
        "sk": "Informácie o obchodníkovi"
    },
    "MEETING_LOCATION": {
        "en": "Meeting Location *",
        "es": "Lugar de Encuentro *",
        "fr": "Lieu de Rendez-vous *",
        "de": "Treffpunkt *",
        "pt": "Local de Encontro *",
        "ja": "会議場所 *",
        "zh": "会议地点 *",
        "ru": "Место встречи *",
        "ar": "مكان الاجتماع *",
        "hi": "मीटिंग स्थान *",
        "sk": "Miesto stretnutia *"
    },
    "DATE": {
        "en": "Date *",
        "es": "Fecha *",
        "fr": "Date *",
        "de": "Datum *",
        "pt": "Data *",
        "ja": "日付 *",
        "zh": "日期 *",
        "ru": "Дата *",
        "ar": "التاريخ *",
        "hi": "तारीख *",
        "sk": "Dátum *"
    },
    "TIME": {
        "en": "Time *",
        "es": "Hora *",
        "fr": "Heure *",
        "de": "Zeit *",
        "pt": "Horário *",
        "ja": "時刻 *",
        "zh": "时间 *",
        "ru": "Время *",
        "ar": "الوقت *",
        "hi": "समय *",
        "sk": "Čas *"
    },
    "OPTIONAL_MESSAGE": {
        "en": "Optional Message",
        "es": "Mensaje Opcional",
        "fr": "Message Optionnel",
        "de": "Optionale Nachricht",
        "pt": "Mensagem Opcional",
        "ja": "オプションのメッセージ",
        "zh": "可选消息",
        "ru": "Дополнительное сообщение",
        "ar": "رسالة اختيارية",
        "hi": "वैकल्पिक संदेश",
        "sk": "Voliteľná správa"
    },
    "CANCEL": {
        "en": "Cancel",
        "es": "Cancelar",
        "fr": "Annuler",
        "de": "Abbrechen",
        "pt": "Cancelar",
        "ja": "キャンセル",
        "zh": "取消",
        "ru": "Отмена",
        "ar": "إلغاء",
        "hi": "रद्द करें",
        "sk": "Zrušiť"
    },
    "SEND_PROPOSAL": {
        "en": "Send Proposal",
        "es": "Enviar Propuesta",
        "fr": "Envoyer Proposition",
        "de": "Vorschlag Senden",
        "pt": "Enviar Proposta",
        "ja": "提案を送信",
        "zh": "发送提议",
        "ru": "Отправить предложение",
        "ar": "إرسال الاقتراح",
        "hi": "प्रस्ताव भेजें",
        "sk": "Poslať návrh"
    },
    "MEETING_PROPOSALS": {
        "en": "Meeting Proposals",
        "es": "Propuestas de Reunión",
        "fr": "Propositions de Réunion",
        "de": "Treffvorschläge",
        "pt": "Propostas de Encontro",
        "ja": "ミーティング提案",
        "zh": "会议提案",
        "ru": "Предложения встреч",
        "ar": "اقتراحات الاجتماع",
        "hi": "मीटिंग प्रस्ताव",
        "sk": "Návrhy stretnutí"
    },
    
    # ProfileView (1 string)
    "MEMBER_SINCE": {
        "en": "Member since",
        "es": "Miembro desde",
        "fr": "Membre depuis",
        "de": "Mitglied seit",
        "pt": "Membro desde",
        "ja": "メンバー開始日",
        "zh": "自...以来的成员",
        "ru": "Член с",
        "ar": "عضو منذ",
        "hi": "सदस्य के बाद से",
        "sk": "Člen od"
    },
    
    # ListingMapView (2 strings)
    "APPROXIMATE_AREA": {
        "en": "Approximate area - exact location shared after purchase",
        "es": "Área aproximada - ubicación exacta compartida después de la compra",
        "fr": "Zone approximative - localisation exacte partagée après l'achat",
        "de": "Ungefähre Fläche - genaue Lage nach dem Kauf freigegeben",
        "pt": "Área aproximada - localização exata compartilhada após a compra",
        "ja": "概算面積 - 購入後に共有される正確な位置",
        "zh": "近似区域 - 购买后共享确切位置",
        "ru": "Приблизительная область - точное местоположение совместно после покупки",
        "ar": "المنطقة التقريبية - يتم مشاركة الموقع الدقيق بعد الشراء",
        "hi": "अनुमानित क्षेत्र - खरीदारी के बाद सटीक स्थान साझा की गई",
        "sk": "Približná plocha - presná poloha zdieľaná po nákupe"
    },
    "EXACT_LOCATION": {
        "en": "Exact location - meeting time confirmed",
        "es": "Ubicación exacta - hora de encuentro confirmada",
        "fr": "Localisation exacte - heure de rendez-vous confirmée",
        "de": "Genaue Lage - Treffzeit bestätigt",
        "pt": "Localização exata - horário de encontro confirmado",
        "ja": "正確な場所 - 会議時間が確認されました",
        "zh": "确切位置 - 会议时间已确认",
        "ru": "Точное местоположение - время встречи подтверждено",
        "ar": "الموقع الدقيق - تم تأكيد وقت الاجتماع",
        "hi": "सटीक स्थान - मीटिंग का समय पुष्टि किया गया",
        "sk": "Presná poloha - čas stretnutia potvrdený"
    },
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("=== HIGH-PRIORITY UI LABELS MIGRATION ===\n")
        
        # Extract English translations first
        english_translations = {key: translations.get('en', '') for key, translations in UI_LABELS_STRINGS.items()}
        
        # English
        english_count = 0
        for key, value in english_translations.items():
            cursor.execute("""
                INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (key, 'en', value, datetime.now(), datetime.now()))
            if cursor.rowcount > 0:
                english_count += 1
        connection.commit()
        print(f"✅ English: {english_count} keys inserted\n")
        
        # Other languages
        for lang_code in ['es', 'fr', 'de', 'pt', 'ja', 'zh', 'ru', 'ar', 'hi', 'sk']:
            inserted_count = 0
            for key, translations in UI_LABELS_STRINGS.items():
                value = translations.get(lang_code, '')
                if value:
                    cursor.execute("""
                        INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (key, lang_code, value, datetime.now(), datetime.now()))
                    if cursor.rowcount > 0:
                        inserted_count += 1
            connection.commit()
            if inserted_count > 0:
                print(f"✅ {lang_code}: {inserted_count} keys inserted")
        
        print("\n✅ Migration completed!")
        return 0
        
    except Exception as e:
        print(f"❌ Error: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    sys.exit(main())
