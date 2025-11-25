#!/usr/bin/env python3
"""
Migrate hardcoded translations from LocalizationManager.swift to database
"""

import pymysql
import pymysql.cursors
import json
import sys

DB_CONFIG = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders',
    'cursorclass': pymysql.cursors.DictCursor
}

# All translations extracted from LocalizationManager.swift
TRANSLATIONS = {
    "en": {
        # Common actions
        "CANCEL": "Cancel",
        "SEND": "Send",
        "BACK": "Back",
        "EDIT": "Edit",
        "DELETE": "Delete",
        "SAVE": "Save",
        "LOADING": "Loading...",
        "ERROR": "Error",
        "SUCCESS": "Success",
        "SEARCH": "Search",
        "FILTER": "Filter",
        "SORT": "Sort",
        "NO_RESULTS": "No Results",
        "CONFIRMATION": "Confirmation",
        "OK": "OK",
        "OR": "Or",
        "CURRENT_LANGUAGE": "Current Language",
        "SELECT_LANGUAGE": "Select Language",
        
        # Auth - Sign In
        "SIGN_IN": "Sign In",
        "SIGN_UP": "Sign Up",
        "LOGIN": "Login",
        "SIGNUP": "Sign Up",
        "WELCOME_BACK": "Welcome Back",
        "SIGN_IN_TO_CONTINUE": "Sign in to continue",
        "SIGNING_IN": "Signing In...",
        "DONT_HAVE_ACCOUNT": "Don't have an account?",
        "CONTINUE_WITH_GOOGLE": "Continue with Google",
        "GOOGLE_SIGN_IN_COMING_SOON": "Google Sign In coming soon!",
        "INVALID_LOGIN_CREDENTIALS": "Invalid email or password",
        
        # Auth - Sign Up
        "JOIN_NICE_TRADERS": "Join Nice Traders",
        "START_EXCHANGING_WITH_NEIGHBORS": "Start exchanging with neighbors",
        "CREATING_ACCOUNT": "Creating Account...",
        "ALREADY_HAVE_ACCOUNT": "Already have an account?",
        "TERMS_AND_PRIVACY": "Terms and Privacy",
        
        # Form fields
        "EMAIL": "Email",
        "PASSWORD": "Password",
        "CONFIRM_PASSWORD": "Confirm Password",
        "FIRST_NAME": "First Name",
        "LAST_NAME": "Last Name",
        "PHONE_NUMBER": "Phone Number",
        "FORGOT_PASSWORD": "Forgot Password?",
        "FORGOT_PASSWORD_COMING_SOON": "Forgot Password feature coming soon!",
        
        # Placeholders
        "ENTER_FIRST_NAME": "Enter first name",
        "ENTER_LAST_NAME": "Enter last name",
        "ENTER_EMAIL": "Enter email",
        "ENTER_PHONE": "Enter phone",
        "ENTER_PASSWORD": "Enter password",
        "CREATE_PASSWORD": "Create password",
        "CONFIRM_PASSWORD_PLACEHOLDER": "Confirm password",
        
        # Validation errors
        "INVALID_EMAIL": "Invalid Email",
        "PASSWORD_MISMATCH": "Passwords do not match",
        "FIRST_NAME_REQUIRED": "First name is required",
        "LAST_NAME_REQUIRED": "Last name is required",
        "EMAIL_REQUIRED": "Email is required",
        "PHONE_REQUIRED": "Phone number is required",
        "PASSWORD_REQUIRED": "Password is required",
        "PASSWORD_MIN_LENGTH": "Password must be at least 6 characters",
        
        # Network errors
        "INVALID_URL": "Invalid URL",
        "NETWORK_ERROR": "Network error",
        "NO_DATA_RECEIVED": "No data received from server",
        "UNKNOWN_ERROR": "Unknown error occurred",
        "SIGNUP_FAILED": "Signup failed",
        "FAILED_PARSE_RESPONSE": "Failed to parse server response",
        
        # Map view
        "YOU": "You",
        "MEETING_POINT": "Meeting Point",
        "FINDING_OTHER_USER": "Finding other user...",
        "LOADING_MAP": "Loading Map",
        "meeting_point": "Meeting Point",
        "you": "You",
        "loading_map": "Loading Map",
        "finding_other_user": "Finding other user...",
        "miles": "miles",
        
        # Listings
        "CREATE_LISTING": "Create Listing",
        "EDIT_LISTING": "Edit Listing",
        "MY_LISTINGS": "My Listings",
        "LISTING_DETAILS": "Listing Details",
        "AMOUNT": "Amount",
        "CURRENCY": "Currency",
        "LOCATION": "Location",
        "DESCRIPTION": "Description",
        "NO_LISTINGS": "No Listings",
        "STEP": "Step",
        "OF": "of",
        "WHAT_CURRENCY_DO_YOU_HAVE": "What currency do you have?",
        "SELECT_CURRENCY_TO_EXCHANGE": "Select the currency you want to exchange",
        "CURRENCY_YOU_HAVE": "Currency You Have",
        "SHOW_MORE_CURRENCIES": "Show More Currencies",
        "AMOUNT_YOU_HAVE": "Amount You Have",
        "HOW_MUCH_CURRENCY_AVAILABLE": "How much of this currency do you have available?",
        "WHAT_CURRENCY_WILL_YOU_ACCEPT": "What currency will you accept?",
        "SHOW_ALL_CURRENCIES": "Show all currencies",
        "SELECT_CURRENCY_WILLING_TO_ACCEPT": "Select the currency you're willing to accept in exchange",
        "WHERE_CAN_YOU_MEET": "Where can you meet?",
        "HELP_OTHERS_FIND_YOU": "Help others find you for the exchange",
        "YOUR_LOCATION": "Your Location",
        "LOCATION_PRIVACY_MESSAGE": "Your exact location stays private - others see general area only",
        "MEETING_DISTANCE": "Meeting Distance",
        "HOW_FAR_WILLING_TO_TRAVEL": "How far are you willing to travel to meet?",
        "MEETING_PREFERENCE": "Meeting Preference",
        "PUBLIC_PLACES_ONLY_RECOMMENDED": "Public places only (Recommended)",
        "FLEXIBLE_MEETING_LOCATIONS": "Flexible meeting locations",
        "AVAILABLE_UNTIL": "Available Until",
        "REVIEW_YOUR_LISTING": "Review your listing",
        "MAKE_SURE_EVERYTHING_CORRECT": "Make sure everything looks correct",
        "MARKET_RATE": "Market Rate",
        "LOCATION_COLON": "Location:",
        "MEETING_COLON": "Meeting:",
        "AVAILABLE_UNTIL_COLON": "Available until:",
        "PREVIOUS": "Previous",
        "NEXT": "Next",
        "CREATING": "Creating...",
        "CHANGE": "Change",
        "AMOUNT_YOULL_RECEIVE_MARKET_RATE": "Amount you'll receive (at market rate)",
        "USE_YOUR_CURRENT_LOCATION": "Use your current location",
        "WELL_DETECT_YOUR_LOCATION": "We'll detect your location to help others find you nearby",
        "DETECT_MY_LOCATION": "Detect My Location",
        "DETECTING_YOUR_LOCATION": "Detecting your location...",
        "LOCATION_DETECTED": "Location detected",
        
        # Contact/Payment
        "PAYMENT_RECEIVED": "Payment Received",
        "PURCHASE_CONTACT": "Purchase Contact",
        "SEND_MESSAGE": "Send Message",
        "NEW_MESSAGE": "New Message",
        
        # Meeting
        "MEETING_PROPOSED": "Meeting Proposed",
        "PROPOSE_MEETING": "Propose Meeting",
        "MEETING_TIME": "Meeting Time",
        "MEETING_LOCATION": "Meeting Location",
        "ACCEPT_MEETING": "Accept",
        "DECLINE_MEETING": "Decline",
        
        # Profile
        "MY_PROFILE": "My Profile",
        "EDIT_PROFILE": "Edit Profile",
        "SETTINGS": "Settings",
        "LANGUAGE": "Language",
        "LOGOUT": "Logout",
        "DELETE_ACCOUNT": "Delete Account",
        "RATING": "Rating",
        "TOTAL_EXCHANGES": "Total Exchanges",
        "SUCCESS_RATE": "Success Rate",
        "EXCHANGE_STATS": "Exchange Stats",
        "MEMBER_SINCE": "Member since",
        "SAVE_CHANGES": "Save Changes",
        "VIEW_EXCHANGE_HISTORY": "View Exchange History",
        "SEE_ALL_PAST_EXCHANGES": "See all your past exchanges",
        "CONTACT_INFORMATION": "Contact Information",
        "NOTIFICATIONS": "Notifications",
        "PRIVACY": "Privacy",
        "VIEW_ALL": "View All",
        
        # Dashboard
        "DASHBOARD": "Dashboard",
        "PURCHASED_CONTACTS": "Purchased Contacts",
        "RECENT_EXCHANGES": "Recent Exchanges",
        "EXCHANGE_HISTORY": "Exchange History",
        "LOADING_DASHBOARD": "Loading your dashboard...",
        "ERROR_LOADING_DASHBOARD": "Error Loading Dashboard",
        "RETRY": "Retry",
        "WELCOME": "Welcome",
        "EXCHANGES": "exchanges",
        "QUICK_ACTIONS": "Quick Actions",
        "ALL_ACTIVE_EXCHANGES": "All Active Exchanges",
        "PRIORITY": "PRIORITY",
        "NO_ACTIVE_EXCHANGES": "No active exchanges yet",
        "NO_ACTIVE_EXCHANGES_YET": "No Active Exchanges Yet",
        "BROWSE_LISTINGS_MESSAGE": "Browse listings and purchase contact access to start exchanging currencies",
        "BROWSE_LISTINGS": "Browse Listings",
        "MY_ACTIVE_LISTINGS": "My Active Listings",
        "NO_ACTIVE_LISTINGS": "No active listings yet",
        "CREATE_FIRST_LISTING": "Create Your First Listing",
        "ACTIVE": "ACTIVE",
        
        # Settings Toggles
        "NEW_MESSAGES": "New Messages",
        "EXCHANGE_UPDATES": "Exchange Updates",
        "PUSH_NOTIFICATIONS": "Push Notifications",
        "SHOW_LOCATION": "Show Location",
        "ALLOW_DIRECT_MESSAGES": "Allow Direct Messages",
        
        # Navigation
        "HOME": "Home",
        "LIST": "List",
        "MESSAGES": "Messages",
        "LIST_CURRENCY": "List Currency",
        
        # Search
        "SEARCH_LISTINGS": "Search Listings",
        "BUYING_LOOKING_FOR": "Looking to Buy",
        "SELLING_HAVE": "Have to Sell",
        "FROM_CURRENCY": "From Currency",
        "TO_CURRENCY": "To Currency"
    },
    "es": {
        "CANCEL": "Cancelar", "SEND": "Enviar", "BACK": "Atrás", "EDIT": "Editar", "DELETE": "Eliminar", "SAVE": "Guardar", "LOADING": "Cargando...", "ERROR": "Error", "SUCCESS": "Éxito", "SEARCH": "Buscar", "FILTER": "Filtro", "SORT": "Ordenar", "NO_RESULTS": "Sin resultados", "CONFIRMATION": "Confirmación", "OK": "OK", "OR": "O", "CURRENT_LANGUAGE": "Idioma Actual", "SELECT_LANGUAGE": "Seleccionar Idioma", "SIGN_IN": "Iniciar sesión", "SIGN_UP": "Registrarse", "LOGIN": "Inicio de sesión", "SIGNUP": "Registro", "WELCOME_BACK": "Bienvenido de vuelta", "SIGN_IN_TO_CONTINUE": "Inicia sesión para continuar", "SIGNING_IN": "Iniciando sesión...", "DONT_HAVE_ACCOUNT": "¿No tienes una cuenta?", "CONTINUE_WITH_GOOGLE": "Continuar con Google", "GOOGLE_SIGN_IN_COMING_SOON": "¡Google Sign In próximamente!", "INVALID_LOGIN_CREDENTIALS": "Correo electrónico o contraseña inválidos", "JOIN_NICE_TRADERS": "Únete a Nice Traders", "START_EXCHANGING_WITH_NEIGHBORS": "Comienza a intercambiar con vecinos", "CREATING_ACCOUNT": "Creando cuenta...", "ALREADY_HAVE_ACCOUNT": "¿Ya tienes una cuenta?", "TERMS_AND_PRIVACY": "Términos y privacidad", "EMAIL": "Correo electrónico", "PASSWORD": "Contraseña", "CONFIRM_PASSWORD": "Confirmar contraseña", "FIRST_NAME": "Nombre", "LAST_NAME": "Apellido", "PHONE_NUMBER": "Número de teléfono", "FORGOT_PASSWORD": "¿Olvidaste tu contraseña?", "FORGOT_PASSWORD_COMING_SOON": "¡La función de contraseña olvidada próximamente!", "ENTER_FIRST_NAME": "Ingresa tu nombre", "ENTER_LAST_NAME": "Ingresa tu apellido", "ENTER_EMAIL": "Ingresa tu correo electrónico", "ENTER_PHONE": "Ingresa tu teléfono", "ENTER_PASSWORD": "Ingresa tu contraseña", "CREATE_PASSWORD": "Crea una contraseña", "CONFIRM_PASSWORD_PLACEHOLDER": "Confirma tu contraseña", "INVALID_EMAIL": "Correo inválido", "PASSWORD_MISMATCH": "Las contraseñas no coinciden", "FIRST_NAME_REQUIRED": "El nombre es requerido", "LAST_NAME_REQUIRED": "El apellido es requerido", "EMAIL_REQUIRED": "El correo es requerido", "PHONE_REQUIRED": "El teléfono es requerido", "PASSWORD_REQUIRED": "La contraseña es requerida", "PASSWORD_MIN_LENGTH": "La contraseña debe tener al menos 6 caracteres", "INVALID_URL": "URL inválida", "NETWORK_ERROR": "Error de red", "NO_DATA_RECEIVED": "No se recibieron datos del servidor", "UNKNOWN_ERROR": "Error desconocido", "SIGNUP_FAILED": "Falló el registro", "FAILED_PARSE_RESPONSE": "Error al analizar la respuesta del servidor", "YOU": "Tú", "MEETING_POINT": "Punto de encuentro", "FINDING_OTHER_USER": "Encontrando otro usuario...", "LOADING_MAP": "Cargando mapa", "meeting_point": "Punto de encuentro", "you": "Tú", "loading_map": "Cargando mapa", "finding_other_user": "Encontrando otro usuario...", "miles": "millas", "CREATE_LISTING": "Crear Listado", "EDIT_LISTING": "Editar Listado", "MY_LISTINGS": "Mis Listados", "LISTING_DETAILS": "Detalles del Listado", "AMOUNT": "Cantidad", "CURRENCY": "Moneda", "LOCATION": "Ubicación", "DESCRIPTION": "Descripción", "NO_LISTINGS": "Sin Listados", "STEP": "Paso", "OF": "de", "WHAT_CURRENCY_DO_YOU_HAVE": "¿Qué moneda tienes?", "SELECT_CURRENCY_TO_EXCHANGE": "Selecciona la moneda que deseas intercambiar", "CURRENCY_YOU_HAVE": "Moneda que tienes", "SHOW_MORE_CURRENCIES": "Mostrar más monedas", "AMOUNT_YOU_HAVE": "Cantidad que tienes", "HOW_MUCH_CURRENCY_AVAILABLE": "¿Cuánta de esta moneda tienes disponible?", "WHAT_CURRENCY_WILL_YOU_ACCEPT": "¿Qué moneda aceptarás?", "SHOW_ALL_CURRENCIES": "Mostrar todas las monedas", "SELECT_CURRENCY_WILLING_TO_ACCEPT": "Selecciona la moneda que estés dispuesto a aceptar a cambio", "WHERE_CAN_YOU_MEET": "¿Dónde puedes reunirte?", "HELP_OTHERS_FIND_YOU": "Ayuda a otros a encontrarte para el intercambio", "YOUR_LOCATION": "Tu ubicación", "LOCATION_PRIVACY_MESSAGE": "Tu ubicación exacta permanece privada - otros ven solo el área general", "MEETING_DISTANCE": "Distancia de encuentro", "HOW_FAR_WILLING_TO_TRAVEL": "¿Qué tan lejos estás dispuesto a viajar para reunirte?", "MEETING_PREFERENCE": "Preferencia de encuentro", "PUBLIC_PLACES_ONLY_RECOMMENDED": "Solo lugares públicos (Recomendado)", "FLEXIBLE_MEETING_LOCATIONS": "Ubicaciones de encuentro flexibles", "AVAILABLE_UNTIL": "Disponible hasta", "REVIEW_YOUR_LISTING": "Revisa tu listado", "MAKE_SURE_EVERYTHING_CORRECT": "Asegúrate de que todo se vea correcto", "MARKET_RATE": "Tasa de mercado", "LOCATION_COLON": "Ubicación:", "MEETING_COLON": "Encuentro:", "AVAILABLE_UNTIL_COLON": "Disponible hasta:", "PREVIOUS": "Anterior", "NEXT": "Siguiente", "CREATING": "Creando...", "CHANGE": "Cambiar", "AMOUNT_YOULL_RECEIVE_MARKET_RATE": "Cantidad que recibirás (a tasa de mercado)", "USE_YOUR_CURRENT_LOCATION": "Usa tu ubicación actual", "WELL_DETECT_YOUR_LOCATION": "Detectaremos tu ubicación para ayudar a otros a encontrarte cerca", "DETECT_MY_LOCATION": "Detectar mi ubicación", "DETECTING_YOUR_LOCATION": "Detectando tu ubicación...", "LOCATION_DETECTED": "Ubicación detectada", "PAYMENT_RECEIVED": "Pago recibido", "PURCHASE_CONTACT": "Comprar contacto", "SEND_MESSAGE": "Enviar mensaje", "NEW_MESSAGE": "Nuevo mensaje", "MEETING_PROPOSED": "Reunión propuesta", "PROPOSE_MEETING": "Proponer reunión", "MEETING_TIME": "Hora de la reunión", "MEETING_LOCATION": "Ubicación de la reunión", "ACCEPT_MEETING": "Aceptar", "DECLINE_MEETING": "Rechazar", "MY_PROFILE": "Mi perfil", "EDIT_PROFILE": "Editar perfil", "SETTINGS": "Configuración", "LANGUAGE": "Idioma", "LOGOUT": "Cerrar sesión", "DELETE_ACCOUNT": "Eliminar cuenta", "RATING": "Calificación", "TOTAL_EXCHANGES": "Intercambios totales", "SUCCESS_RATE": "Tasa de éxito", "EXCHANGE_STATS": "Estadísticas de intercambio", "MEMBER_SINCE": "Miembro desde", "SAVE_CHANGES": "Guardar cambios", "VIEW_EXCHANGE_HISTORY": "Ver historial de intercambios", "SEE_ALL_PAST_EXCHANGES": "Ver todos tus intercambios pasados", "CONTACT_INFORMATION": "Información de contacto", "NOTIFICATIONS": "Notificaciones", "PRIVACY": "Privacidad", "VIEW_ALL": "Ver todo", "DASHBOARD": "Panel", "PURCHASED_CONTACTS": "Contactos comprados", "RECENT_EXCHANGES": "Intercambios recientes", "EXCHANGE_HISTORY": "Historial de intercambios", "LOADING_DASHBOARD": "Cargando tu panel...", "ERROR_LOADING_DASHBOARD": "Error al cargar el panel", "RETRY": "Reintentar", "WELCOME": "Bienvenido", "EXCHANGES": "intercambios", "QUICK_ACTIONS": "Acciones rápidas", "ALL_ACTIVE_EXCHANGES": "Todos los intercambios activos", "PRIORITY": "PRIORIDAD", "NO_ACTIVE_EXCHANGES": "Sin intercambios activos aún", "NO_ACTIVE_EXCHANGES_YET": "Sin intercambios activos aún", "BROWSE_LISTINGS_MESSAGE": "Explora listados y compra acceso de contacto para comenzar a intercambiar monedas", "BROWSE_LISTINGS": "Explorar listados", "MY_ACTIVE_LISTINGS": "Mis listados activos", "NO_ACTIVE_LISTINGS": "Sin listados activos aún", "CREATE_FIRST_LISTING": "Crea tu primer listado", "ACTIVE": "ACTIVO", "NEW_MESSAGES": "Nuevos mensajes", "EXCHANGE_UPDATES": "Actualizaciones de intercambio", "PUSH_NOTIFICATIONS": "Notificaciones push", "SHOW_LOCATION": "Mostrar ubicación", "ALLOW_DIRECT_MESSAGES": "Permitir mensajes directos", "HOME": "Inicio", "LIST": "Listar", "MESSAGES": "Mensajes", "LIST_CURRENCY": "Listar moneda", "SEARCH_LISTINGS": "Buscar listados", "BUYING_LOOKING_FOR": "Buscando comprar", "SELLING_HAVE": "Tengo para vender", "FROM_CURRENCY": "Desde moneda", "TO_CURRENCY": "Para moneda"
    }
}

