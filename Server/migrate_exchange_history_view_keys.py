#!/usr/bin/env python3
"""
Migration script to add Exchange History View translation keys
Adds 29 new translation keys for ExchangeHistoryView.swift localization
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

# Translation keys and their English values
TRANSLATION_KEYS = {
    "EXCHANGE_HISTORY": "Exchange History",
    "TOTAL_EXCHANGES": "Total Exchanges",
    "COMPLETED_EXCHANGES": "Completed",
    "BOUGHT_EXCHANGES": "Bought",
    "SOLD_EXCHANGES": "Sold",
    "FILTER_HISTORY": "Filter History",
    "CLEAR_ALL": "Clear All",
    "FILTER_TYPE": "Type",
    "FILTER_CURRENCY": "Currency",
    "FILTER_STATUS": "Status",
    "FILTER_TIMEFRAME": "Timeframe",
    "ALL_TYPES": "All Types",
    "ALL_CURRENCIES": "All Currencies",
    "ALL_STATUS": "All Status",
    "COMPLETED": "Completed",
    "PENDING": "Pending",
    "CANCELLED": "Cancelled",
    "ALL_TIME": "All Time",
    "LAST_30_DAYS": "Last 30 Days",
    "LAST_90_DAYS": "Last 90 Days",
    "LAST_YEAR": "Last Year",
    "EXCHANGES_COUNT": "Exchanges",
    "LOADING_EXCHANGE_HISTORY": "Loading exchange history...",
    "NO_EXCHANGES_FOUND": "No exchanges found",
    "NO_EXCHANGES_YET": "You haven't completed any exchanges yet.",
    "NO_MATCHING_EXCHANGES": "No exchanges match your current filters.",
    "EXCHANGE_WITH": "with",
    "TRY_AGAIN": "Try Again",
    "BUY_LABEL": "Bought",
    "SELL_LABEL": "Sold",
}

# Language translations
LANGUAGE_TRANSLATIONS = {
    "es": {
        "EXCHANGE_HISTORY": "Historial de Cambios",
        "TOTAL_EXCHANGES": "Total de Cambios",
        "COMPLETED_EXCHANGES": "Completados",
        "BOUGHT_EXCHANGES": "Comprados",
        "SOLD_EXCHANGES": "Vendidos",
        "FILTER_HISTORY": "Filtrar Historial",
        "CLEAR_ALL": "Limpiar Todo",
        "FILTER_TYPE": "Tipo",
        "FILTER_CURRENCY": "Moneda",
        "FILTER_STATUS": "Estado",
        "FILTER_TIMEFRAME": "Período",
        "ALL_TYPES": "Todos los Tipos",
        "ALL_CURRENCIES": "Todas las Monedas",
        "ALL_STATUS": "Todos los Estados",
        "COMPLETED": "Completado",
        "PENDING": "Pendiente",
        "CANCELLED": "Cancelado",
        "ALL_TIME": "Todo el Tiempo",
        "LAST_30_DAYS": "Últimos 30 Días",
        "LAST_90_DAYS": "Últimos 90 Días",
        "LAST_YEAR": "Último Año",
        "EXCHANGES_COUNT": "Cambios",
        "LOADING_EXCHANGE_HISTORY": "Cargando historial de cambios...",
        "NO_EXCHANGES_FOUND": "No se encontraron cambios",
        "NO_EXCHANGES_YET": "Aún no has completado ningún cambio.",
        "NO_MATCHING_EXCHANGES": "No hay cambios que coincidan con tus filtros actuales.",
        "EXCHANGE_WITH": "con",
        "TRY_AGAIN": "Intentar de Nuevo",
        "BUY_LABEL": "Comprado",
        "SELL_LABEL": "Vendido",
    },
    "fr": {
        "EXCHANGE_HISTORY": "Historique des Échanges",
        "TOTAL_EXCHANGES": "Total des Échanges",
        "COMPLETED_EXCHANGES": "Complétés",
        "BOUGHT_EXCHANGES": "Achetés",
        "SOLD_EXCHANGES": "Vendus",
        "FILTER_HISTORY": "Filtrer l'Historique",
        "CLEAR_ALL": "Effacer Tout",
        "FILTER_TYPE": "Type",
        "FILTER_CURRENCY": "Devise",
        "FILTER_STATUS": "Statut",
        "FILTER_TIMEFRAME": "Période",
        "ALL_TYPES": "Tous les Types",
        "ALL_CURRENCIES": "Toutes les Devises",
        "ALL_STATUS": "Tous les Statuts",
        "COMPLETED": "Complété",
        "PENDING": "En Attente",
        "CANCELLED": "Annulé",
        "ALL_TIME": "Tout le Temps",
        "LAST_30_DAYS": "30 Derniers Jours",
        "LAST_90_DAYS": "90 Derniers Jours",
        "LAST_YEAR": "Dernière Année",
        "EXCHANGES_COUNT": "Échanges",
        "LOADING_EXCHANGE_HISTORY": "Chargement de l'historique des échanges...",
        "NO_EXCHANGES_FOUND": "Aucun échange trouvé",
        "NO_EXCHANGES_YET": "Vous n'avez pas encore complété d'échanges.",
        "NO_MATCHING_EXCHANGES": "Aucun échange ne correspond à vos filtres actuels.",
        "EXCHANGE_WITH": "avec",
        "TRY_AGAIN": "Réessayer",
        "BUY_LABEL": "Acheté",
        "SELL_LABEL": "Vendu",
    },
    "de": {
        "EXCHANGE_HISTORY": "Austauschverlauf",
        "TOTAL_EXCHANGES": "Gesamtaustausche",
        "COMPLETED_EXCHANGES": "Abgeschlossen",
        "BOUGHT_EXCHANGES": "Gekauft",
        "SOLD_EXCHANGES": "Verkauft",
        "FILTER_HISTORY": "Verlauf Filtern",
        "CLEAR_ALL": "Alles Löschen",
        "FILTER_TYPE": "Typ",
        "FILTER_CURRENCY": "Währung",
        "FILTER_STATUS": "Status",
        "FILTER_TIMEFRAME": "Zeitraum",
        "ALL_TYPES": "Alle Typen",
        "ALL_CURRENCIES": "Alle Währungen",
        "ALL_STATUS": "Alle Status",
        "COMPLETED": "Abgeschlossen",
        "PENDING": "Ausstehend",
        "CANCELLED": "Storniert",
        "ALL_TIME": "Ganzer Zeitraum",
        "LAST_30_DAYS": "Letzte 30 Tage",
        "LAST_90_DAYS": "Letzte 90 Tage",
        "LAST_YEAR": "Letztes Jahr",
        "EXCHANGES_COUNT": "Austausche",
        "LOADING_EXCHANGE_HISTORY": "Austauschverlauf wird geladen...",
        "NO_EXCHANGES_FOUND": "Keine Austausche gefunden",
        "NO_EXCHANGES_YET": "Sie haben noch keine Austausche abgeschlossen.",
        "NO_MATCHING_EXCHANGES": "Keine Austausche entsprechen Ihren aktuellen Filtern.",
        "EXCHANGE_WITH": "mit",
        "TRY_AGAIN": "Erneut Versuchen",
        "BUY_LABEL": "Gekauft",
        "SELL_LABEL": "Verkauft",
    },
    "pt": {
        "EXCHANGE_HISTORY": "Histórico de Trocas",
        "TOTAL_EXCHANGES": "Total de Trocas",
        "COMPLETED_EXCHANGES": "Concluídas",
        "BOUGHT_EXCHANGES": "Compradas",
        "SOLD_EXCHANGES": "Vendidas",
        "FILTER_HISTORY": "Filtrar Histórico",
        "CLEAR_ALL": "Limpar Tudo",
        "FILTER_TYPE": "Tipo",
        "FILTER_CURRENCY": "Moeda",
        "FILTER_STATUS": "Status",
        "FILTER_TIMEFRAME": "Período",
        "ALL_TYPES": "Todos os Tipos",
        "ALL_CURRENCIES": "Todas as Moedas",
        "ALL_STATUS": "Todos os Status",
        "COMPLETED": "Concluído",
        "PENDING": "Pendente",
        "CANCELLED": "Cancelado",
        "ALL_TIME": "Todo o Tempo",
        "LAST_30_DAYS": "Últimos 30 Dias",
        "LAST_90_DAYS": "Últimos 90 Dias",
        "LAST_YEAR": "Último Ano",
        "EXCHANGES_COUNT": "Trocas",
        "LOADING_EXCHANGE_HISTORY": "Carregando histórico de trocas...",
        "NO_EXCHANGES_FOUND": "Nenhuma troca encontrada",
        "NO_EXCHANGES_YET": "Você ainda não concluiu nenhuma troca.",
        "NO_MATCHING_EXCHANGES": "Nenhuma troca corresponde aos seus filtros atuais.",
        "EXCHANGE_WITH": "com",
        "TRY_AGAIN": "Tentar Novamente",
        "BUY_LABEL": "Comprado",
        "SELL_LABEL": "Vendido",
    },
    "ja": {
        "EXCHANGE_HISTORY": "交換履歴",
        "TOTAL_EXCHANGES": "合計交換数",
        "COMPLETED_EXCHANGES": "完了",
        "BOUGHT_EXCHANGES": "購入",
        "SOLD_EXCHANGES": "売却",
        "FILTER_HISTORY": "履歴をフィルタリング",
        "CLEAR_ALL": "すべてクリア",
        "FILTER_TYPE": "種類",
        "FILTER_CURRENCY": "通貨",
        "FILTER_STATUS": "ステータス",
        "FILTER_TIMEFRAME": "期間",
        "ALL_TYPES": "すべての種類",
        "ALL_CURRENCIES": "すべての通貨",
        "ALL_STATUS": "すべてのステータス",
        "COMPLETED": "完了",
        "PENDING": "保留中",
        "CANCELLED": "キャンセル",
        "ALL_TIME": "すべての期間",
        "LAST_30_DAYS": "過去30日間",
        "LAST_90_DAYS": "過去90日間",
        "LAST_YEAR": "過去1年間",
        "EXCHANGES_COUNT": "交換",
        "LOADING_EXCHANGE_HISTORY": "交換履歴を読み込み中...",
        "NO_EXCHANGES_FOUND": "交換が見つかりません",
        "NO_EXCHANGES_YET": "まだ交換を完了していません。",
        "NO_MATCHING_EXCHANGES": "現在のフィルターに一致する交換がありません。",
        "EXCHANGE_WITH": "と",
        "TRY_AGAIN": "もう一度試す",
        "BUY_LABEL": "購入",
        "SELL_LABEL": "売却",
    },
    "zh": {
        "EXCHANGE_HISTORY": "兑换历史",
        "TOTAL_EXCHANGES": "总兑换数",
        "COMPLETED_EXCHANGES": "已完成",
        "BOUGHT_EXCHANGES": "已购买",
        "SOLD_EXCHANGES": "已出售",
        "FILTER_HISTORY": "筛选历史",
        "CLEAR_ALL": "清除全部",
        "FILTER_TYPE": "类型",
        "FILTER_CURRENCY": "货币",
        "FILTER_STATUS": "状态",
        "FILTER_TIMEFRAME": "时间范围",
        "ALL_TYPES": "所有类型",
        "ALL_CURRENCIES": "所有货币",
        "ALL_STATUS": "所有状态",
        "COMPLETED": "已完成",
        "PENDING": "待处理",
        "CANCELLED": "已取消",
        "ALL_TIME": "所有时间",
        "LAST_30_DAYS": "过去30天",
        "LAST_90_DAYS": "过去90天",
        "LAST_YEAR": "过去一年",
        "EXCHANGES_COUNT": "兑换",
        "LOADING_EXCHANGE_HISTORY": "正在加载兑换历史...",
        "NO_EXCHANGES_FOUND": "未找到兑换记录",
        "NO_EXCHANGES_YET": "您还没有完成任何兑换。",
        "NO_MATCHING_EXCHANGES": "没有兑换与您当前的筛选条件匹配。",
        "EXCHANGE_WITH": "与",
        "TRY_AGAIN": "重试",
        "BUY_LABEL": "已购买",
        "SELL_LABEL": "已出售",
    },
    "ru": {
        "EXCHANGE_HISTORY": "История Обмена",
        "TOTAL_EXCHANGES": "Всего Обменов",
        "COMPLETED_EXCHANGES": "Завершено",
        "BOUGHT_EXCHANGES": "Куплено",
        "SOLD_EXCHANGES": "Продано",
        "FILTER_HISTORY": "Фильтровать Историю",
        "CLEAR_ALL": "Очистить Все",
        "FILTER_TYPE": "Тип",
        "FILTER_CURRENCY": "Валюта",
        "FILTER_STATUS": "Статус",
        "FILTER_TIMEFRAME": "Период",
        "ALL_TYPES": "Все Типы",
        "ALL_CURRENCIES": "Все Валюты",
        "ALL_STATUS": "Все Статусы",
        "COMPLETED": "Завершено",
        "PENDING": "В ожидании",
        "CANCELLED": "Отменено",
        "ALL_TIME": "Все Время",
        "LAST_30_DAYS": "Последние 30 Дней",
        "LAST_90_DAYS": "Последние 90 Дней",
        "LAST_YEAR": "Последний Год",
        "EXCHANGES_COUNT": "Обмены",
        "LOADING_EXCHANGE_HISTORY": "Загрузка истории обмена...",
        "NO_EXCHANGES_FOUND": "Обмены не найдены",
        "NO_EXCHANGES_YET": "Вы еще не завершили ни одного обмена.",
        "NO_MATCHING_EXCHANGES": "Нет обменов, соответствующих вашим текущим фильтрам.",
        "EXCHANGE_WITH": "с",
        "TRY_AGAIN": "Попробовать Снова",
        "BUY_LABEL": "Куплено",
        "SELL_LABEL": "Продано",
    },
    "ar": {
        "EXCHANGE_HISTORY": "سجل الصرف",
        "TOTAL_EXCHANGES": "إجمالي الصرفات",
        "COMPLETED_EXCHANGES": "مكتمل",
        "BOUGHT_EXCHANGES": "مشتري",
        "SOLD_EXCHANGES": "مباع",
        "FILTER_HISTORY": "تصفية السجل",
        "CLEAR_ALL": "حذف الكل",
        "FILTER_TYPE": "النوع",
        "FILTER_CURRENCY": "العملة",
        "FILTER_STATUS": "الحالة",
        "FILTER_TIMEFRAME": "الفترة الزمنية",
        "ALL_TYPES": "جميع الأنواع",
        "ALL_CURRENCIES": "جميع العملات",
        "ALL_STATUS": "جميع الحالات",
        "COMPLETED": "مكتمل",
        "PENDING": "قيد الانتظار",
        "CANCELLED": "ملغي",
        "ALL_TIME": "كل الوقت",
        "LAST_30_DAYS": "آخر 30 يومًا",
        "LAST_90_DAYS": "آخر 90 يومًا",
        "LAST_YEAR": "السنة الماضية",
        "EXCHANGES_COUNT": "الصرفات",
        "LOADING_EXCHANGE_HISTORY": "جاري تحميل سجل الصرف...",
        "NO_EXCHANGES_FOUND": "لم يتم العثور على صرفات",
        "NO_EXCHANGES_YET": "لم تكمل أي صرفات بعد.",
        "NO_MATCHING_EXCHANGES": "لا توجد صرفات تطابق عوامل التصفية الحالية.",
        "EXCHANGE_WITH": "مع",
        "TRY_AGAIN": "حاول مرة أخرى",
        "BUY_LABEL": "مشتري",
        "SELL_LABEL": "مباع",
    },
    "hi": {
        "EXCHANGE_HISTORY": "विनिमय इतिहास",
        "TOTAL_EXCHANGES": "कुल विनिमय",
        "COMPLETED_EXCHANGES": "पूर्ण",
        "BOUGHT_EXCHANGES": "खरीदा",
        "SOLD_EXCHANGES": "बेचा",
        "FILTER_HISTORY": "इतिहास फ़िल्टर करें",
        "CLEAR_ALL": "सब कुछ साफ़ करें",
        "FILTER_TYPE": "प्रकार",
        "FILTER_CURRENCY": "मुद्रा",
        "FILTER_STATUS": "स्थिति",
        "FILTER_TIMEFRAME": "समय अवधि",
        "ALL_TYPES": "सभी प्रकार",
        "ALL_CURRENCIES": "सभी मुद्राएं",
        "ALL_STATUS": "सभी स्थितियां",
        "COMPLETED": "पूर्ण",
        "PENDING": "लंबित",
        "CANCELLED": "रद्द",
        "ALL_TIME": "सभी समय",
        "LAST_30_DAYS": "पिछले 30 दिन",
        "LAST_90_DAYS": "पिछले 90 दिन",
        "LAST_YEAR": "पिछला वर्ष",
        "EXCHANGES_COUNT": "विनिमय",
        "LOADING_EXCHANGE_HISTORY": "विनिमय इतिहास लोड हो रहा है...",
        "NO_EXCHANGES_FOUND": "कोई विनिमय नहीं मिला",
        "NO_EXCHANGES_YET": "आपने अभी तक कोई विनिमय पूर्ण नहीं किया है।",
        "NO_MATCHING_EXCHANGES": "कोई विनिमय आपकी वर्तमान फ़िल्टर से मेल नहीं खाते।",
        "EXCHANGE_WITH": "के साथ",
        "TRY_AGAIN": "दोबारा कोशिश करें",
        "BUY_LABEL": "खरीदा",
        "SELL_LABEL": "बेचा",
    },
    "sk": {
        "EXCHANGE_HISTORY": "História Výmen",
        "TOTAL_EXCHANGES": "Celkové Výmeny",
        "COMPLETED_EXCHANGES": "Dokončené",
        "BOUGHT_EXCHANGES": "Kúpené",
        "SOLD_EXCHANGES": "Predané",
        "FILTER_HISTORY": "Filtrovať Históriu",
        "CLEAR_ALL": "Vymazať Všetko",
        "FILTER_TYPE": "Typ",
        "FILTER_CURRENCY": "Mena",
        "FILTER_STATUS": "Stav",
        "FILTER_TIMEFRAME": "Časové Obdobie",
        "ALL_TYPES": "Všetky Typy",
        "ALL_CURRENCIES": "Všetky Meny",
        "ALL_STATUS": "Všetky Stavy",
        "COMPLETED": "Dokončené",
        "PENDING": "Čakajúce",
        "CANCELLED": "Zrušené",
        "ALL_TIME": "Celý Čas",
        "LAST_30_DAYS": "Posledných 30 Dní",
        "LAST_90_DAYS": "Posledných 90 Dní",
        "LAST_YEAR": "Posledný Rok",
        "EXCHANGES_COUNT": "Výmeny",
        "LOADING_EXCHANGE_HISTORY": "Načítavanie histórie výmen...",
        "NO_EXCHANGES_FOUND": "Žiadne výmeny neboli nájdené",
        "NO_EXCHANGES_YET": "Ešte ste nedokončili žiadne výmeny.",
        "NO_MATCHING_EXCHANGES": "Žiadne výmeny nezodpovedajú vašim aktuálnym filtrom.",
        "EXCHANGE_WITH": "s",
        "TRY_AGAIN": "Skúsiť Znova",
        "BUY_LABEL": "Kúpené",
        "SELL_LABEL": "Predané",
    },
    "en": {
        # English defaults to the TRANSLATION_KEYS dict values above
    }
}

def main():
    """Execute migration"""
    print("🔄 Starting Exchange History View translation migration...\n")
    
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Get English translations first
        english_count = 0
        for key, english_value in TRANSLATION_KEYS.items():
            cursor.execute("""
                INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (key, 'en', english_value, datetime.now(), datetime.now()))
            
            if cursor.rowcount > 0:
                print(f"✅ Inserted {key}: {english_value}")
                english_count += 1
        
        connection.commit()
        print(f"\n✅ English: {english_count} keys inserted\n")
        
        # Insert translations for all other languages
        language_results = {}
        for language_code, translations in LANGUAGE_TRANSLATIONS.items():
            if language_code == 'en':
                continue
            
            inserted_count = 0
            for key, value in translations.items():
                cursor.execute("""
                    INSERT IGNORE INTO translations (translation_key, language_code, translation_value, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (key, language_code, value, datetime.now(), datetime.now()))
                
                if cursor.rowcount > 0:
                    inserted_count += 1
                    print(f"✅ Inserted {key} ({language_code}): {value}")
            
            connection.commit()
            language_results[language_code] = inserted_count
            print(f"✅ {language_code}: {inserted_count} keys inserted\n")
        
        # Print summary
        print("\n" + "="*60)
        print("✅ Migration completed successfully!")
        print("="*60)
        print(f"\nSummary:")
        for lang, count in sorted(language_results.items()):
            print(f"  {lang}: {count} keys")
        
    except Exception as e:
        print(f"❌ Error during migration: {e}")
        connection.rollback()
        return 1
    finally:
        cursor.close()
        connection.close()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
