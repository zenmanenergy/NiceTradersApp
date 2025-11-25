#!/usr/bin/env python3
"""
Migrate Contact Trader View Keys to Database
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
CONTACT_TRADER_KEYS = {
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
        "CONTACT_TRADER": "Contactar Comerciante",
        "DISTANCE_UNKNOWN": "Distancia desconocida (acceso a ubicación requerido)",
        "MARKET_RATE": "Tasa de Mercado",
        "WITHIN_N_MILES_RANGE": "Dentro de 5 millas",
        "DAY_AGO": "hace 1 día",
        "COMPLETED_TRADES": "transacciones completadas",
        "MEMBER_SINCE": "Miembro desde:",
        "RESPONSE_TIME": "Tiempo de respuesta:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "Generalmente responde dentro de 1 hora",
        "LANGUAGES": "Idiomas:",
        "MEETING_PREFERENCE": "Preferencia de reunión:",
        "CONTACT_ACCESS_ACTIVE": "Acceso de Contacto Activo",
        "CAN_COMMUNICATE_DIRECTLY": "Puedes comunicarte directamente con {name} y coordinar tu intercambio.",
        "DIRECT_CONTACT": "Contacto Directo",
        "PHONE": "Teléfono:",
        "EMAIL": "Correo electrónico:",
        "CALL_NOW": "Llamar Ahora",
        "SEND_MESSAGE": "Enviar Mensaje",
        "CONTACT_ACCESS_REQUIRED": "Acceso de Contacto Requerido",
        "PAY_TO_CONTACT": "Paga $2.00 para contactar a {name} y coordinar tu intercambio.",
        "UNLOCK_FULL_CONTACT": "Desbloquear Contacto Completo",
        "PAY_ONCE_FULL_ACCESS": "Paga una vez para obtener acceso de contacto completo y coordinar tu intercambio",
        "CONTACT_ACCESS_TITLE": "Acceso de Contacto",
        "FEATURE_DIRECT_CONTACT": "Contacto directo con el vendedor",
        "FEATURE_EXCHANGE_COORDINATION": "Coordinación de intercambio",
        "FEATURE_PLATFORM_PROTECTION": "Protección de plataforma",
        "FEATURE_DISPUTE_RESOLUTION": "Apoyo en resolución de disputas",
        "SECURE_PAYMENT_PROCESSING": "Procesamiento seguro de pagos a través de PayPal. Puedes pagar con tu cuenta de PayPal o tarjeta de crédito.",
        "PAY_WITH_PAYPAL": "Paga $2.00 con PayPal",
        "PAYMENT_SECURE": "Tu información de pago es segura y cifrada. Nunca almacenamos tus datos de pago.",
        "SAFETY_TIPS": "Consejos de Seguridad",
        "SAFETY_TIP_1": "Siempre reúnete en lugares públicos durante las horas del día",
        "SAFETY_TIP_2": "Trae a un amigo o deja que alguien sepa tus planes",
        "SAFETY_TIP_3": "Verifica la moneda antes de completar el intercambio",
        "SAFETY_TIP_4": "Usa la resolución de disputas de NICE Traders si surgen problemas",
        "SAFETY_TIP_5": "Nunca compartas información financiera personal",
    },
    "fr": {
        "CONTACT_TRADER": "Contacter le Commerçant",
        "DISTANCE_UNKNOWN": "Distance inconnue (accès à la localisation requis)",
        "MARKET_RATE": "Taux du Marché",
        "WITHIN_N_MILES_RANGE": "À moins de 5 km",
        "DAY_AGO": "il y a 1 jour",
        "COMPLETED_TRADES": "échanges complétés",
        "MEMBER_SINCE": "Membre depuis:",
        "RESPONSE_TIME": "Temps de réponse:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "Répond généralement dans l'heure",
        "LANGUAGES": "Langues:",
        "MEETING_PREFERENCE": "Préférence de réunion:",
        "CONTACT_ACCESS_ACTIVE": "Accès de Contact Actif",
        "CAN_COMMUNICATE_DIRECTLY": "Vous pouvez communiquer directement avec {name} et coordonner votre échange.",
        "DIRECT_CONTACT": "Contact Direct",
        "PHONE": "Téléphone:",
        "EMAIL": "Email:",
        "CALL_NOW": "Appeler Maintenant",
        "SEND_MESSAGE": "Envoyer un Message",
        "CONTACT_ACCESS_REQUIRED": "Accès de Contact Requis",
        "PAY_TO_CONTACT": "Payez 2,00 $ pour contacter {name} et coordonner votre échange.",
        "UNLOCK_FULL_CONTACT": "Déverrouiller le Contact Complet",
        "PAY_ONCE_FULL_ACCESS": "Payez une fois pour obtenir un accès de contact complet et coordonner votre échange",
        "CONTACT_ACCESS_TITLE": "Accès de Contact",
        "FEATURE_DIRECT_CONTACT": "Contact direct avec le vendeur",
        "FEATURE_EXCHANGE_COORDINATION": "Coordination d'échange",
        "FEATURE_PLATFORM_PROTECTION": "Protection de la plateforme",
        "FEATURE_DISPUTE_RESOLUTION": "Support de résolution des différends",
        "SECURE_PAYMENT_PROCESSING": "Traitement sécurisé des paiements via PayPal. Vous pouvez payer avec votre compte PayPal ou votre carte de crédit.",
        "PAY_WITH_PAYPAL": "Payez 2,00 $ avec PayPal",
        "PAYMENT_SECURE": "Vos informations de paiement sont sécurisées et chiffrées. Nous ne stockons jamais vos détails de paiement.",
        "SAFETY_TIPS": "Conseils de Sécurité",
        "SAFETY_TIP_1": "Toujours se rencontrer dans des lieux publics pendant les heures de jour",
        "SAFETY_TIP_2": "Amenez un ami ou faites savoir à quelqu'un vos projets",
        "SAFETY_TIP_3": "Vérifiez la devise avant de terminer l'échange",
        "SAFETY_TIP_4": "Utilisez la résolution des différends de NICE Traders en cas de problème",
        "SAFETY_TIP_5": "Ne partagez jamais d'informations financières personnelles",
    },
    "de": {
        "CONTACT_TRADER": "Trader Kontaktieren",
        "DISTANCE_UNKNOWN": "Entfernung unbekannt (Zugriff auf Standort erforderlich)",
        "MARKET_RATE": "Marktkurs",
        "WITHIN_N_MILES_RANGE": "Innerhalb von 5 Meilen",
        "DAY_AGO": "vor 1 Tag",
        "COMPLETED_TRADES": "abgeschlossene Transaktionen",
        "MEMBER_SINCE": "Mitglied seit:",
        "RESPONSE_TIME": "Antwortzeit:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "Antwortet normalerweise innerhalb von 1 Stunde",
        "LANGUAGES": "Sprachen:",
        "MEETING_PREFERENCE": "Treffpunktpräferenz:",
        "CONTACT_ACCESS_ACTIVE": "Kontaktzugriff Aktiv",
        "CAN_COMMUNICATE_DIRECTLY": "Sie können direkt mit {name} kommunizieren und Ihren Austausch koordinieren.",
        "DIRECT_CONTACT": "Direkter Kontakt",
        "PHONE": "Telefon:",
        "EMAIL": "E-Mail:",
        "CALL_NOW": "Jetzt Anrufen",
        "SEND_MESSAGE": "Nachricht Senden",
        "CONTACT_ACCESS_REQUIRED": "Kontaktzugriff Erforderlich",
        "PAY_TO_CONTACT": "Zahlen Sie 2,00 $, um {name} zu kontaktieren und Ihren Austausch zu koordinieren.",
        "UNLOCK_FULL_CONTACT": "Vollständigen Kontakt Freischalten",
        "PAY_ONCE_FULL_ACCESS": "Zahlen Sie einmal, um vollständigen Kontaktzugriff zu erhalten und Ihren Austausch zu koordinieren",
        "CONTACT_ACCESS_TITLE": "Kontaktzugriff",
        "FEATURE_DIRECT_CONTACT": "Direkter Kontakt mit dem Verkäufer",
        "FEATURE_EXCHANGE_COORDINATION": "Austauschkoordination",
        "FEATURE_PLATFORM_PROTECTION": "Plattformschutz",
        "FEATURE_DISPUTE_RESOLUTION": "Unterstützung bei der Streitbeilegung",
        "SECURE_PAYMENT_PROCESSING": "Sichere Zahlungsabwicklung über PayPal. Sie können mit Ihrem PayPal-Konto oder Ihrer Kreditkarte bezahlen.",
        "PAY_WITH_PAYPAL": "Zahlen Sie 2,00 $ mit PayPal",
        "PAYMENT_SECURE": "Ihre Zahlungsinformationen sind sicher und verschlüsselt. Wir speichern Ihre Zahlungsdetails niemals.",
        "SAFETY_TIPS": "Sicherheitstipps",
        "SAFETY_TIP_1": "Treffen Sie sich immer an öffentlichen Orten während der Tagesstunden",
        "SAFETY_TIP_2": "Bringen Sie einen Freund mit oder lassen Sie jemanden Ihre Pläne wissen",
        "SAFETY_TIP_3": "Überprüfen Sie die Währung vor Abschluss des Austauschs",
        "SAFETY_TIP_4": "Verwenden Sie die Streitbeilegung von NICE Traders, wenn Probleme auftreten",
        "SAFETY_TIP_5": "Teilen Sie niemals persönliche Finanzinformationen mit",
    },
    "pt": {
        "CONTACT_TRADER": "Contatar Comerciante",
        "DISTANCE_UNKNOWN": "Distância desconhecida (acesso à localização necessário)",
        "MARKET_RATE": "Taxa de Mercado",
        "WITHIN_N_MILES_RANGE": "Dentro de 5 milhas",
        "DAY_AGO": "há 1 dia",
        "COMPLETED_TRADES": "transações concluídas",
        "MEMBER_SINCE": "Membro desde:",
        "RESPONSE_TIME": "Tempo de resposta:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "Geralmente responde em 1 hora",
        "LANGUAGES": "Idiomas:",
        "MEETING_PREFERENCE": "Preferência de reunião:",
        "CONTACT_ACCESS_ACTIVE": "Acesso de Contato Ativo",
        "CAN_COMMUNICATE_DIRECTLY": "Você pode se comunicar diretamente com {name} e coordenar sua troca.",
        "DIRECT_CONTACT": "Contato Direto",
        "PHONE": "Telefone:",
        "EMAIL": "Email:",
        "CALL_NOW": "Ligar Agora",
        "SEND_MESSAGE": "Enviar Mensagem",
        "CONTACT_ACCESS_REQUIRED": "Acesso de Contato Necessário",
        "PAY_TO_CONTACT": "Pague $2,00 para contatar {name} e coordenar sua troca.",
        "UNLOCK_FULL_CONTACT": "Desbloquear Contato Completo",
        "PAY_ONCE_FULL_ACCESS": "Pague uma vez para obter acesso de contato completo e coordenar sua troca",
        "CONTACT_ACCESS_TITLE": "Acesso de Contato",
        "FEATURE_DIRECT_CONTACT": "Contato direto com o vendedor",
        "FEATURE_EXCHANGE_COORDINATION": "Coordenação de troca",
        "FEATURE_PLATFORM_PROTECTION": "Proteção de plataforma",
        "FEATURE_DISPUTE_RESOLUTION": "Suporte de resolução de disputas",
        "SECURE_PAYMENT_PROCESSING": "Processamento seguro de pagamentos via PayPal. Você pode pagar com sua conta PayPal ou cartão de crédito.",
        "PAY_WITH_PAYPAL": "Pague $2,00 com PayPal",
        "PAYMENT_SECURE": "Suas informações de pagamento são seguras e criptografadas. Nunca armazenamos seus detalhes de pagamento.",
        "SAFETY_TIPS": "Dicas de Segurança",
        "SAFETY_TIP_1": "Sempre encontre-se em locais públicos durante as horas do dia",
        "SAFETY_TIP_2": "Traga um amigo ou deixe alguém saber sobre seus planos",
        "SAFETY_TIP_3": "Verifique a moeda antes de concluir a troca",
        "SAFETY_TIP_4": "Use a resolução de disputas da NICE Traders se surgirem problemas",
        "SAFETY_TIP_5": "Nunca compartilhe informações financeiras pessoais",
    },
    "ja": {
        "CONTACT_TRADER": "トレーダーに連絡",
        "DISTANCE_UNKNOWN": "距離不明（位置情報アクセスが必要）",
        "MARKET_RATE": "市場レート",
        "WITHIN_N_MILES_RANGE": "5マイル以内",
        "DAY_AGO": "1日前",
        "COMPLETED_TRADES": "完了した取引",
        "MEMBER_SINCE": "メンバー登録:",
        "RESPONSE_TIME": "応答時間:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "通常1時間以内に応答します",
        "LANGUAGES": "言語:",
        "MEETING_PREFERENCE": "会議の環境設定:",
        "CONTACT_ACCESS_ACTIVE": "連絡先アクセス有効",
        "CAN_COMMUNICATE_DIRECTLY": "{name}と直接通信して、交換を調整できます。",
        "DIRECT_CONTACT": "直接連絡",
        "PHONE": "電話:",
        "EMAIL": "メール:",
        "CALL_NOW": "今すぐ電話",
        "SEND_MESSAGE": "メッセージを送信",
        "CONTACT_ACCESS_REQUIRED": "連絡先アクセスが必要",
        "PAY_TO_CONTACT": "$2.00を支払って{name}に連絡し、交換を調整します。",
        "UNLOCK_FULL_CONTACT": "フルコンタクトロック解除",
        "PAY_ONCE_FULL_ACCESS": "1回支払って、完全な連絡先アクセスを取得し、交換を調整します",
        "CONTACT_ACCESS_TITLE": "連絡先アクセス",
        "FEATURE_DIRECT_CONTACT": "販売者との直接連絡",
        "FEATURE_EXCHANGE_COORDINATION": "交換調整",
        "FEATURE_PLATFORM_PROTECTION": "プラットフォーム保護",
        "FEATURE_DISPUTE_RESOLUTION": "紛争解決サポート",
        "SECURE_PAYMENT_PROCESSING": "PayPalを通じた安全な支払い処理。PayPalアカウントまたはクレジットカードで支払うことができます。",
        "PAY_WITH_PAYPAL": "PayPalで$2.00を支払う",
        "PAYMENT_SECURE": "お支払い情報は安全で暗号化されています。お支払いの詳細は保存しません。",
        "SAFETY_TIPS": "安全に関するヒント",
        "SAFETY_TIP_1": "昼間の間は常に公共の場所で会う",
        "SAFETY_TIP_2": "友人を連れるか、誰かに計画を知らせる",
        "SAFETY_TIP_3": "交換を完了する前に通貨を確認します",
        "SAFETY_TIP_4": "問題が発生した場合はNICE Tradersの紛争解決を使用",
        "SAFETY_TIP_5": "個人の財務情報を共有しないでください",
    },
    "zh": {
        "CONTACT_TRADER": "联系交易者",
        "DISTANCE_UNKNOWN": "距离未知（需要位置访问权限）",
        "MARKET_RATE": "市场汇率",
        "WITHIN_N_MILES_RANGE": "5英里以内",
        "DAY_AGO": "1天前",
        "COMPLETED_TRADES": "已完成交易",
        "MEMBER_SINCE": "成员时间:",
        "RESPONSE_TIME": "响应时间:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "通常在1小时内回应",
        "LANGUAGES": "语言:",
        "MEETING_PREFERENCE": "会议偏好:",
        "CONTACT_ACCESS_ACTIVE": "联系方式访问激活",
        "CAN_COMMUNICATE_DIRECTLY": "您可以与{name}直接沟通并协调您的交换。",
        "DIRECT_CONTACT": "直接联系",
        "PHONE": "电话:",
        "EMAIL": "邮箱:",
        "CALL_NOW": "立即致电",
        "SEND_MESSAGE": "发送消息",
        "CONTACT_ACCESS_REQUIRED": "需要联系方式访问权限",
        "PAY_TO_CONTACT": "支付$2.00与{name}联系并协调您的交换。",
        "UNLOCK_FULL_CONTACT": "解锁完整联系方式",
        "PAY_ONCE_FULL_ACCESS": "支付一次以获得完整的联系方式访问权限并协调您的交换",
        "CONTACT_ACCESS_TITLE": "联系方式访问",
        "FEATURE_DIRECT_CONTACT": "与卖家直接联系",
        "FEATURE_EXCHANGE_COORDINATION": "交换协调",
        "FEATURE_PLATFORM_PROTECTION": "平台保护",
        "FEATURE_DISPUTE_RESOLUTION": "纠纷解决支持",
        "SECURE_PAYMENT_PROCESSING": "通过PayPal进行安全的支付处理。您可以使用PayPal账户或信用卡付款。",
        "PAY_WITH_PAYPAL": "用PayPal支付$2.00",
        "PAYMENT_SECURE": "您的支付信息是安全的并经过加密。我们从不存储您的支付详情。",
        "SAFETY_TIPS": "安全建议",
        "SAFETY_TIP_1": "始终在白天在公共场所见面",
        "SAFETY_TIP_2": "带上朋友或让某人知道您的计划",
        "SAFETY_TIP_3": "在完成交换之前验证货币",
        "SAFETY_TIP_4": "如果出现问题，请使用NICE Traders的纠纷解决",
        "SAFETY_TIP_5": "永远不要分享个人财务信息",
    },
    "ru": {
        "CONTACT_TRADER": "Связаться с Трейдером",
        "DISTANCE_UNKNOWN": "Расстояние неизвестно (требуется доступ к местоположению)",
        "MARKET_RATE": "Рыночный Курс",
        "WITHIN_N_MILES_RANGE": "В пределах 5 миль",
        "DAY_AGO": "1 день назад",
        "COMPLETED_TRADES": "завершенные сделки",
        "MEMBER_SINCE": "Участник с:",
        "RESPONSE_TIME": "Время ответа:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "Обычно отвечает в течение 1 часа",
        "LANGUAGES": "Языки:",
        "MEETING_PREFERENCE": "Предпочтение встречи:",
        "CONTACT_ACCESS_ACTIVE": "Доступ к Контакту Активен",
        "CAN_COMMUNICATE_DIRECTLY": "Вы можете напрямую общаться с {name} и координировать свой обмен.",
        "DIRECT_CONTACT": "Прямой Контакт",
        "PHONE": "Телефон:",
        "EMAIL": "Электронная почта:",
        "CALL_NOW": "Позвонить Сейчас",
        "SEND_MESSAGE": "Отправить Сообщение",
        "CONTACT_ACCESS_REQUIRED": "Требуется Доступ к Контакту",
        "PAY_TO_CONTACT": "Заплатите $2,00, чтобы связаться с {name} и координировать свой обмен.",
        "UNLOCK_FULL_CONTACT": "Разблокировать Полный Контакт",
        "PAY_ONCE_FULL_ACCESS": "Заплатите один раз, чтобы получить полный доступ к контакту и координировать свой обмен",
        "CONTACT_ACCESS_TITLE": "Доступ к Контакту",
        "FEATURE_DIRECT_CONTACT": "Прямой контакт с продавцом",
        "FEATURE_EXCHANGE_COORDINATION": "Координация обмена",
        "FEATURE_PLATFORM_PROTECTION": "Защита платформы",
        "FEATURE_DISPUTE_RESOLUTION": "Поддержка разрешения споров",
        "SECURE_PAYMENT_PROCESSING": "Безопасная обработка платежей через PayPal. Вы можете платить с помощью учетной записи PayPal или кредитной карты.",
        "PAY_WITH_PAYPAL": "Заплатите $2,00 с помощью PayPal",
        "PAYMENT_SECURE": "Ваша информация о платеже защищена и зашифрована. Мы никогда не храним ваши платежные реквизиты.",
        "SAFETY_TIPS": "Советы Безопасности",
        "SAFETY_TIP_1": "Всегда встречайтесь в общественных местах в дневное время",
        "SAFETY_TIP_2": "Приведите друга или дайте кому-нибудь знать о своих планах",
        "SAFETY_TIP_3": "Проверьте валюту перед завершением обмена",
        "SAFETY_TIP_4": "Используйте разрешение споров NICE Traders, если возникнут проблемы",
        "SAFETY_TIP_5": "Никогда не делитесь личной финансовой информацией",
    },
    "ar": {
        "CONTACT_TRADER": "الاتصال بالمتاجر",
        "DISTANCE_UNKNOWN": "المسافة غير معروفة (يلزم الوصول إلى الموقع)",
        "MARKET_RATE": "سعر الصرف",
        "WITHIN_N_MILES_RANGE": "في حدود 5 أميال",
        "DAY_AGO": "منذ يوم واحد",
        "COMPLETED_TRADES": "الصفقات المكتملة",
        "MEMBER_SINCE": "عضو منذ:",
        "RESPONSE_TIME": "وقت الرد:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "عادة يرد في غضون ساعة واحدة",
        "LANGUAGES": "اللغات:",
        "MEETING_PREFERENCE": "تفضيل الاجتماع:",
        "CONTACT_ACCESS_ACTIVE": "الوصول للاتصال نشط",
        "CAN_COMMUNICATE_DIRECTLY": "يمكنك التواصل مباشرة مع {name} وتنسيق التبادل الخاص بك.",
        "DIRECT_CONTACT": "الاتصال المباشر",
        "PHONE": "الهاتف:",
        "EMAIL": "البريد الإلكتروني:",
        "CALL_NOW": "اتصل الآن",
        "SEND_MESSAGE": "إرسال رسالة",
        "CONTACT_ACCESS_REQUIRED": "يلزم الوصول للاتصال",
        "PAY_TO_CONTACT": "ادفع $2.00 للاتصال ب {name} وتنسيق التبادل الخاص بك.",
        "UNLOCK_FULL_CONTACT": "فتح الاتصال الكامل",
        "PAY_ONCE_FULL_ACCESS": "ادفع مرة واحدة للحصول على الوصول الكامل للاتصال وتنسيق التبادل الخاص بك",
        "CONTACT_ACCESS_TITLE": "الوصول للاتصال",
        "FEATURE_DIRECT_CONTACT": "الاتصال المباشر مع البائع",
        "FEATURE_EXCHANGE_COORDINATION": "تنسيق التبادل",
        "FEATURE_PLATFORM_PROTECTION": "حماية المنصة",
        "FEATURE_DISPUTE_RESOLUTION": "دعم حل النزاعات",
        "SECURE_PAYMENT_PROCESSING": "معالجة الدفع الآمنة من خلال PayPal. يمكنك الدفع باستخدام حسابك على PayPal أو بطاقة الائتمان.",
        "PAY_WITH_PAYPAL": "ادفع $2.00 باستخدام PayPal",
        "PAYMENT_SECURE": "معلومات الدفع الخاصة بك آمنة ومشفرة. لا نقوم أبداً بتخزين تفاصيل الدفع الخاصة بك.",
        "SAFETY_TIPS": "نصائح السلامة",
        "SAFETY_TIP_1": "تجتمع دائماً في الأماكن العامة خلال ساعات النهار",
        "SAFETY_TIP_2": "أحضر صديقاً أو أخبر شخصاً ما عن خططك",
        "SAFETY_TIP_3": "تحقق من العملة قبل إتمام الصرف",
        "SAFETY_TIP_4": "استخدم حل النزاعات في NICE Traders إذا حدثت مشاكل",
        "SAFETY_TIP_5": "لا تشارك أبداً معلومات مالية شخصية",
    },
    "hi": {
        "CONTACT_TRADER": "व्यापारी से संपर्क करें",
        "DISTANCE_UNKNOWN": "दूरी अज्ञात (स्थान पहुंच आवश्यक)",
        "MARKET_RATE": "बाजार दर",
        "WITHIN_N_MILES_RANGE": "5 मील के भीतर",
        "DAY_AGO": "1 दिन पहले",
        "COMPLETED_TRADES": "पूर्ण व्यापार",
        "MEMBER_SINCE": "सदस्य बनाया:",
        "RESPONSE_TIME": "प्रतिक्रिया समय:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "आमतौर पर 1 घंटे के भीतर प्रतिक्रिया देता है",
        "LANGUAGES": "भाषाएं:",
        "MEETING_PREFERENCE": "बैठक की प्राथमिकता:",
        "CONTACT_ACCESS_ACTIVE": "संपर्क पहुंच सक्रिय",
        "CAN_COMMUNICATE_DIRECTLY": "आप सीधे {name} के साथ संवाद कर सकते हैं और अपने विनिमय को समन्वय कर सकते हैं।",
        "DIRECT_CONTACT": "सीधा संपर्क",
        "PHONE": "फोन:",
        "EMAIL": "ईमेल:",
        "CALL_NOW": "अभी कॉल करें",
        "SEND_MESSAGE": "संदेश भेजें",
        "CONTACT_ACCESS_REQUIRED": "संपर्क पहुंच आवश्यक",
        "PAY_TO_CONTACT": "${name} से संपर्क करने के लिए $2.00 का भुगतान करें और अपने विनिमय को समन्वय करें।",
        "UNLOCK_FULL_CONTACT": "पूर्ण संपर्क अनलॉक करें",
        "PAY_ONCE_FULL_ACCESS": "पूर्ण संपर्क पहुंच प्राप्त करने और अपने विनिमय को समन्वय करने के लिए एक बार भुगतान करें",
        "CONTACT_ACCESS_TITLE": "संपर्क पहुंच",
        "FEATURE_DIRECT_CONTACT": "विक्रेता के साथ सीधा संपर्क",
        "FEATURE_EXCHANGE_COORDINATION": "विनिमय समन्वय",
        "FEATURE_PLATFORM_PROTECTION": "मंच सुरक्षा",
        "FEATURE_DISPUTE_RESOLUTION": "विवाद समाधान समर्थन",
        "SECURE_PAYMENT_PROCESSING": "PayPal के माध्यम से सुरक्षित भुगतान प्रसंस्करण। आप अपने PayPal खाते या क्रेडिट कार्ड से भुगतान कर सकते हैं।",
        "PAY_WITH_PAYPAL": "PayPal के साथ $2.00 का भुगतान करें",
        "PAYMENT_SECURE": "आपकी भुगतान जानकारी सुरक्षित और एन्क्रिप्ट की गई है। हम कभी भी आपके भुगतान विवरण को संग्रहीत नहीं करते।",
        "SAFETY_TIPS": "सुरक्षा सुझाव",
        "SAFETY_TIP_1": "हमेशा दिन के समय सार्वजनिक स्थानों पर मिलें",
        "SAFETY_TIP_2": "एक दोस्त लाएं या किसी को अपनी योजनाओं के बारे में बताएं",
        "SAFETY_TIP_3": "विनिमय पूरा करने से पहले मुद्रा को सत्यापित करें",
        "SAFETY_TIP_4": "समस्याएं उत्पन्न होने पर NICE Traders के विवाद समाधान का उपयोग करें",
        "SAFETY_TIP_5": "कभी भी व्यक्तिगत वित्तीय जानकारी साझा न करें",
    },
    "sk": {
        "CONTACT_TRADER": "Kontaktovať Obchodníka",
        "DISTANCE_UNKNOWN": "Vzdialenosť neznáma (je potrebný prístup k polohe)",
        "MARKET_RATE": "Trhová Sadzba",
        "WITHIN_N_MILES_RANGE": "V rámci 5 míľ",
        "DAY_AGO": "pred 1 dňom",
        "COMPLETED_TRADES": "dokončené obchody",
        "MEMBER_SINCE": "Člen od:",
        "RESPONSE_TIME": "Čas odozvy:",
        "USUALLY_RESPONDS_WITHIN_1_HOUR": "Zvyčajne odpovedá do 1 hodiny",
        "LANGUAGES": "Jazyky:",
        "MEETING_PREFERENCE": "Preferencia stretnutia:",
        "CONTACT_ACCESS_ACTIVE": "Prístup k Kontaktu Aktívny",
        "CAN_COMMUNICATE_DIRECTLY": "Môžete sa priamo komunikovať s {name} a koordinovať svoju výmenu.",
        "DIRECT_CONTACT": "Priamy Kontakt",
        "PHONE": "Telefón:",
        "EMAIL": "Email:",
        "CALL_NOW": "Zavolať Teraz",
        "SEND_MESSAGE": "Poslať Správu",
        "CONTACT_ACCESS_REQUIRED": "Vyžaduje sa Prístup k Kontaktu",
        "PAY_TO_CONTACT": "Zaplaťte $2,00, aby ste kontaktovali {name} a koordinovali svoju výmenu.",
        "UNLOCK_FULL_CONTACT": "Odomknúť Úplný Kontakt",
        "PAY_ONCE_FULL_ACCESS": "Zaplaťte raz, aby ste získali úplný prístup k kontaktu a koordinovali svoju výmenu",
        "CONTACT_ACCESS_TITLE": "Prístup k Kontaktu",
        "FEATURE_DIRECT_CONTACT": "Priamy kontakt s predávajúcim",
        "FEATURE_EXCHANGE_COORDINATION": "Koordinácia výmeny",
        "FEATURE_PLATFORM_PROTECTION": "Ochrana platformy",
        "FEATURE_DISPUTE_RESOLUTION": "Podpora pri riešení sporov",
        "SECURE_PAYMENT_PROCESSING": "Bezpečné spracovanie platieb cez PayPal. Môžete platiť pomocou svojho účtu PayPal alebo kreditnej karty.",
        "PAY_WITH_PAYPAL": "Zaplaťte $2,00 cez PayPal",
        "PAYMENT_SECURE": "Vaše informácie o platbe sú bezpečné a šifrované. Nikdy neukladáme vaše údaje o platbe.",
        "SAFETY_TIPS": "Tipy na Bezpečnosť",
        "SAFETY_TIP_1": "Vždy sa stretávajte na verejných miestach počas denných hodín",
        "SAFETY_TIP_2": "Prineste si priateľa alebo komu-buď dajte vedieť o svojich plánoch",
        "SAFETY_TIP_3": "Pred dokončením výmeny si overte menu",
        "SAFETY_TIP_4": "Ak sa objavia problémy, použite riešenie sporov NICE Traders",
        "SAFETY_TIP_5": "Nikdy nezdieľajte osobné finančné informácie",
    },
}


def migrate():
    """Insert or update contact trader view keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("📝 Inserting English translations...")
        for key, value in CONTACT_TRADER_KEYS.items():
            check_query = "SELECT id FROM translations WHERE translation_key = %s AND language_code = 'en'"
            cursor.execute(check_query, (key,))
            result = cursor.fetchone()
            
            if result:
                update_query = "UPDATE translations SET translation_value = %s, updated_at = NOW() WHERE translation_key = %s AND language_code = 'en'"
                cursor.execute(update_query, (value, key))
                print(f"  ✏️  Updated: {key}")
            else:
                insert_query = "INSERT INTO translations (translation_key, translation_value, language_code, created_at, updated_at) VALUES (%s, %s, 'en', NOW(), NOW())"
                cursor.execute(insert_query, (key, value))
                print(f"  ✅ Inserted: {key}")
        
        connection.commit()
        
        for language_code, translations in TRANSLATIONS.items():
            print(f"\n📝 Inserting {language_code.upper()} translations...")
            for key, value in translations.items():
                check_query = "SELECT id FROM translations WHERE translation_key = %s AND language_code = %s"
                cursor.execute(check_query, (key, language_code))
                result = cursor.fetchone()
                
                if result:
                    update_query = "UPDATE translations SET translation_value = %s, updated_at = NOW() WHERE translation_key = %s AND language_code = %s"
                    cursor.execute(update_query, (value, key, language_code))
                    print(f"  ✏️  Updated: {key}")
                else:
                    insert_query = "INSERT INTO translations (translation_key, translation_value, language_code, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW())"
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
