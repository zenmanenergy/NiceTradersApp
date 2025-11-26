#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Fix Missing Translations
Finds translations that match English text and replaces them with proper translations.
"""

import pymysql

# Translation dictionary for each language
TRANSLATIONS = {
    'ja': {  # Japanese
        'Welcome Back': 'おかえりなさい',
        'Sign in to continue': 'ログインして続ける',
        'Email': 'メール',
        'Enter email': 'メールアドレスを入力',
        'Password': 'パスワード',
        'Enter password': 'パスワードを入力',
        'Forgot Password?': 'パスワードをお忘れですか？',
        'Password recovery is coming soon!': 'パスワード回復機能は近日公開予定です！',
        'Signing in...': 'ログイン中...',
        "Don't have an account?": 'アカウントをお持ちではありませんか？',
        'Sign Up': '新規登録',
        'Sign In': 'ログイン',
        'Login': 'ログイン',
        'OK': 'OK',
        'Email is required': 'メールアドレスは必須です',
        'Invalid email address': 'メールアドレスが無効です',
        'Password is required': 'パスワードは必須です',
        'Invalid URL': '無効なURL',
        'Network error': 'ネットワークエラー',
        'No data received': 'データを受信できませんでした',
        'Invalid email or password': 'メールアドレスまたはパスワードが正しくありません',
        'Failed to parse response': 'レスポンスの解析に失敗しました',
        'Already have an account?': 'すでにアカウントをお持ちですか？',
        'Checking session...': 'セッションを確認中...',
    },
    'es': {  # Spanish
        'Welcome Back': 'Bienvenido de Nuevo',
        'Sign in to continue': 'Inicia sesión para continuar',
        'Email': 'Correo Electrónico',
        'Enter email': 'Ingresa tu correo',
        'Password': 'Contraseña',
        'Enter password': 'Ingresa tu contraseña',
        'Forgot Password?': '¿Olvidaste tu Contraseña?',
        'Password recovery is coming soon!': '¡La recuperación de contraseña estará disponible pronto!',
        'Signing in...': 'Iniciando sesión...',
        "Don't have an account?": '¿No tienes una cuenta?',
        'Sign Up': 'Registrarse',
        'Sign In': 'Iniciar Sesión',
        'Login': 'Iniciar Sesión',
        'OK': 'OK',
        'Email is required': 'El correo electrónico es obligatorio',
        'Invalid email address': 'Correo electrónico inválido',
        'Password is required': 'La contraseña es obligatoria',
        'Invalid URL': 'URL inválida',
        'Network error': 'Error de red',
        'No data received': 'No se recibieron datos',
        'Invalid email or password': 'Correo o contraseña incorrectos',
        'Failed to parse response': 'Error al analizar la respuesta',
        'Already have an account?': '¿Ya tienes una cuenta?',
        'Checking session...': 'Verificando sesión...',
    },
    'fr': {  # French
        'Welcome Back': 'Bienvenue',
        'Sign in to continue': 'Connectez-vous pour continuer',
        'Email': 'E-mail',
        'Enter email': 'Entrez votre e-mail',
        'Password': 'Mot de Passe',
        'Enter password': 'Entrez votre mot de passe',
        'Forgot Password?': 'Mot de Passe Oublié?',
        'Password recovery is coming soon!': 'La récupération du mot de passe arrive bientôt!',
        'Signing in...': 'Connexion en cours...',
        "Don't have an account?": "Vous n'avez pas de compte?",
        'Sign Up': "S'inscrire",
        'Sign In': 'Se Connecter',
        'Login': 'Connexion',
        'OK': 'OK',
        'Email is required': "L'e-mail est requis",
        'Invalid email address': 'E-mail invalide',
        'Password is required': 'Le mot de passe est requis',
        'Invalid URL': 'URL invalide',
        'Network error': 'Erreur réseau',
        'No data received': 'Aucune donnée reçue',
        'Invalid email or password': 'E-mail ou mot de passe incorrect',
        'Failed to parse response': "Échec de l'analyse de la réponse",
        'Already have an account?': 'Vous avez déjà un compte?',
        'Checking session...': 'Vérification de la session...',
    },
    'de': {  # German
        'Welcome Back': 'Willkommen zurück',
        'Sign in to continue': 'Anmelden um fortzufahren',
        'Email': 'E-Mail',
        'Enter email': 'E-Mail eingeben',
        'Password': 'Passwort',
        'Enter password': 'Passwort eingeben',
        'Forgot Password?': 'Passwort vergessen?',
        'Password recovery is coming soon!': 'Passwortwiederherstellung kommt bald!',
        'Signing in...': 'Anmeldung läuft...',
        "Don't have an account?": 'Noch kein Konto?',
        'Sign Up': 'Registrieren',
        'Sign In': 'Anmelden',
        'Login': 'Anmelden',
        'OK': 'OK',
        'Email is required': 'E-Mail ist erforderlich',
        'Invalid email address': 'Ungültige E-Mail-Adresse',
        'Password is required': 'Passwort ist erforderlich',
        'Invalid URL': 'Ungültige URL',
        'Network error': 'Netzwerkfehler',
        'No data received': 'Keine Daten empfangen',
        'Invalid email or password': 'E-Mail oder Passwort ungültig',
        'Failed to parse response': 'Fehler beim Parsen der Antwort',
        'Already have an account?': 'Bereits ein Konto?',
        'Checking session...': 'Sitzung wird überprüft...',
    },
}

def main():
    # Connect to database
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    print("🔍 Searching for translations that match English...")
    print()
    
    # Get all English translations
    cursor.execute("""
        SELECT translation_key, translation_value 
        FROM translations 
        WHERE language_code = 'en'
        ORDER BY translation_key
    """)
    english_translations = {row[0]: row[1] for row in cursor.fetchall()}
    
    total_fixed = 0
    
    # Check each language
    for lang_code, translations_map in TRANSLATIONS.items():
        print(f"📝 Checking {lang_code.upper()} translations...")
        fixed_count = 0
        
        for translation_key, english_value in english_translations.items():
            # Get the current translation for this language
            cursor.execute("""
                SELECT translation_value 
                FROM translations 
                WHERE translation_key = %s AND language_code = %s
            """, (translation_key, lang_code))
            
            result = cursor.fetchone()
            if result:
                current_value = result[0]
                
                # Check if the translation matches the English text (indicating it's not translated)
                if current_value == english_value and english_value in translations_map:
                    correct_translation = translations_map[english_value]
                    
                    # Update with correct translation
                    cursor.execute("""
                        UPDATE translations 
                        SET translation_value = %s, updated_at = NOW()
                        WHERE translation_key = %s AND language_code = %s
                    """, (correct_translation, translation_key, lang_code))
                    
                    print(f"  ✅ Fixed {translation_key}: '{current_value}' → '{correct_translation}'")
                    fixed_count += 1
            else:
                # Translation doesn't exist, insert it if we have a mapping
                if english_value in translations_map:
                    correct_translation = translations_map[english_value]
                    cursor.execute("""
                        INSERT INTO translations (translation_key, language_code, translation_value)
                        VALUES (%s, %s, %s)
                    """, (translation_key, lang_code, correct_translation))
                    print(f"  ➕ Added {translation_key}: '{correct_translation}'")
                    fixed_count += 1
        
        if fixed_count == 0:
            print(f"  ✓ No issues found")
        else:
            print(f"  🎉 Fixed {fixed_count} translations")
        
        total_fixed += fixed_count
        print()
    
    # Commit changes
    db.commit()
    
    print(f"{'='*60}")
    print(f"✅ Total translations fixed/added: {total_fixed}")
    print(f"{'='*60}")
    
    # Show summary
    cursor.execute("""
        SELECT language_code, COUNT(*) as count 
        FROM translations 
        GROUP BY language_code 
        ORDER BY language_code
    """)
    
    print("\n📊 Translation counts by language:")
    for lang, count in cursor.fetchall():
        print(f"  {lang}: {count} translations")
    
    cursor.close()
    db.close()

if __name__ == '__main__':
    main()
