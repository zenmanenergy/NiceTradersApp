#!/usr/bin/env python3
"""
Migrate missing Contact Purchase View Keys to Database
These are additional keys needed for ContactPurchaseView.swift localization
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
CONTACT_PURCHASE_KEYS = {
    "LOADING_CONTACT_DETAILS": "Loading contact details...",
    "MEMBER_SINCE_COLON": "Member since:",
    "RESPONSE_TIME_COLON": "Response time:",
    "LANGUAGES_COLON": "Languages:",
    "MEETING_PREFERENCE_COLON": "Meeting preference:",
    "PROCESSING_PAYMENT": "Processing Payment...",
    "SESSION_EXPIRED_LOGIN_AGAIN": "Session expired. Please log in again.",
    "FAILED_LOAD_CONTACT_INFO": "Failed to load contact information",
    "FAILED_LOAD_LISTING_DETAILS": "Failed to load listing details",
    "HELP_KEEP_PLATFORM_SAFE": "Help us keep the platform safe by reporting inappropriate listings.",
    "REASON_FOR_REPORTING_COLON": "Reason for reporting:",
    "SELECT_A_REASON": "Select a reason",
    "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Additional details (optional):",
    "REPORT_LISTING": "Report Listing",
    "REPORT_SCAM_OR_FRAUD": "Scam or fraud",
    "REPORT_FAKE_LISTING": "Fake listing",
    "REPORT_INAPPROPRIATE_CONTENT": "Inappropriate content",
    "REPORT_SPAM": "Spam",
    "REPORT_OTHER": "Other",
    "SUBMIT_REPORT": "Submit Report",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {
        "LOADING_CONTACT_DETAILS": "Cargando detalles de contacto...",
        "MEMBER_SINCE_COLON": "Miembro desde:",
        "RESPONSE_TIME_COLON": "Tiempo de respuesta:",
        "LANGUAGES_COLON": "Idiomas:",
        "MEETING_PREFERENCE_COLON": "Preferencia de reunión:",
        "PROCESSING_PAYMENT": "Procesando Pago...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "Sesión expirada. Por favor, inicia sesión de nuevo.",
        "FAILED_LOAD_CONTACT_INFO": "Error al cargar la información de contacto",
        "FAILED_LOAD_LISTING_DETAILS": "Error al cargar los detalles del anuncio",
        "HELP_KEEP_PLATFORM_SAFE": "Ayúdanos a mantener la plataforma segura reportando anuncios inapropiados.",
        "REASON_FOR_REPORTING_COLON": "Motivo del reporte:",
        "SELECT_A_REASON": "Selecciona un motivo",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Detalles adicionales (opcional):",
        "REPORT_LISTING": "Reportar Anuncio",
        "REPORT_SCAM_OR_FRAUD": "Estafa o fraude",
        "REPORT_FAKE_LISTING": "Anuncio falso",
        "REPORT_INAPPROPRIATE_CONTENT": "Contenido inapropiado",
        "REPORT_SPAM": "Spam",
        "REPORT_OTHER": "Otro",
        "SUBMIT_REPORT": "Enviar Reporte",
    },
    "fr": {
        "LOADING_CONTACT_DETAILS": "Chargement des détails de contact...",
        "MEMBER_SINCE_COLON": "Membre depuis:",
        "RESPONSE_TIME_COLON": "Temps de réponse:",
        "LANGUAGES_COLON": "Langues:",
        "MEETING_PREFERENCE_COLON": "Préférence de réunion:",
        "PROCESSING_PAYMENT": "Traitement du Paiement...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "Session expirée. Veuillez vous reconnecter.",
        "FAILED_LOAD_CONTACT_INFO": "Impossible de charger les informations de contact",
        "FAILED_LOAD_LISTING_DETAILS": "Impossible de charger les détails de l'annonce",
        "HELP_KEEP_PLATFORM_SAFE": "Aidez-nous à garder la plateforme sûre en signalant les annonces inappropriées.",
        "REASON_FOR_REPORTING_COLON": "Raison du signalement:",
        "SELECT_A_REASON": "Sélectionnez une raison",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Détails supplémentaires (optionnel):",
        "REPORT_LISTING": "Signaler l'Annonce",
        "REPORT_SCAM_OR_FRAUD": "Escroquerie ou fraude",
        "REPORT_FAKE_LISTING": "Annonce fausse",
        "REPORT_INAPPROPRIATE_CONTENT": "Contenu inapproprié",
        "REPORT_SPAM": "Spam",
        "REPORT_OTHER": "Autre",
        "SUBMIT_REPORT": "Soumettre le Rapport",
    },
    "de": {
        "LOADING_CONTACT_DETAILS": "Kontaktdetails werden geladen...",
        "MEMBER_SINCE_COLON": "Mitglied seit:",
        "RESPONSE_TIME_COLON": "Antwortzeit:",
        "LANGUAGES_COLON": "Sprachen:",
        "MEETING_PREFERENCE_COLON": "Treffpunktpräferenz:",
        "PROCESSING_PAYMENT": "Zahlung wird verarbeitet...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "Sitzung abgelaufen. Bitte melden Sie sich erneut an.",
        "FAILED_LOAD_CONTACT_INFO": "Kontaktinformationen konnten nicht geladen werden",
        "FAILED_LOAD_LISTING_DETAILS": "Angebotdetails konnten nicht geladen werden",
        "HELP_KEEP_PLATFORM_SAFE": "Helfen Sie uns, die Plattform sicher zu halten, indem Sie unangemessene Angebote melden.",
        "REASON_FOR_REPORTING_COLON": "Grund für die Meldung:",
        "SELECT_A_REASON": "Wählen Sie einen Grund aus",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Zusätzliche Details (optional):",
        "REPORT_LISTING": "Angebot Melden",
        "REPORT_SCAM_OR_FRAUD": "Betrug oder Schwindel",
        "REPORT_FAKE_LISTING": "Falsches Angebot",
        "REPORT_INAPPROPRIATE_CONTENT": "Unangemessener Inhalt",
        "REPORT_SPAM": "Spam",
        "REPORT_OTHER": "Sonstiges",
        "SUBMIT_REPORT": "Bericht Einreichen",
    },
    "pt": {
        "LOADING_CONTACT_DETAILS": "Carregando detalhes de contato...",
        "MEMBER_SINCE_COLON": "Membro desde:",
        "RESPONSE_TIME_COLON": "Tempo de resposta:",
        "LANGUAGES_COLON": "Idiomas:",
        "MEETING_PREFERENCE_COLON": "Preferência de reunião:",
        "PROCESSING_PAYMENT": "Processando Pagamento...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "Sessão expirada. Por favor, faça login novamente.",
        "FAILED_LOAD_CONTACT_INFO": "Falha ao carregar informações de contato",
        "FAILED_LOAD_LISTING_DETAILS": "Falha ao carregar detalhes do anúncio",
        "HELP_KEEP_PLATFORM_SAFE": "Ajude-nos a manter a plataforma segura relatando anúncios inadequados.",
        "REASON_FOR_REPORTING_COLON": "Motivo do relatório:",
        "SELECT_A_REASON": "Selecione um motivo",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Detalhes adicionais (opcional):",
        "REPORT_LISTING": "Denunciar Anúncio",
        "REPORT_SCAM_OR_FRAUD": "Fraude ou golpe",
        "REPORT_FAKE_LISTING": "Anúncio falso",
        "REPORT_INAPPROPRIATE_CONTENT": "Conteúdo inadequado",
        "REPORT_SPAM": "Spam",
        "REPORT_OTHER": "Outro",
        "SUBMIT_REPORT": "Enviar Relatório",
    },
    "ja": {
        "LOADING_CONTACT_DETAILS": "連絡先の詳細を読み込み中...",
        "MEMBER_SINCE_COLON": "メンバー登録:",
        "RESPONSE_TIME_COLON": "応答時間:",
        "LANGUAGES_COLON": "言語:",
        "MEETING_PREFERENCE_COLON": "会議の環境設定:",
        "PROCESSING_PAYMENT": "支払い処理中...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "セッションの有効期限が切れています。再度ログインしてください。",
        "FAILED_LOAD_CONTACT_INFO": "連絡先情報の読み込みに失敗しました",
        "FAILED_LOAD_LISTING_DETAILS": "リスティングの詳細の読み込みに失敗しました",
        "HELP_KEEP_PLATFORM_SAFE": "不適切なリスティングを報告して、プラットフォームの安全性を保つのにお役立てください。",
        "REASON_FOR_REPORTING_COLON": "報告の理由:",
        "SELECT_A_REASON": "理由を選択",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "追加の詳細（オプション）:",
        "REPORT_LISTING": "リスティングを報告",
        "REPORT_SCAM_OR_FRAUD": "詐欺または詐欺",
        "REPORT_FAKE_LISTING": "架空のリスティング",
        "REPORT_INAPPROPRIATE_CONTENT": "不適切なコンテンツ",
        "REPORT_SPAM": "スパム",
        "REPORT_OTHER": "その他",
        "SUBMIT_REPORT": "レポートを提出",
    },
    "zh": {
        "LOADING_CONTACT_DETAILS": "正在加载联系方式详情...",
        "MEMBER_SINCE_COLON": "成员时间:",
        "RESPONSE_TIME_COLON": "响应时间:",
        "LANGUAGES_COLON": "语言:",
        "MEETING_PREFERENCE_COLON": "会议偏好:",
        "PROCESSING_PAYMENT": "正在处理付款...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "会话已过期。请重新登录。",
        "FAILED_LOAD_CONTACT_INFO": "加载联系方式信息失败",
        "FAILED_LOAD_LISTING_DETAILS": "加载列表详情失败",
        "HELP_KEEP_PLATFORM_SAFE": "通过报告不适当的列表，帮助我们保持平台安全。",
        "REASON_FOR_REPORTING_COLON": "报告原因:",
        "SELECT_A_REASON": "选择原因",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "其他详情（可选）:",
        "REPORT_LISTING": "报告列表",
        "REPORT_SCAM_OR_FRAUD": "诈骗或欺诈",
        "REPORT_FAKE_LISTING": "虚假列表",
        "REPORT_INAPPROPRIATE_CONTENT": "不适当的内容",
        "REPORT_SPAM": "垃圾邮件",
        "REPORT_OTHER": "其他",
        "SUBMIT_REPORT": "提交报告",
    },
    "ru": {
        "LOADING_CONTACT_DETAILS": "Загрузка контактной информации...",
        "MEMBER_SINCE_COLON": "Участник с:",
        "RESPONSE_TIME_COLON": "Время ответа:",
        "LANGUAGES_COLON": "Языки:",
        "MEETING_PREFERENCE_COLON": "Предпочтение встречи:",
        "PROCESSING_PAYMENT": "Обработка платежа...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "Сеанс истек. Пожалуйста, войдите снова.",
        "FAILED_LOAD_CONTACT_INFO": "Не удалось загрузить контактную информацию",
        "FAILED_LOAD_LISTING_DETAILS": "Не удалось загрузить сведения об объявлении",
        "HELP_KEEP_PLATFORM_SAFE": "Помогите нам обеспечить безопасность платформы, сообщив о неуместных объявлениях.",
        "REASON_FOR_REPORTING_COLON": "Причина отчета:",
        "SELECT_A_REASON": "Выберите причину",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Дополнительные детали (необязательно):",
        "REPORT_LISTING": "Сообщить об объявлении",
        "REPORT_SCAM_OR_FRAUD": "Мошенничество или обман",
        "REPORT_FAKE_LISTING": "Поддельное объявление",
        "REPORT_INAPPROPRIATE_CONTENT": "Неуместный контент",
        "REPORT_SPAM": "Спам",
        "REPORT_OTHER": "Другое",
        "SUBMIT_REPORT": "Отправить отчет",
    },
    "ar": {
        "LOADING_CONTACT_DETAILS": "جاري تحميل تفاصيل الاتصال...",
        "MEMBER_SINCE_COLON": "عضو منذ:",
        "RESPONSE_TIME_COLON": "وقت الرد:",
        "LANGUAGES_COLON": "اللغات:",
        "MEETING_PREFERENCE_COLON": "تفضيل الاجتماع:",
        "PROCESSING_PAYMENT": "جاري معالجة الدفع...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.",
        "FAILED_LOAD_CONTACT_INFO": "فشل تحميل معلومات الاتصال",
        "FAILED_LOAD_LISTING_DETAILS": "فشل تحميل تفاصيل الإدراج",
        "HELP_KEEP_PLATFORM_SAFE": "ساعدنا في الحفاظ على أمان المنصة بالإبلاغ عن الإدراجات غير المناسبة.",
        "REASON_FOR_REPORTING_COLON": "سبب الإبلاغ:",
        "SELECT_A_REASON": "اختر سبباً",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "تفاصيل إضافية (اختياري):",
        "REPORT_LISTING": "الإبلاغ عن الإدراج",
        "REPORT_SCAM_OR_FRAUD": "احتيال أو غش",
        "REPORT_FAKE_LISTING": "إدراج وهمي",
        "REPORT_INAPPROPRIATE_CONTENT": "محتوى غير مناسب",
        "REPORT_SPAM": "بريد عشوائي",
        "REPORT_OTHER": "آخر",
        "SUBMIT_REPORT": "إرسال التقرير",
    },
    "hi": {
        "LOADING_CONTACT_DETAILS": "संपर्क विवरण लोड हो रहे हैं...",
        "MEMBER_SINCE_COLON": "सदस्य के बाद से:",
        "RESPONSE_TIME_COLON": "प्रतिक्रिया समय:",
        "LANGUAGES_COLON": "भाषाएँ:",
        "MEETING_PREFERENCE_COLON": "बैठक की पसंद:",
        "PROCESSING_PAYMENT": "भुगतान प्रसंस्करण...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "सत्र समाप्त हो गया है। कृपया फिर से लॉगिन करें।",
        "FAILED_LOAD_CONTACT_INFO": "संपर्क जानकारी लोड करने में विफल रहा",
        "FAILED_LOAD_LISTING_DETAILS": "सूची विवरण लोड करने में विफल रहा",
        "HELP_KEEP_PLATFORM_SAFE": "अनुचित सूचियों की रिपोर्ट करके प्लेटफॉर्म को सुरक्षित रखने में हमारी सहायता करें।",
        "REASON_FOR_REPORTING_COLON": "रिपोर्ट का कारण:",
        "SELECT_A_REASON": "एक कारण चुनें",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "अतिरिक्त विवरण (वैकल्पिक):",
        "REPORT_LISTING": "सूची की रिपोर्ट करें",
        "REPORT_SCAM_OR_FRAUD": "धोखाधड़ी या जालसाजी",
        "REPORT_FAKE_LISTING": "नकली सूची",
        "REPORT_INAPPROPRIATE_CONTENT": "अनुचित सामग्री",
        "REPORT_SPAM": "स्पैम",
        "REPORT_OTHER": "अन्य",
        "SUBMIT_REPORT": "रिपोर्ट सबमिट करें",
    },
    "sk": {
        "LOADING_CONTACT_DETAILS": "Načítavajú sa podrobnosti kontaktu...",
        "MEMBER_SINCE_COLON": "Člen od:",
        "RESPONSE_TIME_COLON": "Čas odozvy:",
        "LANGUAGES_COLON": "Jazyky:",
        "MEETING_PREFERENCE_COLON": "Voľba stretnutia:",
        "PROCESSING_PAYMENT": "Spracovanie platby...",
        "SESSION_EXPIRED_LOGIN_AGAIN": "Relácia sa vypršala. Prihláste sa znova.",
        "FAILED_LOAD_CONTACT_INFO": "Nepodarilo sa načítať kontaktné informácie",
        "FAILED_LOAD_LISTING_DETAILS": "Nepodarilo sa načítať podrobnosti zoznamu",
        "HELP_KEEP_PLATFORM_SAFE": "Pomôžte nám udržiavať platformu bezpečnú tým, že nahlásrite nevhodné zoznamy.",
        "REASON_FOR_REPORTING_COLON": "Dôvod hlásenia:",
        "SELECT_A_REASON": "Vyberte dôvod",
        "ADDITIONAL_DETAILS_OPTIONAL_COLON": "Ďalšie podrobnosti (voliteľné):",
        "REPORT_LISTING": "Nahlásiť zoznam",
        "REPORT_SCAM_OR_FRAUD": "Podvod alebo podvod",
        "REPORT_FAKE_LISTING": "Nepravý zoznam",
        "REPORT_INAPPROPRIATE_CONTENT": "Nevhodný obsah",
        "REPORT_SPAM": "Spam",
        "REPORT_OTHER": "Ostatné",
        "SUBMIT_REPORT": "Poslať správu",
    },
}

def main():
    """Insert or update contact purchase view keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        for lang_code in TRANSLATIONS.keys():
            print(f"\n📝 Inserting {lang_code} translations...")
            trans_dict = TRANSLATIONS[lang_code]
            
            for key_name, english_value in CONTACT_PURCHASE_KEYS.items():
                if key_name in trans_dict:
                    trans_value = trans_dict[key_name]
                else:
                    trans_value = english_value
                
                # Check if key already exists for this language
                check_query = "SELECT id FROM translations WHERE translation_key = %s AND language_code = %s"
                cursor.execute(check_query, (key_name, lang_code))
                result = cursor.fetchone()
                
                if result:
                    # Update existing
                    update_query = "UPDATE translations SET translation_value = %s WHERE translation_key = %s AND language_code = %s"
                    cursor.execute(update_query, (trans_value, key_name, lang_code))
                    print(f"  ✏️  Updated: {key_name}")
                else:
                    # Insert new
                    insert_query = "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s)"
                    cursor.execute(insert_query, (key_name, lang_code, trans_value))
                    print(f"  ✅ Inserted: {key_name}")
            
            connection.commit()
        
        print("\n✅ Migration completed successfully!")
        
    except Exception as e:
        connection.rollback()
        print(f"❌ Migration failed: {e}")
    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    main()
