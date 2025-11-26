-- Add LoginView translations for multiple languages
-- This migration adds all the translation keys needed for the LoginView screen

-- English translations
INSERT INTO translations (translation_key, language_code, translation_value) VALUES
('WELCOME_BACK', 'en', 'Welcome Back'),
('SIGN_IN_TO_CONTINUE', 'en', 'Sign in to continue'),
('EMAIL', 'en', 'Email'),
('ENTER_EMAIL', 'en', 'Enter email'),
('PASSWORD', 'en', 'Password'),
('ENTER_PASSWORD', 'en', 'Enter password'),
('FORGOT_PASSWORD', 'en', 'Forgot Password?'),
('FORGOT_PASSWORD_COMING_SOON', 'en', 'Password recovery is coming soon!'),
('SIGNING_IN', 'en', 'Signing in...'),
('DONT_HAVE_ACCOUNT', 'en', "Don't have an account?"),
('SIGN_UP', 'en', 'Sign Up'),
('SIGN_IN', 'en', 'Sign In'),
('LOGIN', 'en', 'Login'),
('OK', 'en', 'OK'),
('EMAIL_REQUIRED', 'en', 'Email is required'),
('INVALID_EMAIL', 'en', 'Invalid email address'),
('PASSWORD_REQUIRED', 'en', 'Password is required'),
('INVALID_URL', 'en', 'Invalid URL'),
('NETWORK_ERROR', 'en', 'Network error'),
('NO_DATA_RECEIVED', 'en', 'No data received'),
('INVALID_LOGIN_CREDENTIALS', 'en', 'Invalid email or password'),
('FAILED_PARSE_RESPONSE', 'en', 'Failed to parse response')
ON DUPLICATE KEY UPDATE translation_value = VALUES(translation_value);

-- Japanese translations
INSERT INTO translations (translation_key, language_code, translation_value) VALUES
('WELCOME_BACK', 'ja', 'おかえりなさい'),
('SIGN_IN_TO_CONTINUE', 'ja', 'ログインして続ける'),
('EMAIL', 'ja', 'メール'),
('ENTER_EMAIL', 'ja', 'メールアドレスを入力'),
('PASSWORD', 'ja', 'パスワード'),
('ENTER_PASSWORD', 'ja', 'パスワードを入力'),
('FORGOT_PASSWORD', 'ja', 'パスワードをお忘れですか？'),
('FORGOT_PASSWORD_COMING_SOON', 'ja', 'パスワード回復機能は近日公開予定です！'),
('SIGNING_IN', 'ja', 'ログイン中...'),
('DONT_HAVE_ACCOUNT', 'ja', 'アカウントをお持ちではありませんか？'),
('SIGN_UP', 'ja', '新規登録'),
('SIGN_IN', 'ja', 'ログイン'),
('LOGIN', 'ja', 'ログイン'),
('OK', 'ja', 'OK'),
('EMAIL_REQUIRED', 'ja', 'メールアドレスは必須です'),
('INVALID_EMAIL', 'ja', 'メールアドレスが無効です'),
('PASSWORD_REQUIRED', 'ja', 'パスワードは必須です'),
('INVALID_URL', 'ja', '無効なURL'),
('NETWORK_ERROR', 'ja', 'ネットワークエラー'),
('NO_DATA_RECEIVED', 'ja', 'データを受信できませんでした'),
('INVALID_LOGIN_CREDENTIALS', 'ja', 'メールアドレスまたはパスワードが正しくありません'),
('FAILED_PARSE_RESPONSE', 'ja', 'レスポンスの解析に失敗しました')
ON DUPLICATE KEY UPDATE translation_value = VALUES(translation_value);

-- Spanish translations
INSERT INTO translations (translation_key, language_code, translation_value) VALUES
('WELCOME_BACK', 'es', 'Bienvenido de Nuevo'),
('SIGN_IN_TO_CONTINUE', 'es', 'Inicia sesión para continuar'),
('EMAIL', 'es', 'Correo Electrónico'),
('ENTER_EMAIL', 'es', 'Ingresa tu correo'),
('PASSWORD', 'es', 'Contraseña'),
('ENTER_PASSWORD', 'es', 'Ingresa tu contraseña'),
('FORGOT_PASSWORD', 'es', '¿Olvidaste tu Contraseña?'),
('FORGOT_PASSWORD_COMING_SOON', 'es', '¡La recuperación de contraseña estará disponible pronto!'),
('SIGNING_IN', 'es', 'Iniciando sesión...'),
('DONT_HAVE_ACCOUNT', 'es', '¿No tienes una cuenta?'),
('SIGN_UP', 'es', 'Registrarse'),
('SIGN_IN', 'es', 'Iniciar Sesión'),
('LOGIN', 'es', 'Iniciar Sesión'),
('OK', 'es', 'OK'),
('EMAIL_REQUIRED', 'es', 'El correo electrónico es obligatorio'),
('INVALID_EMAIL', 'es', 'Correo electrónico inválido'),
('PASSWORD_REQUIRED', 'es', 'La contraseña es obligatoria'),
('INVALID_URL', 'es', 'URL inválida'),
('NETWORK_ERROR', 'es', 'Error de red'),
('NO_DATA_RECEIVED', 'es', 'No se recibieron datos'),
('INVALID_LOGIN_CREDENTIALS', 'es', 'Correo o contraseña incorrectos'),
('FAILED_PARSE_RESPONSE', 'es', 'Error al analizar la respuesta')
ON DUPLICATE KEY UPDATE translation_value = VALUES(translation_value);

