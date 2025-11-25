#!/usr/bin/env python3
"""
Migration script to add EditListingView translation keys
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database
from datetime import datetime

TRANSLATION_KEYS = {
    "DELETE_LISTING_DIALOG_TITLE": "Delete Listing",
    "DELETE_LISTING_CONFIRM_MESSAGE": "Are you sure you want to delete this listing? This action cannot be undone.",
    "CHANGE": "Change",
    "AMOUNT_YOU_WILL_RECEIVE": "Amount you'll receive (at market rate)",
    "WITHIN_MILES": "Within",  # Will be used as: "Within {radius} miles"
    "MILES": "miles",
}

LANGUAGE_TRANSLATIONS = {
    "es": {
        "DELETE_LISTING_DIALOG_TITLE": "Eliminar Anuncio",
        "DELETE_LISTING_CONFIRM_MESSAGE": "¿Estás seguro de que deseas eliminar este anuncio? Esta acción no se puede deshacer.",
        "CHANGE": "Cambiar",
        "AMOUNT_YOU_WILL_RECEIVE": "Cantidad que recibirás (al tipo de cambio actual)",
        "WITHIN_MILES": "Dentro de",
        "MILES": "millas",
    },
    "fr": {
        "DELETE_LISTING_DIALOG_TITLE": "Supprimer l'Annonce",
        "DELETE_LISTING_CONFIRM_MESSAGE": "Êtes-vous sûr de vouloir supprimer cette annonce? Cette action ne peut pas être annulée.",
        "CHANGE": "Changer",
        "AMOUNT_YOU_WILL_RECEIVE": "Montant que vous recevrez (au taux actuel)",
        "WITHIN_MILES": "Dans",
        "MILES": "kilomètres",
    },
    "de": {
        "DELETE_LISTING_DIALOG_TITLE": "Anzeige Löschen",
        "DELETE_LISTING_CONFIRM_MESSAGE": "Bist du sicher, dass du diese Anzeige löschen möchtest? Diese Aktion kann nicht rückgängig gemacht werden.",
        "CHANGE": "Ändern",
        "AMOUNT_YOU_WILL_RECEIVE": "Betrag, den Sie erhalten (zum aktuellen Kurs)",
        "WITHIN_MILES": "Innerhalb",
        "MILES": "Kilometer",
    },
    "pt": {
        "DELETE_LISTING_DIALOG_TITLE": "Eliminar Anúncio",
        "DELETE_LISTING_CONFIRM_MESSAGE": "Tem certeza de que deseja eliminar este anúncio? Esta ação não pode ser desfeita.",
        "CHANGE": "Alterar",
        "AMOUNT_YOU_WILL_RECEIVE": "Valor que você receberá (à taxa de câmbio atual)",
        "WITHIN_MILES": "Dentro de",
        "MILES": "quilômetros",
    },
    "ja": {
        "DELETE_LISTING_DIALOG_TITLE": "リスティングを削除",
        "DELETE_LISTING_CONFIRM_MESSAGE": "このリスティングを削除してもよろしいですか？この操作は取り消すことができません。",
        "CHANGE": "変更",
        "AMOUNT_YOU_WILL_RECEIVE": "受け取る金額（現在の相場）",
        "WITHIN_MILES": "以内",
        "MILES": "マイル",
    },
    "zh": {
        "DELETE_LISTING_DIALOG_TITLE": "删除列表",
        "DELETE_LISTING_CONFIRM_MESSAGE": "您确定要删除此列表吗？此操作无法撤消。",
        "CHANGE": "更改",
        "AMOUNT_YOU_WILL_RECEIVE": "您将收到的金额（按市场汇率）",
        "WITHIN_MILES": "在",
        "MILES": "英里",
    },
    "ru": {
        "DELETE_LISTING_DIALOG_TITLE": "Удалить Объявление",
        "DELETE_LISTING_CONFIRM_MESSAGE": "Вы уверены, что хотите удалить это объявление? Это действие не может быть отменено.",
        "CHANGE": "Изменить",
        "AMOUNT_YOU_WILL_RECEIVE": "Сумма, которую вы получите (по текущему курсу)",
        "WITHIN_MILES": "В пределах",
        "MILES": "километров",
    },
    "ar": {
        "DELETE_LISTING_DIALOG_TITLE": "حذف القائمة",
        "DELETE_LISTING_CONFIRM_MESSAGE": "هل أنت متأكد من أنك تريد حذف هذه القائمة؟ لا يمكن التراجع عن هذا الإجراء.",
        "CHANGE": "تغيير",
        "AMOUNT_YOU_WILL_RECEIVE": "المبلغ الذي ستستقبله (بسعر الصرف الحالي)",
        "WITHIN_MILES": "في",
        "MILES": "كيلومتر",
    },
    "hi": {
        "DELETE_LISTING_DIALOG_TITLE": "सूची हटाएं",
        "DELETE_LISTING_CONFIRM_MESSAGE": "क्या आप सुनिश्चित हैं कि आप इस सूची को हटाना चाहते हैं? यह कार्रवाई पूर्ववत नहीं की जा सकती।",
        "CHANGE": "बदलें",
        "AMOUNT_YOU_WILL_RECEIVE": "आप जो राशि प्राप्त करेंगे (बाजार दर पर)",
        "WITHIN_MILES": "के भीतर",
        "MILES": "किलोमीटर",
    },
    "sk": {
        "DELETE_LISTING_DIALOG_TITLE": "Vymazať Inzerát",
        "DELETE_LISTING_CONFIRM_MESSAGE": "Ste si istí, že chcete odstrániť tento inzerát? Túto akciu nemožno vrátiť späť.",
        "CHANGE": "Zmeniť",
        "AMOUNT_YOU_WILL_RECEIVE": "Suma, ktorú dostanete (po aktuálnom výmennom kurze)",
        "WITHIN_MILES": "V rámci",
        "MILES": "kilometrov",
    },
}

def main():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print("=== EDIT LISTING VIEW KEYS MIGRATION ===\n")
        
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
