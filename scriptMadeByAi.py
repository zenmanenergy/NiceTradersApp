#!/usr/bin/env python3
"""
Add missing translation keys for EditListingView step2 restructuring
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql

translations = [
    ("CONFIRM_YOUR_PREFERENCES", "en", "Confirm Your Preferences"),
    ("CONFIRM_YOUR_PREFERENCES", "ja", "あなたの好みを確認してください"),
    ("CONFIRM_YOUR_PREFERENCES", "es", "Confirma Tus Preferencias"),
    ("CONFIRM_YOUR_PREFERENCES", "fr", "Confirmez Vos Préférences"),
    ("CONFIRM_YOUR_PREFERENCES", "de", "Bestätigen Sie Ihre Einstellungen"),
    ("CONFIRM_YOUR_PREFERENCES", "ar", "تأكيد تفضيلاتك"),
    ("CONFIRM_YOUR_PREFERENCES", "hi", "अपनी प्राथमिकताओं की पुष्टि करें"),
    ("CONFIRM_YOUR_PREFERENCES", "pt", "Confirme Suas Preferências"),
    ("CONFIRM_YOUR_PREFERENCES", "ru", "Подтвердите ваши предпочтения"),
    ("CONFIRM_YOUR_PREFERENCES", "sk", "Potvrďte Vaše Preferencie"),
    ("CONFIRM_YOUR_PREFERENCES", "zh", "确认您的偏好"),
    
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "en", "Which currency will you accept?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "ja", "どの通貨を受け付けますか？"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "es", "¿Qué moneda aceptarás?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "fr", "Quelle devise accepterez-vous?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "de", "Welche Währung werden Sie akzeptieren?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "ar", "أي عملة ستقبل؟"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "hi", "आप कौन सी मुद्रा स्वीकार करेंगे?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "pt", "Qual moeda você aceitará?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "ru", "Какую валюту вы примете?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "sk", "Ktorú menu budete akceptovať?"),
    ("WHICH_CURRENCY_WILL_YOU_ACCEPT", "zh", "您将接受哪种货币？"),
    
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "en", "I'm willing to round to the nearest whole dollar"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "ja", "最も近いドルに丸める意思があります"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "es", "Estoy dispuesto a redondear al dólar más cercano"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "fr", "Je suis prêt à arrondir au dollar le plus proche"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "de", "Ich bin bereit, auf den nächsten Dollar zu runden"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "ar", "أنا مستعد للتقريب إلى أقرب دولار"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "hi", "मैं निकटतम पूरे डॉलर तक पूर्णांक करने के लिए तैयार हूँ"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "pt", "Estou disposto a arredondar para o dólar mais próximo"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "ru", "Я готов округлить до ближайшего доллара"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "sk", "Som ochotný zaokrúhliť na najbližší celý dolár"),
    ("WILLING_TO_ROUND_TO_NEAREST_DOLLAR", "zh", "我愿意四舍五入到最近的整数美元"),
    
    ("EXAMPLE_ROUNDING", "en", "Example: 130.79 USD rounds to 131 USD"),
    ("EXAMPLE_ROUNDING", "ja", "例：130.79 USDは131 USDに丸められます"),
    ("EXAMPLE_ROUNDING", "es", "Ejemplo: 130,79 USD se redondea a 131 USD"),
    ("EXAMPLE_ROUNDING", "fr", "Exemple : 130,79 USD arrondit à 131 USD"),
    ("EXAMPLE_ROUNDING", "de", "Beispiel: 130,79 USD werden auf 131 USD gerundet"),
    ("EXAMPLE_ROUNDING", "ar", "مثال: يتم تقريب 130.79 دولار إلى 131 دولار"),
    ("EXAMPLE_ROUNDING", "hi", "उदाहरण: 130.79 USD को 131 USD तक पूर्णांक किया जाता है"),
    ("EXAMPLE_ROUNDING", "pt", "Exemplo: 130,79 USD arredonda para 131 USD"),
    ("EXAMPLE_ROUNDING", "ru", "Пример: 130,79 USD округляется до 131 USD"),
    ("EXAMPLE_ROUNDING", "sk", "Príklad: 130,79 USD sa zaokrúhli na 131 USD"),
    ("EXAMPLE_ROUNDING", "zh", "示例：130.79 美元四舍五入到 131 美元"),
]

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)

cursor = db.cursor()

for key, lang, value in translations:
    cursor.execute(
        "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s",
        (key, lang, value, value)
    )
    print(f"Added/Updated: {key} ({lang})")

db.commit()
cursor.close()
db.close()

print("\n✅ Added 44 new translation keys for EditListingView step2 restructuring!")
