#!/usr/bin/env python3
"""
Migration script to add ContentView (landing page) localization keys for all languages.
"""

import sys
from datetime import datetime

sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Define all strings to add with translations for all 11 languages
CONTENT_VIEW_STRINGS = {
    "NICE_TRADERS_HEADER": {
        "en": "NICE Traders",
        "es": "NICE Traders",
        "fr": "NICE Traders",
        "de": "NICE Traders",
        "pt": "NICE Traders",
        "ja": "NICE Traders",
        "zh": "NICE Traders",
        "ru": "NICE Traders",
        "ar": "NICE Traders",
        "hi": "NICE Traders",
        "sk": "NICE Traders"
    },
    "NEIGHBORHOOD_CURRENCY_EXCHANGE": {
        "en": "Neighborhood International Currency Exchange",
        "es": "Intercambio Internacional de Moneda del Barrio",
        "fr": "Échange International de Devises du Quartier",
        "de": "Internationaler Währungsaustausch in der Nachbarschaft",
        "pt": "Troca Internacional de Moedas do Bairro",
        "ja": "近所の国際通貨交換",
        "zh": "街区国际货币交换",
        "ru": "Международный обмен валюты по соседству",
        "ar": "تبديل العملات الدولية بالحي",
        "hi": "पड़ोस अंतर्राष्ट्रीय मुद्रा विनिमय",
        "sk": "Susedský medzinárodný výmena mien"
    },
    "EXCHANGE_CURRENCY_LOCALLY": {
        "en": "Exchange Currency Locally",
        "es": "Cambia Moneda Localmente",
        "fr": "Échanger des Devises Localement",
        "de": "Tauschen Sie Währungen lokal",
        "pt": "Troque Moeda Localmente",
        "ja": "地元で通貨を交換",
        "zh": "在本地交换货币",
        "ru": "Обменять валюту локально",
        "ar": "تبديل العملات محليًا",
        "hi": "स्थानीय रूप से मुद्रा विनिमय करें",
        "sk": "Výmena mien lokálne"
    },
    "LANDING_PAGE_DESCRIPTION": {
        "en": "Connect with neighbors to exchange foreign currency safely and affordably. Skip the expensive fees and get the cash you need from your community.",
        "es": "Conecta con tus vecinos para cambiar moneda extranjera de forma segura y asequible. Salta las costosas comisiones y obtén el dinero que necesitas de tu comunidad.",
        "fr": "Connectez-vous avec vos voisins pour échanger des devises étrangères en toute sécurité et à un coût abordable. Évitez les frais élevés et obtenez l'argent dont vous avez besoin auprès de votre communauté.",
        "de": "Verbinden Sie sich mit Ihren Nachbarn, um Fremdwährungen sicher und preiswert auszutauschen. Sparen Sie sich die teuren Gebühren und holen Sie sich das Geld, das Sie benötigen, von Ihrer Gemeinde.",
        "pt": "Conecte-se com seus vizinhos para trocar moeda estrangeira com segurança e acessibilidade. Pule as taxas caras e obtenha o dinheiro que você precisa da sua comunidade.",
        "ja": "隣人と連絡を取り合って、外国通貨を安全で手頃な価格で交換してください。高い手数料をスキップして、あなたのコミュニティから必要な現金を取得してください。",
        "zh": "与您的邻居联系以安全且经济实惠的方式交换外币。跳过昂贵的费用，从您的社区获取所需的现金。",
        "ru": "Свяжитесь со своими соседями, чтобы обменять иностранную валюту безопасно и доступно. Пропустите дорогие комиссии и получите нужные вам деньги из вашего сообщества.",
        "ar": "تواصل مع جيرانك لتبديل العملات الأجنبية بأمان وبأسعار معقولة. تخطي الرسوم باهظة واحصل على الأموال التي تحتاجها من مجتمعك.",
        "hi": "अपने पड़ोसियों के साथ जुड़ें ताकि विदेशी मुद्रा को सुरक्षित और सस्ते तरीके से विनिमय किया जा सके। महंगे शुल्क को छोड़ दें और अपने समुदाय से आवश्यक नकदी प्राप्त करें।",
        "sk": "Spojte sa so svojimi susedmi na bezpečnú a dostupnú výmenu cudzích mien. Preskočte drahé poplatky a získajte peniaze, ktoré potrebujete od svojej komunity."
    },
    "FIND_NEARBY": {
        "en": "Find Nearby",
        "es": "Encontrar Cercano",
        "fr": "Trouver à Proximité",
        "de": "In der Nähe finden",
        "pt": "Encontrar Próximo",
        "ja": "近くを探す",
        "zh": "附近查找",
        "ru": "Найти поблизости",
        "ar": "البحث بالقرب",
        "hi": "पास खोजें",
        "sk": "Nájsť blízko"
    },
    "FIND_NEARBY_DESC": {
        "en": "See currency exchanges happening in your neighborhood",
        "es": "Ver cambios de divisas sucediendo en tu vecindario",
        "fr": "Voir les échanges de devises se produisant dans votre quartier",
        "de": "Sehen Sie Währungsumtausche in Ihrer Nachbarschaft",
        "pt": "Veja trocas de moedas acontecendo em seu bairro",
        "ja": "あなたの近所で起こっている通貨交換を見てください",
        "zh": "查看您所在社区中发生的货币交换",
        "ru": "Посмотрите обмены валют, происходящие в вашем районе",
        "ar": "شاهد عمليات تبديل العملات التي تحدث في حيك",
        "hi": "अपने पड़ोस में होने वाले मुद्रा विनिमय देखें",
        "sk": "Pozrite si výmeny mien v kminičstve"
    },
    "BETTER_RATES": {
        "en": "Better Rates",
        "es": "Mejores Tasas",
        "fr": "Meilleurs Taux",
        "de": "Bessere Sätze",
        "pt": "Melhores Taxas",
        "ja": "より良いレート",
        "zh": "更好的利率",
        "ru": "Лучшие ставки",
        "ar": "أسعار أفضل",
        "hi": "बेहतर दरें",
        "sk": "Lepšie sadzby"
    },
    "BETTER_RATES_DESC": {
        "en": "Avoid high bank and airport exchange fees",
        "es": "Evita altas tarifas de cambio de banco y aeropuerto",
        "fr": "Évitez les frais de change élevés des banques et des aéroports",
        "de": "Vermeiden Sie hohe Bank- und Flughafenumtauschgebühren",
        "pt": "Evite altas taxas de câmbio de banco e aeroporto",
        "ja": "銀行と空港の高い両替手数料を避ける",
        "zh": "避免高额的银行和机场兑换费",
        "ru": "Избежите высоких комиссий банков и аэропортов",
        "ar": "تجنب رسوم الصرف العالية للبنوك والمطارات",
        "hi": "बैंक और हवाई अड्डे की उच्च विनिमय शुल्क से बचें",
        "sk": "Vyhýbajte sa vysokým bankovým a letiskovým výmenným poplatkom"
    },
    "SAFE_EXCHANGES": {
        "en": "Safe Exchanges",
        "es": "Cambios Seguros",
        "fr": "Échanges Sûrs",
        "de": "Sichere Umtausche",
        "pt": "Trocas Seguras",
        "ja": "安全な交換",
        "zh": "安全交换",
        "ru": "Безопасные обмены",
        "ar": "التبادلات الآمنة",
        "hi": "सुरक्षित विनिमय",
        "sk": "Bezpečné výmeny"
    },
    "SAFE_EXCHANGES_DESC": {
        "en": "Meet in public places with user ratings for safety",
        "es": "Reúnete en lugares públicos con calificaciones de usuarios para seguridad",
        "fr": "Rencontrez-vous dans des lieux publics avec les évaluations des utilisateurs pour la sécurité",
        "de": "Treffen Sie sich an öffentlichen Orten mit Benutzerbewertungen für Sicherheit",
        "pt": "Encontre-se em locais públicos com avaliações de usuários para segurança",
        "ja": "安全のためのユーザー評価を備えた公共の場所で会う",
        "zh": "在公共场所与用户安全评分相符的地方见面",
        "ru": "Встречайтесь в общественных местах с оценками пользователей для безопасности",
        "ar": "التقِ في الأماكن العامة مع تقييمات المستخدمين للسلامة",
        "hi": "सुरक्षा के लिए उपयोगकर्ता रेटिंग के साथ सार्वजनिक स्थानों पर मिलें",
        "sk": "Stretávajte sa na verejných miestach s hodnoteniami používateľov pre bezpečnosť"
    },
    "GET_STARTED": {
        "en": "Get Started",
        "es": "Empezar",
        "fr": "Commencer",
        "de": "Anfangen",
        "pt": "Começar",
        "ja": "始めましょう",
        "zh": "开始使用",
        "ru": "Начать",
        "ar": "ابدأ",
        "hi": "शुरू करो",
        "sk": "Začať"
    },
    "LEARN_MORE": {
        "en": "Learn More",
        "es": "Aprende Más",
        "fr": "En Savoir Plus",
        "de": "Mehr Erfahren",
        "pt": "Saiba Mais",
        "ja": "詳しく知る",
        "zh": "了解更多",
        "ru": "Узнать больше",
        "ar": "اعرف أكثر",
        "hi": "अधिक जानें",
        "sk": "Zistiť viac"
    },
    "LANDING_FOOTER": {
        "en": "Join thousands of travelers saving money on currency exchange",
        "es": "Únete a miles de viajeros ahorrando dinero en cambio de divisas",
        "fr": "Rejoignez des milliers de voyageurs économisant de l'argent sur l'échange de devises",
        "de": "Schließen Sie sich Tausenden von Reisenden an, die beim Währungsumtausch Geld sparen",
        "pt": "Junte-se a milhares de viajantes economizando dinheiro em troca de moedas",
        "ja": "通貨交換でお金を節約する何千人もの旅行者に参加してください",
        "zh": "加入数千名旅行者，在货币兑换中节省资金",
        "ru": "Присоединитесь к тысячам путешественников, экономящих деньги при обмене валюты",
        "ar": "انضم إلى آلاف المسافرين الذين يوفرون الأموال على صرف العملات الأجنبية",
        "hi": "मुद्रा विनिमय पर पैसा बचाने वाले हजारों यात्रियों में शामिल हों",
        "sk": "Присоединитесь к tisícom cestovateľom, ktorí ušetria peniaze na výmene meny"
    },
    "ALREADY_HAVE_ACCOUNT": {
        "en": "Already have an account?",
        "es": "¿Ya tienes una cuenta?",
        "fr": "Vous avez déjà un compte?",
        "de": "Haben Sie bereits ein Konto?",
        "pt": "Já tem uma conta?",
        "ja": "既にアカウントをお持ちですか？",
        "zh": "已有账户？",
        "ru": "Уже есть аккаунт?",
        "ar": "هل لديك حساب بالفعل؟",
        "hi": "क्या आपके पास पहले से खाता है?",
        "sk": "Už máte účet?"
    },
    "SIGN_IN": {
        "en": "Sign In",
        "es": "Iniciar Sesión",
        "fr": "Se Connecter",
        "de": "Anmelden",
        "pt": "Entrar",
        "ja": "サインイン",
        "zh": "登录",
        "ru": "Вход",
        "ar": "تسجيل الدخول",
        "hi": "साइन इन करें",
        "sk": "Prihlásiť sa"
    },
    "CHECKING_SESSION": {
        "en": "Checking session...",
        "es": "Comprobando sesión...",
        "fr": "Vérification de la session...",
        "de": "Sitzung wird überprüft...",
        "pt": "Verificando sessão...",
        "ja": "セッションを確認中...",
        "zh": "正在检查会话...",
        "ru": "Проверка сессии...",
        "ar": "جاري التحقق من الجلسة...",
        "hi": "सत्र की जांच...",
        "sk": "Kontrola sedenia..."
    }
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("=== CONTENT VIEW KEYS MIGRATION ===\n")
        
        # Extract English translations first
        english_translations = {key: translations.get('en', '') for key, translations in CONTENT_VIEW_STRINGS.items()}
        
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
        language_results = {}
        for lang_code in ['es', 'fr', 'de', 'pt', 'ja', 'zh', 'ru', 'ar', 'hi', 'sk']:
            inserted_count = 0
            for key, translations in CONTENT_VIEW_STRINGS.items():
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
