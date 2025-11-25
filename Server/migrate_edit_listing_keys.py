#!/usr/bin/env python3
"""
Migrate Edit Listing Keys to Database
Inserts translation keys for the Edit Listing view
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib import Database

# Translation keys and their English values
EDIT_LISTING_KEYS = {
    "EDIT_LISTING": "Edit Listing",
    "PASO_1_DE_3": "Step 1 of 3",
    "WHAT_CURRENCY_DO_YOU_HAVE": "What currency do you have?",
    "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Select the currency you want to exchange",
    "CURRENCY_YOU_HAVE": "Currency You Have",
    "CHANGE": "Change",
    "AMOUNT_YOU_HAVE": "Amount You Have",
    "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "How much of this currency do you have available?",
    "WHAT_CURRENCY_WILL_YOU_ACCEPT": "What currency will you accept?",
    "NEXT": "Next",
    "DANGER_ZONE": "Danger Zone",
    "ONCE_YOU_DELETE_NO_GOING_BACK": "Once you delete this listing, there is no going back. Please be certain.",
    "DELETE_THIS_LISTING": "Delete This Listing",
}

# Translations for other supported languages
TRANSLATIONS = {
    "es": {  # Spanish
        "EDIT_LISTING": "Editar Listado",
        "PASO_1_DE_3": "Paso 1 de 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "¿Qué moneda tienes?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Selecciona la moneda que quieres intercambiar",
        "CURRENCY_YOU_HAVE": "Moneda Que Tienes",
        "CHANGE": "Cambiar",
        "AMOUNT_YOU_HAVE": "Cantidad Que Tienes",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "¿Cuánta de esta moneda tienes disponible?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "¿Qué moneda aceptarás?",
        "NEXT": "Siguiente",
        "DANGER_ZONE": "Zona de Peligro",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "Una vez que elimines este listado, no hay vuelta atrás. Por favor, asegúrate.",
        "DELETE_THIS_LISTING": "Eliminar Este Listado",
    },
    "fr": {  # French
        "EDIT_LISTING": "Modifier l'annonce",
        "PASO_1_DE_3": "Étape 1 sur 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Quelle devise avez-vous?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Sélectionnez la devise que vous souhaitez échanger",
        "CURRENCY_YOU_HAVE": "Devise que vous avez",
        "CHANGE": "Modifier",
        "AMOUNT_YOU_HAVE": "Montant que vous avez",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "Combien de cette devise avez-vous disponible?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "Quelle devise accepterez-vous?",
        "NEXT": "Suivant",
        "DANGER_ZONE": "Zone Dangereuse",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "Une fois que vous supprimez cette annonce, il n'y a pas de retour. Veuillez être certain.",
        "DELETE_THIS_LISTING": "Supprimer Cette Annonce",
    },
    "de": {  # German
        "EDIT_LISTING": "Angebot bearbeiten",
        "PASO_1_DE_3": "Schritt 1 von 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Welche Währung haben Sie?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Wählen Sie die Währung aus, die Sie tauschen möchten",
        "CURRENCY_YOU_HAVE": "Währung, die Sie haben",
        "CHANGE": "Ändern",
        "AMOUNT_YOU_HAVE": "Menge, die Sie haben",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "Wie viel dieser Währung haben Sie verfügbar?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "Welche Währung werden Sie akzeptieren?",
        "NEXT": "Weiter",
        "DANGER_ZONE": "Gefahrenzone",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "Sobald Sie dieses Angebot löschen, gibt es kein Zurück. Bitte seien Sie sicher.",
        "DELETE_THIS_LISTING": "Dieses Angebot Löschen",
    },
    "pt": {  # Portuguese
        "EDIT_LISTING": "Editar Anúncio",
        "PASO_1_DE_3": "Passo 1 de 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Que moeda você tem?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Selecione a moeda que deseja trocar",
        "CURRENCY_YOU_HAVE": "Moeda Que Você Tem",
        "CHANGE": "Alterar",
        "AMOUNT_YOU_HAVE": "Quantia Que Você Tem",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "Quanto dessa moeda você tem disponível?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "Que moeda você aceitará?",
        "NEXT": "Próximo",
        "DANGER_ZONE": "Zona de Perigo",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "Uma vez que você exclui este anúncio, não há volta. Por favor, tenha certeza.",
        "DELETE_THIS_LISTING": "Excluir Este Anúncio",
    },
    "ja": {  # Japanese
        "EDIT_LISTING": "リスティングを編集",
        "PASO_1_DE_3": "ステップ1の3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "どの通貨を持っていますか？",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "交換したい通貨を選択してください",
        "CURRENCY_YOU_HAVE": "お持ちの通貨",
        "CHANGE": "変更",
        "AMOUNT_YOU_HAVE": "お持ちの金額",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "この通貨はいくらご利用可能ですか？",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "どの通貨を受け入れますか？",
        "NEXT": "次へ",
        "DANGER_ZONE": "危険区域",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "このリスティングを削除すると、戻ることができません。確認してください。",
        "DELETE_THIS_LISTING": "このリスティングを削除",
    },
    "zh": {  # Chinese
        "EDIT_LISTING": "编辑列表",
        "PASO_1_DE_3": "第1步，共3步",
        "WHAT_CURRENCY_DO_YOU_HAVE": "你有什么货币？",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "选择您要交换的货币",
        "CURRENCY_YOU_HAVE": "你拥有的货币",
        "CHANGE": "改变",
        "AMOUNT_YOU_HAVE": "你拥有的金额",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "您有多少这种货币可用？",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "您接受哪种货币？",
        "NEXT": "下一步",
        "DANGER_ZONE": "危险区域",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "删除此列表后，无法返回。请确定。",
        "DELETE_THIS_LISTING": "删除此列表",
    },
    "ru": {  # Russian
        "EDIT_LISTING": "Редактировать объявление",
        "PASO_1_DE_3": "Шаг 1 из 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Какая у вас валюта?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Выберите валюту, которую вы хотите обменять",
        "CURRENCY_YOU_HAVE": "Валюта, которая у вас есть",
        "CHANGE": "Изменить",
        "AMOUNT_YOU_HAVE": "Сумма, которая у вас есть",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "Сколько этой валюты у вас есть?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "Какую валюту вы примете?",
        "NEXT": "Далее",
        "DANGER_ZONE": "Опасная зона",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "Как только вы удалите это объявление, пути назад нет. Пожалуйста, будьте уверены.",
        "DELETE_THIS_LISTING": "Удалить это объявление",
    },
    "ar": {  # Arabic
        "EDIT_LISTING": "تعديل الإدراج",
        "PASO_1_DE_3": "الخطوة 1 من 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "ما العملة التي لديك؟",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "حدد العملة التي تريد تبديلها",
        "CURRENCY_YOU_HAVE": "العملة التي لديك",
        "CHANGE": "تغيير",
        "AMOUNT_YOU_HAVE": "المبلغ الذي لديك",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "كم من هذه العملة لديك متاح؟",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "ما العملة التي ستقبلها؟",
        "NEXT": "التالي",
        "DANGER_ZONE": "منطقة الخطر",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "بمجرد حذف هذا الإدراج، لا يمكن العودة. يرجى التأكد.",
        "DELETE_THIS_LISTING": "حذف هذا الإدراج",
    },
    "hi": {  # Hindi
        "EDIT_LISTING": "सूची संपादित करें",
        "PASO_1_DE_3": "चरण 1 का 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "आपके पास कौन सी मुद्रा है?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "वह मुद्रा चुनें जिसे आप विनिमय करना चाहते हैं",
        "CURRENCY_YOU_HAVE": "आपके पास मुद्रा",
        "CHANGE": "बदलना",
        "AMOUNT_YOU_HAVE": "आपके पास राशि",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "इस मुद्रा में आपके पास कितना उपलब्ध है?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "आप कौन सी मुद्रा स्वीकार करेंगे?",
        "NEXT": "अगला",
        "DANGER_ZONE": "खतरे का क्षेत्र",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "एक बार जब आप इस सूची को हटा देते हैं, तो वापस नहीं जा सकते। कृपया सुनिश्चित रहें।",
        "DELETE_THIS_LISTING": "इस सूची को हटाएं",
    },
    "sk": {  # Slovak
        "EDIT_LISTING": "Upraviť inzerát",
        "PASO_1_DE_3": "Krok 1 z 3",
        "WHAT_CURRENCY_DO_YOU_HAVE": "Akú menu máte?",
        "SELECT_THE_CURRENCY_YOU_WANT_TO_EXCHANGE": "Vyberte menu, ktorú chcete vymeniť",
        "CURRENCY_YOU_HAVE": "Menu, ktorú máte",
        "CHANGE": "Zmeniť",
        "AMOUNT_YOU_HAVE": "Suma, ktorú máte",
        "HOW_MUCH_OF_THIS_CURRENCY_AVAILABLE": "Koľko tejto meny máte k dispozícii?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "Akú menu budete akceptovať?",
        "NEXT": "Ďalej",
        "DANGER_ZONE": "Nebezpečná zóna",
        "ONCE_YOU_DELETE_NO_GOING_BACK": "Keď zmažete tento inzerát, nie je cesty späť. Prosím, buďte si istí.",
        "DELETE_THIS_LISTING": "Odstrániť Tento Inzerát",
    },
}


def migrate():
    """Insert or update edit listing keys in the database"""
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Insert English translations first
        print("📝 Inserting English translations...")
        for key, value in EDIT_LISTING_KEYS.items():
            # Check if key already exists
            check_query = """
                SELECT id FROM translations 
                WHERE translation_key = %s AND language_code = 'en'
            """
            cursor.execute(check_query, (key,))
            result = cursor.fetchone()
            
            if result:
                # Update existing
                update_query = """
                    UPDATE translations 
                    SET translation_value = %s, updated_at = NOW()
                    WHERE translation_key = %s AND language_code = 'en'
                """
                cursor.execute(update_query, (value, key))
                print(f"  ✏️  Updated: {key}")
            else:
                # Insert new
                insert_query = """
                    INSERT INTO translations 
                    (translation_key, translation_value, language_code, created_at, updated_at)
                    VALUES (%s, %s, 'en', NOW(), NOW())
                """
                cursor.execute(insert_query, (key, value))
                print(f"  ✅ Inserted: {key}")
        
        connection.commit()
        
        # Insert translations for other languages
        for language_code, translations in TRANSLATIONS.items():
            print(f"\n📝 Inserting {language_code.upper()} translations...")
            for key, value in translations.items():
                # Check if key already exists for this language
                check_query = """
                    SELECT id FROM translations 
                    WHERE translation_key = %s AND language_code = %s
                """
                cursor.execute(check_query, (key, language_code))
                result = cursor.fetchone()
                
                if result:
                    # Update existing
                    update_query = """
                        UPDATE translations 
                        SET translation_value = %s, updated_at = NOW()
                        WHERE translation_key = %s AND language_code = %s
                    """
                    cursor.execute(update_query, (value, key, language_code))
                    print(f"  ✏️  Updated: {key}")
                else:
                    # Insert new
                    insert_query = """
                        INSERT INTO translations 
                        (translation_key, translation_value, language_code, created_at, updated_at)
                        VALUES (%s, %s, %s, NOW(), NOW())
                    """
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