-- French translations
INSERT INTO translations (translation_key, language_code, translation_value) VALUES
('WELCOME_BACK', 'fr', 'Bienvenue'),
('SIGN_IN_TO_CONTINUE', 'fr', 'Connectez-vous pour continuer'),
('EMAIL', 'fr', 'E-mail'),
('ENTER_EMAIL', 'fr', 'Entrez votre e-mail'),
('PASSWORD', 'fr', 'Mot de Passe'),
('ENTER_PASSWORD', 'fr', 'Entrez votre mot de passe'),
('FORGOT_PASSWORD', 'fr', 'Mot de Passe Oublié?'),
('FORGOT_PASSWORD_COMING_SOON', 'fr', 'La récupération du mot de passe arrive bientôt!'),
('SIGNING_IN', 'fr', 'Connexion en cours...'),
('DONT_HAVE_ACCOUNT', 'fr', "Vous n'avez pas de compte?"),
('SIGN_UP', 'fr', "S'inscrire"),
('SIGN_IN', 'fr', 'Se Connecter'),
('LOGIN', 'fr', 'Connexion'),
('OK', 'fr', 'OK'),
('EMAIL_REQUIRED', 'fr', "L'e-mail est requis"),
('INVALID_EMAIL', 'fr', 'E-mail invalide'),
('PASSWORD_REQUIRED', 'fr', 'Le mot de passe est requis'),
('INVALID_URL', 'fr', 'URL invalide'),
('NETWORK_ERROR', 'fr', 'Erreur réseau'),
('NO_DATA_RECEIVED', 'fr', 'Aucune donnée reçue'),
('INVALID_LOGIN_CREDENTIALS', 'fr', 'E-mail ou mot de passe incorrect'),
('FAILED_PARSE_RESPONSE', 'fr', "Échec de l'analyse de la réponse")
ON DUPLICATE KEY UPDATE translation_value = VALUES(translation_value);

-- German translations
INSERT INTO translations (translation_key, language_code, translation_value) VALUES
('WELCOME_BACK', 'de', 'Willkommen zurück'),
('SIGN_IN_TO_CONTINUE', 'de', 'Anmelden um fortzufahren'),
('EMAIL', 'de', 'E-Mail'),
('ENTER_EMAIL', 'de', 'E-Mail eingeben'),
('PASSWORD', 'de', 'Passwort'),
('ENTER_PASSWORD', 'de', 'Passwort eingeben'),
('FORGOT_PASSWORD', 'de', 'Passwort vergessen?'),
('FORGOT_PASSWORD_COMING_SOON', 'de', 'Passwortwiederherstellung kommt bald!'),
('SIGNING_IN', 'de', 'Anmeldung läuft...'),
('DONT_HAVE_ACCOUNT', 'de', 'Noch kein Konto?'),
('SIGN_UP', 'de', 'Registrieren'),
('SIGN_IN', 'de', 'Anmelden'),
('LOGIN', 'de', 'Anmelden'),
('OK', 'de', 'OK'),
('EMAIL_REQUIRED', 'de', 'E-Mail ist erforderlich'),
('INVALID_EMAIL', 'de', 'Ungültige E-Mail-Adresse'),
('PASSWORD_REQUIRED', 'de', 'Passwort ist erforderlich'),
('INVALID_URL', 'de', 'Ungültige URL'),
('NETWORK_ERROR', 'de', 'Netzwerkfehler'),
('NO_DATA_RECEIVED', 'de', 'Keine Daten empfangen'),
('INVALID_LOGIN_CREDENTIALS', 'de', 'E-Mail oder Passwort ungültig'),
('FAILED_PARSE_RESPONSE', 'de', 'Fehler beim Parsen der Antwort')
ON DUPLICATE KEY UPDATE translation_value = VALUES(translation_value);

SELECT 'LoginView translations added for 5 languages (en, ja, es, fr, de)' as status;