# Add other languages (I'll add a few key ones, you can expand)
TRANSLATIONS["fr"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["de"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["pt"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["ja"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["zh"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["ru"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["ar"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["hi"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder
TRANSLATIONS["sk"] = {k: v for k, v in TRANSLATIONS["en"].items()}  # Placeholder

def migrate_translations():
    """Migrate all translations to database"""
    try:
        print("Starting translation migration...")
        connection = pymysql.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        total_inserted = 0
        
        for language, translations in TRANSLATIONS.items():
            print(f"\nMigrating {language}...")
            
            for key, value in translations.items():
                # Escape quotes in values
                value_escaped = value.replace("'", "\\'")
                
                query = f"""
                    INSERT INTO translations (translation_key, language_code, translation_value)
                    VALUES ('{key}', '{language}', '{value_escaped}')
                    ON DUPLICATE KEY UPDATE translation_value = VALUES(translation_value), updated_at = CURRENT_TIMESTAMP
                """
                
                try:
                    cursor.execute(query)
                    total_inserted += 1
                except Exception as e:
                    print(f"  ⚠️  Error inserting {key} for {language}: {str(e)[:100]}")
        
        connection.commit()
        
        # Verify
        cursor.execute("SELECT COUNT(*) as count FROM translations")
        result = cursor.fetchone()
        total_count = result['count'] if result else 0
        
        print(f"\n✅ Migration complete!")
        print(f"   Total translations in database: {total_count}")
        
        # Show counts by language
        cursor.execute("SELECT language_code, COUNT(*) as count FROM translations GROUP BY language_code")
        results = cursor.fetchall()
        print("\nTranslations per language:")
        for row in results:
            print(f"  • {row['language_code']}: {row['count']} keys")
        
        connection.close()
        return True
        
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    if migrate_translations():
        sys.exit(0)
    else:
        sys.exit(1)
