#!/usr/bin/env python3
"""
Migrate Search Currency View Keys to Database
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
SEARCH_CURRENCY_KEYS = {
    "SEARCH_CURRENCY": "Search Currency",
    "FIND_CURRENCY_EXCHANGE": "Find Currency Exchange",
    "WHAT_CURRENCY_DO_YOU_HAVE": "What currency do you have?",
    "WHAT_CURRENCY_DO_YOU_WANT": "What currency do you want?",
    "HOW_FAR_WILLING_TO_TRAVEL": "How far are you willing to travel?",
    "SELECT_CURRENCY": "Select currency",
    "ONE_MILE": "1 mile",
    "FIVE_MILES": "5 miles",
    "TEN_MILES": "10 miles",
    "TWENTY_FIVE_MILES": "25 miles",
    "FIFTY_MILES": "50 miles",
    "HUNDRED_MILES": "100 miles",
    "SEARCHING": "Searching...",
    "SEARCHING_FOR_CURRENCY_LISTINGS": "Searching for currency listings...",
    "SEARCH_ERROR": "Search Error",
    "TRY_AGAIN": "Try Again",
    "NO_LISTINGS_FOUND": "No listings found",
    "TRY_ADJUSTING_SEARCH": "Try adjusting your search or check back later for new listings.",
    "RESULTS_FOUND": "Results Found",
    "RECENT_LISTINGS": "Recent Listings",
    "MEETING_COLON": "Meeting:",
    "PRIVATE": "Private",
    "FLEXIBLE": "Flexible",
    "AVAILABLE_UNTIL_COLON": "Available until:",
    "WANTS": "Wants",
    "TRADES": "trades",
    "CONTACT_TRADER": "Contact Trader",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {
        "SEARCH_CURRENCY": "Buscar Moneda",
        "FIND_CURRENCY_EXCHANGE": "Encontrar Intercambio de Moneda",
        "WHAT_CURRENCY_DO_YOU_HAVE": "¿Qué moneda tienes?",
        "WHAT_CURRENCY_DO_YOU_WANT": "¿Qué moneda quieres?",
        "HOW_FAR_WILLING_TO_TRAVEL": "¿Qué tan lejos estás dispuesto a viajar?",
        "SELECT_CURRENCY": "Selecciona moneda",
        "ONE_MILE": "1 milla",
        "FIVE_MILES": "5 millas",
        "TEN_MILES": "10 millas",
        "TWENTY_FIVE_MILES": "25 millas",
        "FIFTY_MILES": "50 millas",
        "HUNDRED_MILES": "100 millas",
        "SEARCHING": "Buscando...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "Buscando listados de moneda...",
        "SEARCH_ERROR": "Error de búsqueda",
        "TRY_AGAIN": "Intentar de nuevo",
        "NO_LISTINGS_FOUND": "No se encontraron listados",
        "TRY_ADJUSTING_SEARCH": "Intenta ajustar tu búsqueda o regresa más tarde para nuevos listados.",
        "RESULTS_FOUND": "Resultados Encontrados",
        "RECENT_LISTINGS": "Listados Recientes",
        "MEETING_COLON": "Reunión:",
        "PRIVATE": "Privado",
        "FLEXIBLE": "Flexible",
        "AVAILABLE_UNTIL_COLON": "Disponible hasta:",
        "WANTS": "Quiere",
        "TRADES": "transacciones",
        "CONTACT_TRADER": "Contactar Comerciante",
    },
    "fr": {
        "SEARCH_CURRENCY": "Rechercher Devise",
        "FIND_CURRENCY_EXCHANGE": "Trouver Échange de Devises",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Quelle devise avez-vous?",
        "WHAT_CURRENCY_DO_YOU_WANT": "Quelle devise voulez-vous?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Jusqu'où êtes-vous disposé à voyager?",
        "SELECT_CURRENCY": "Sélectionner devise",
        "ONE_MILE": "1 km",
        "FIVE_MILES": "5 km",
        "TEN_MILES": "10 km",
        "TWENTY_FIVE_MILES": "25 km",
        "FIFTY_MILES": "50 km",
        "HUNDRED_MILES": "100 km",
        "SEARCHING": "Recherche en cours...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "Recherche des annonces de devises...",
        "SEARCH_ERROR": "Erreur de recherche",
        "TRY_AGAIN": "Réessayer",
        "NO_LISTINGS_FOUND": "Aucune annonce trouvée",
        "TRY_ADJUSTING_SEARCH": "Essayez d'ajuster votre recherche ou revenez plus tard pour de nouvelles annonces.",
        "RESULTS_FOUND": "Résultats Trouvés",
        "RECENT_LISTINGS": "Annonces Récentes",
        "MEETING_COLON": "Réunion:",
        "PRIVATE": "Privé",
        "FLEXIBLE": "Flexible",
        "AVAILABLE_UNTIL_COLON": "Disponible jusqu'à:",
        "WANTS": "Veut",
        "TRADES": "échanges",
        "CONTACT_TRADER": "Contacter le Commerçant",
    },
    "de": {
        "SEARCH_CURRENCY": "Währung Suchen",
        "FIND_CURRENCY_EXCHANGE": "Währungstausch Finden",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Welche Währung haben Sie?",
        "WHAT_CURRENCY_DO_YOU_WANT": "Welche Währung möchten Sie?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Wie weit sind Sie bereit zu reisen?",
        "SELECT_CURRENCY": "Währung wählen",
        "ONE_MILE": "1 Meile",
        "FIVE_MILES": "5 Meilen",
        "TEN_MILES": "10 Meilen",
        "TWENTY_FIVE_MILES": "25 Meilen",
        "FIFTY_MILES": "50 Meilen",
        "HUNDRED_MILES": "100 Meilen",
        "SEARCHING": "Wird gesucht...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "Suche nach Währungsangeboten...",
        "SEARCH_ERROR": "Suchfehler",
        "TRY_AGAIN": "Erneut Versuchen",
        "NO_LISTINGS_FOUND": "Keine Angebote gefunden",
        "TRY_ADJUSTING_SEARCH": "Versuchen Sie, Ihre Suche anzupassen, oder kehren Sie später zurück, um neue Angebote zu sehen.",
        "RESULTS_FOUND": "Ergebnisse Gefunden",
        "RECENT_LISTINGS": "Aktuelle Angebote",
        "MEETING_COLON": "Treffen:",
        "PRIVATE": "Privat",
        "FLEXIBLE": "Flexibel",
        "AVAILABLE_UNTIL_COLON": "Verfügbar bis:",
        "WANTS": "Möchte",
        "TRADES": "Transaktionen",
        "CONTACT_TRADER": "Trader Kontaktieren",
    },
    "pt": {
        "SEARCH_CURRENCY": "Pesquisar Moeda",
        "FIND_CURRENCY_EXCHANGE": "Encontrar Câmbio de Moeda",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Que moeda você tem?",
        "WHAT_CURRENCY_DO_YOU_WANT": "Que moeda você quer?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Até que distância você está disposto a viajar?",
        "SELECT_CURRENCY": "Selecionar moeda",
        "ONE_MILE": "1 milha",
        "FIVE_MILES": "5 milhas",
        "TEN_MILES": "10 milhas",
        "TWENTY_FIVE_MILES": "25 milhas",
        "FIFTY_MILES": "50 milhas",
        "HUNDRED_MILES": "100 milhas",
        "SEARCHING": "Pesquisando...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "Pesquisando anúncios de moeda...",
        "SEARCH_ERROR": "Erro de Pesquisa",
        "TRY_AGAIN": "Tentar Novamente",
        "NO_LISTINGS_FOUND": "Nenhum anúncio encontrado",
        "TRY_ADJUSTING_SEARCH": "Tente ajustar sua pesquisa ou volte mais tarde para novos anúncios.",
        "RESULTS_FOUND": "Resultados Encontrados",
        "RECENT_LISTINGS": "Anúncios Recentes",
        "MEETING_COLON": "Reunião:",
        "PRIVATE": "Privado",
        "FLEXIBLE": "Flexível",
        "AVAILABLE_UNTIL_COLON": "Disponível até:",
        "WANTS": "Quer",
        "TRADES": "transações",
        "CONTACT_TRADER": "Contactar Comerciante",
    },
    "ja": {
        "SEARCH_CURRENCY": "通貨を検索",
        "FIND_CURRENCY_EXCHANGE": "通貨両替を検索",
        "WHAT_CURRENCY_DO_YOU_HAVE": "どの通貨を持っていますか？",
        "WHAT_CURRENCY_DO_YOU_WANT": "どの通貨が欲しいですか？",
        "HOW_FAR_WILLING_TO_TRAVEL": "どのくらい遠くまで移動できますか？",
        "SELECT_CURRENCY": "通貨を選択",
        "ONE_MILE": "1マイル",
        "FIVE_MILES": "5マイル",
        "TEN_MILES": "10マイル",
        "TWENTY_FIVE_MILES": "25マイル",
        "FIFTY_MILES": "50マイル",
        "HUNDRED_MILES": "100マイル",
        "SEARCHING": "検索中...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "通貨リストを検索中...",
        "SEARCH_ERROR": "検索エラー",
        "TRY_AGAIN": "もう一度試す",
        "NO_LISTINGS_FOUND": "リストが見つかりません",
        "TRY_ADJUSTING_SEARCH": "検索を調整するか、後で戻ってきて新しいリストを確認してください。",
        "RESULTS_FOUND": "結果が見つかりました",
        "RECENT_LISTINGS": "最近のリスト",
        "MEETING_COLON": "ミーティング:",
        "PRIVATE": "プライベート",
        "FLEXIBLE": "柔軟",
        "AVAILABLE_UNTIL_COLON": "有効期限:",
        "WANTS": "欲しい",
        "TRADES": "取引",
        "CONTACT_TRADER": "トレーダーに連絡",
    },
    "zh": {
        "SEARCH_CURRENCY": "搜索货币",
        "FIND_CURRENCY_EXCHANGE": "查找货币兑换",
        "WHAT_CURRENCY_DO_YOU_HAVE": "你有什么货币？",
        "WHAT_CURRENCY_DO_YOU_WANT": "你想要什么货币？",
        "HOW_FAR_WILLING_TO_TRAVEL": "你愿意走多远？",
        "SELECT_CURRENCY": "选择货币",
        "ONE_MILE": "1英里",
        "FIVE_MILES": "5英里",
        "TEN_MILES": "10英里",
        "TWENTY_FIVE_MILES": "25英里",
        "FIFTY_MILES": "50英里",
        "HUNDRED_MILES": "100英里",
        "SEARCHING": "搜索中...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "搜索货币列表...",
        "SEARCH_ERROR": "搜索错误",
        "TRY_AGAIN": "再试一次",
        "NO_LISTINGS_FOUND": "未找到列表",
        "TRY_ADJUSTING_SEARCH": "尝试调整搜索或稍后返回查看新列表。",
        "RESULTS_FOUND": "找到结果",
        "RECENT_LISTINGS": "最近的列表",
        "MEETING_COLON": "会议:",
        "PRIVATE": "私密",
        "FLEXIBLE": "灵活",
        "AVAILABLE_UNTIL_COLON": "有效期至:",
        "WANTS": "想要",
        "TRADES": "交易",
        "CONTACT_TRADER": "联系交易者",
    },
    "ru": {
        "SEARCH_CURRENCY": "Поиск Валюты",
        "FIND_CURRENCY_EXCHANGE": "Найти Обмен Валюты",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Какая у вас валюта?",
        "WHAT_CURRENCY_DO_YOU_WANT": "Какую валюту вы хотите?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Как далеко вы готовы путешествовать?",
        "SELECT_CURRENCY": "Выбрать валюту",
        "ONE_MILE": "1 миля",
        "FIVE_MILES": "5 миль",
        "TEN_MILES": "10 миль",
        "TWENTY_FIVE_MILES": "25 миль",
        "FIFTY_MILES": "50 миль",
        "HUNDRED_MILES": "100 миль",
        "SEARCHING": "Поиск...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "Поиск списков валют...",
        "SEARCH_ERROR": "Ошибка поиска",
        "TRY_AGAIN": "Попробуйте Снова",
        "NO_LISTINGS_FOUND": "Списки не найдены",
        "TRY_ADJUSTING_SEARCH": "Попробуйте отрегулировать поиск или вернитесь позже, чтобы увидеть новые списки.",
        "RESULTS_FOUND": "Результаты Найдены",
        "RECENT_LISTINGS": "Недавние Списки",
        "MEETING_COLON": "Встреча:",
        "PRIVATE": "Приватный",
        "FLEXIBLE": "Гибкий",
        "AVAILABLE_UNTIL_COLON": "Доступно до:",
        "WANTS": "Хочет",
        "TRADES": "сделки",
        "CONTACT_TRADER": "Связаться с Трейдером",
    },
    "ar": {
        "SEARCH_CURRENCY": "البحث عن العملة",
        "FIND_CURRENCY_EXCHANGE": "العثور على صرف العملات",
        "WHAT_CURRENCY_DO_YOU_HAVE": "ما العملة التي لديك؟",
        "WHAT_CURRENCY_DO_YOU_WANT": "ما العملة التي تريدها؟",
        "HOW_FAR_WILLING_TO_TRAVEL": "إلى أي مدى أنت على استعداد للسفر؟",
        "SELECT_CURRENCY": "اختر العملة",
        "ONE_MILE": "1 ميل",
        "FIVE_MILES": "5 أميال",
        "TEN_MILES": "10 أميال",
        "TWENTY_FIVE_MILES": "25 ميل",
        "FIFTY_MILES": "50 ميل",
        "HUNDRED_MILES": "100 ميل",
        "SEARCHING": "جاري البحث...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "البحث عن قوائم العملات...",
        "SEARCH_ERROR": "خطأ في البحث",
        "TRY_AGAIN": "حاول مرة أخرى",
        "NO_LISTINGS_FOUND": "لم يتم العثور على قوائم",
        "TRY_ADJUSTING_SEARCH": "حاول تعديل البحث أو العودة لاحقًا لمشاهدة القوائم الجديدة.",
        "RESULTS_FOUND": "تم العثور على النتائج",
        "RECENT_LISTINGS": "القوائم الأخيرة",
        "MEETING_COLON": "الاجتماع:",
        "PRIVATE": "خاص",
        "FLEXIBLE": "مرن",
        "AVAILABLE_UNTIL_COLON": "متاح حتى:",
        "WANTS": "يريد",
        "TRADES": "التجارة",
        "CONTACT_TRADER": "الاتصال بالمتاجر",
    },
    "hi": {
        "SEARCH_CURRENCY": "मुद्रा खोजें",
        "FIND_CURRENCY_EXCHANGE": "मुद्रा विनिमय खोजें",
        "WHAT_CURRENCY_DO_YOU_HAVE": "आपके पास कौन सी मुद्रा है?",
        "WHAT_CURRENCY_DO_YOU_WANT": "आप कौन सी मुद्रा चाहते हैं?",
        "HOW_FAR_WILLING_TO_TRAVEL": "आप कितनी दूर यात्रा करने के लिए तैयार हैं?",
        "SELECT_CURRENCY": "मुद्रा चुनें",
        "ONE_MILE": "1 मील",
        "FIVE_MILES": "5 मील",
        "TEN_MILES": "10 मील",
        "TWENTY_FIVE_MILES": "25 मील",
        "FIFTY_MILES": "50 मील",
        "HUNDRED_MILES": "100 मील",
        "SEARCHING": "खोज रहे हैं...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "मुद्रा सूचियों की खोज जारी है...",
        "SEARCH_ERROR": "खोज त्रुटि",
        "TRY_AGAIN": "फिर से प्रयास करें",
        "NO_LISTINGS_FOUND": "कोई सूची नहीं मिली",
        "TRY_ADJUSTING_SEARCH": "अपनी खोज को समायोजित करने का प्रयास करें या नई सूचियों के लिए बाद में वापस आएं।",
        "RESULTS_FOUND": "परिणाम मिले",
        "RECENT_LISTINGS": "हाल की सूचियां",
        "MEETING_COLON": "बैठक:",
        "PRIVATE": "निजी",
        "FLEXIBLE": "लचकदार",
        "AVAILABLE_UNTIL_COLON": "उपलब्ध तक:",
        "WANTS": "चाहता है",
        "TRADES": "व्यापार",
        "CONTACT_TRADER": "व्यापारी से संपर्क करें",
    },
    "sk": {
        "SEARCH_CURRENCY": "Hľadať Menu",
        "FIND_CURRENCY_EXCHANGE": "Nájsť Výmenu Mien",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Akú menu máte?",
        "WHAT_CURRENCY_DO_YOU_WANT": "Akú menu chcete?",
        "HOW_FAR_WILLING_TO_TRAVEL": "Ako ďaleko ste ochotní cestovať?",
        "SELECT_CURRENCY": "Vyberte menu",
        "ONE_MILE": "1 míľa",
        "FIVE_MILES": "5 míľ",
        "TEN_MILES": "10 míľ",
        "TWENTY_FIVE_MILES": "25 míľ",
        "FIFTY_MILES": "50 míľ",
        "HUNDRED_MILES": "100 míľ",
        "SEARCHING": "Hľadám...",
        "SEARCHING_FOR_CURRENCY_LISTINGS": "Hľadanie zoznamov mien...",
        "SEARCH_ERROR": "Chyba pri hľadaní",
        "TRY_AGAIN": "Skúsiť Znova",
        "NO_LISTINGS_FOUND": "Nenašli sa žiadne zoznamy",
        "TRY_ADJUSTING_SEARCH": "Skúste upraviť vyhľadávanie alebo sa vráťte neskôr a pozrite si nové zoznamy.",
        "RESULTS_FOUND": "Nájdené Výsledky",
        "RECENT_LISTINGS": "Nedávne Zoznamy",
        "MEETING_COLON": "Stretnutie:",
        "PRIVATE": "Súkromný",
        "FLEXIBLE": "Flexibilný",
        "AVAILABLE_UNTIL_COLON": "Dostupné do:",
        "WANTS": "Chce",
        "TRADES": "obchody",
        "CONTACT_TRADER": "Kontaktovať Obchodníka",
    },
}


def migrate():
    """Insert or update search currency view keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("📝 Inserting English translations...")
        for key, value in SEARCH_CURRENCY_KEYS.items():
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
