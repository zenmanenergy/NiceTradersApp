//
//  LocalizationManager.swift
//  Nice Traders
//
//  Handles all localization and internationalization for the app
//  Uses database-driven translations from backend API with smart caching

import Foundation
import CoreLocation
import Combine

class LocalizationManager: NSObject, ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            languageVersion += 1
            // Fetch new language translations when changed
            Task {
                await downloadTranslations(for: currentLanguage)
            }
        }
    }
    
    @Published var languageVersion: Int = 0  // Increment this to force view updates
    @Published var isLoading: Bool = false
    
    static let shared = LocalizationManager()
    
    let supportedLanguages = [
        "en": "English 🇺🇸",
        "es": "Español 🇪🇸",
        "fr": "Français 🇫🇷",
        "de": "Deutsch 🇩🇪",
        "pt": "Português 🇵🇹",
        "ja": "日本語 🇯🇵",
        "zh": "中文 🇨🇳",
        "ru": "Русский 🇷🇺",
        "ar": "العربية 🇸🇦",
        "hi": "हिन्दी 🇮🇳",
        "sk": "Slovenčina 🇸🇰"
    ]
    
    private var cachedTranslations: [String: String] = [:]
    
    private override init() {
        self.currentLanguage = "en"
        super.init()
        
        // Try to load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguage = savedLanguage
        } else {
            // Auto-detect from system locale first
            let systemLocale = Locale.preferredLanguages.first ?? "en"
            let languageCode = String(systemLocale.prefix(2))
            self.currentLanguage = supportedLanguages[languageCode] != nil ? languageCode : "en"
        }
        
        // Load cached translations immediately
        loadFromCache(language: self.currentLanguage)
    }
    
    // MARK: - Language Detection from GPS
    
    /// Detect user's language based on their current GPS location
    /// Falls back to system locale if GPS access is unavailable
    func initializeLanguageFromLocation(_ locationManager: CLLocationManager) {
        // If we already have a saved preference, use it
        if UserDefaults.standard.string(forKey: "AppLanguage") != nil {
            return
        }
        
        // For now, just use detected language from Locale
        // Can integrate GPS-based detection later if needed
        let systemLocale = Locale.preferredLanguages.first ?? "en"
        let languageCode = String(systemLocale.prefix(2))
        if supportedLanguages[languageCode] != nil {
            DispatchQueue.main.async {
                self.currentLanguage = languageCode
                UserDefaults.standard.set(languageCode, forKey: "AppLanguage")
            }
        }
    }
    
    // MARK: - Backend Synchronization
    
    private func saveLanguagePreferenceToBackend(languageCode: String, userId: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("⚠️ [LocalizationManager] No session ID, skipping backend save")
            return
        }
        
        let backendURL = "\(Settings.shared.baseURL)/Profile/UpdateProfile"
        guard let url = URL(string: backendURL) else {
            print("⚠️ [LocalizationManager] Invalid URL: \(backendURL)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "SessionId": sessionId,
            "preferred_language": languageCode
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ [LocalizationManager] Error saving language to backend: \(error.localizedDescription)")
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool {
                    if success {
                        print("✅ [LocalizationManager] Language saved to backend: \(languageCode)")
                    } else {
                        print("⚠️ [LocalizationManager] Backend save failed: \(json["error"] as? String ?? "Unknown error")")
                    }
                }
            }.resume()
        } catch {
            print("❌ [LocalizationManager] Error encoding language preference: \(error.localizedDescription)")
        }
    }
    
    /// Load language preference from backend for logged-in user
    func loadLanguageFromBackend() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("⚠️ [LocalizationManager] No session ID, cannot load language from backend")
            return
        }
        
        let backendURL = "\(Settings.shared.baseURL)/Profile/GetProfile?SessionId=\(sessionId)"
        guard let url = URL(string: backendURL) else {
            print("⚠️ [LocalizationManager] Invalid URL: \(backendURL)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ [LocalizationManager] Error loading language from backend: \(error.localizedDescription)")
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               success,
               let profile = json["profile"] as? [String: Any],
               let preferredLanguage = profile["preferredLanguage"] as? String {
                
                DispatchQueue.main.async {
                    print("📥 [LocalizationManager] Loaded language from backend: \(preferredLanguage)")
                    self.currentLanguage = preferredLanguage
                }
            }
        }.resume()
    }
    
    // MARK: - Translation Fetching & Caching
    
    /// Initialize translations on app startup
    /// Checks cache first, then server for updates
    func initializeTranslations() {
        Task {
            await checkAndSyncTranslations()
        }
    }
    
    /// Check if translations need updating from server
    /// Only downloads if server has newer data than cached
    private func checkAndSyncTranslations() async {
        // Load from cache immediately
        loadFromCache(language: currentLanguage)
        
        // Check server for updates
        await checkForTranslationUpdates()
    }
    
    /// Check if server has newer translations than cached version
    private func checkForTranslationUpdates() async {
        let endpoint = "\(Settings.shared.baseURL)/Translations/GetLastUpdated"
        guard let url = URL(string: endpoint) else {
            print("⚠️ [LocalizationManager] Invalid URL: \(endpoint)")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LastUpdatedResponse.self, from: data)
            
            if response.success,
               let serverTimestamp = response.last_updated[currentLanguage],
               let cachedTimestamp = UserDefaults.standard.string(forKey: "translations_\(currentLanguage)_timestamp") {
                
                // If server is newer, download updates
                if serverTimestamp > cachedTimestamp {
                    print("🔄 [LocalizationManager] Translations are outdated, downloading new version")
                    await downloadTranslations(for: currentLanguage)
                }
            } else if response.success {
                // No cached version, download from server
                await downloadTranslations(for: currentLanguage)
            }
        } catch {
            print("⚠️ [LocalizationManager] Error checking translation updates: \(error.localizedDescription)")
            // Use cached version, no crash
        }
    }
    
    /// Download all translations for a language from server
    private func downloadTranslations(for language: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let endpoint = "\(Settings.shared.baseURL)/Translations/GetTranslations"
        guard var urlComponents = URLComponents(string: endpoint) else {
            print("⚠️ [LocalizationManager] Invalid URL: \(endpoint)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "language", value: language)]
        guard let url = urlComponents.url else {
            print("⚠️ [LocalizationManager] Failed to construct URL")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TranslationsResponse.self, from: data)
            
            if response.success {
                DispatchQueue.main.async {
                    // Cache the translations
                    self.cachedTranslations = response.translations
                    UserDefaults.standard.setValue(response.translations, forKey: "translations_\(language)")
                    UserDefaults.standard.setValue(response.last_updated, forKey: "translations_\(language)_timestamp")
                    
                    print("✅ [LocalizationManager] Downloaded \(response.count) translations for \(language)")
                    self.languageVersion += 1
                    self.isLoading = false
                }
            } else {
                print("⚠️ [LocalizationManager] Server returned error: \(response.message ?? "Unknown")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        } catch {
            print("⚠️ [LocalizationManager] Error downloading translations: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            // Use cached version on error
        }
    }
    
    /// Load translations from cache
    private func loadFromCache(language: String) {
        if let cached = UserDefaults.standard.dictionary(forKey: "translations_\(language)") as? [String: String] {
            self.cachedTranslations = cached
            print("📦 [LocalizationManager] Loaded \(cached.count) cached translations for \(language)")
        } else {
            print("ℹ️ [LocalizationManager] No cached translations found for \(language)")
            self.cachedTranslations = [:]
        }
    }
    
    // MARK: - String Localization
    
    // Hardcoded translations dictionary
    private let translations: [String: [String: String]] = [
        "en": [
            // Common actions
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
            
            // Auth - Sign In
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
            
            // Auth - Sign Up
            "JOIN_NICE_TRADERS": "Join Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "Start exchanging with neighbors",
            "CREATING_ACCOUNT": "Creating Account...",
            "ALREADY_HAVE_ACCOUNT": "Already have an account?",
            "TERMS_AND_PRIVACY": "Terms and Privacy",
            
            // Form fields
            "EMAIL": "Email",
            "PASSWORD": "Password",
            "CONFIRM_PASSWORD": "Confirm Password",
            "FIRST_NAME": "First Name",
            "LAST_NAME": "Last Name",
            "PHONE_NUMBER": "Phone Number",
            "FORGOT_PASSWORD": "Forgot Password?",
            "FORGOT_PASSWORD_COMING_SOON": "Forgot Password feature coming soon!",
            
            // Placeholders
            "ENTER_FIRST_NAME": "Enter first name",
            "ENTER_LAST_NAME": "Enter last name",
            "ENTER_EMAIL": "Enter email",
            "ENTER_PHONE": "Enter phone",
            "ENTER_PASSWORD": "Enter password",
            "CREATE_PASSWORD": "Create password",
            "CONFIRM_PASSWORD_PLACEHOLDER": "Confirm password",
            
            // Validation errors
            "INVALID_EMAIL": "Invalid Email",
            "PASSWORD_MISMATCH": "Passwords do not match",
            "FIRST_NAME_REQUIRED": "First name is required",
            "LAST_NAME_REQUIRED": "Last name is required",
            "EMAIL_REQUIRED": "Email is required",
            "PHONE_REQUIRED": "Phone number is required",
            "PASSWORD_REQUIRED": "Password is required",
            "PASSWORD_MIN_LENGTH": "Password must be at least 6 characters",
            
            // Network errors
            "INVALID_URL": "Invalid URL",
            "NETWORK_ERROR": "Network error",
            "NO_DATA_RECEIVED": "No data received from server",
            "UNKNOWN_ERROR": "Unknown error occurred",
            "SIGNUP_FAILED": "Signup failed",
            "FAILED_PARSE_RESPONSE": "Failed to parse server response",
            
            // Map view
            "YOU": "You",
            "MEETING_POINT": "Meeting Point",
            "FINDING_OTHER_USER": "Finding other user...",
            "LOADING_MAP": "Loading Map",
            "meeting_point": "Meeting Point",
            "you": "You",
            "loading_map": "Loading Map",
            "finding_other_user": "Finding other user...",
            "miles": "miles",
            
            // Listings
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
            
            // Contact/Payment
            "PAYMENT_RECEIVED": "Payment Received",
            "PURCHASE_CONTACT": "Purchase Contact",
            "SEND_MESSAGE": "Send Message",
            "NEW_MESSAGE": "New Message",
            
            // Meeting
            "MEETING_PROPOSED": "Meeting Proposed",
            "PROPOSE_MEETING": "Propose Meeting",
            "MEETING_TIME": "Meeting Time",
            "MEETING_LOCATION": "Meeting Location",
            "ACCEPT_MEETING": "Accept",
            "DECLINE_MEETING": "Decline",
            
            // Profile
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
            
            // Dashboard
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
            
            // Settings Toggles
            "NEW_MESSAGES": "New Messages",
            "EXCHANGE_UPDATES": "Exchange Updates",
            "PUSH_NOTIFICATIONS": "Push Notifications",
            "SHOW_LOCATION": "Show Location",
            "ALLOW_DIRECT_MESSAGES": "Allow Direct Messages",
            
            // Navigation
            "HOME": "Home",
            "LIST": "List",
            "MESSAGES": "Messages",
            "LIST_CURRENCY": "List Currency",
            
            // Search
            "SEARCH_LISTINGS": "Search Listings",
            "BUYING_LOOKING_FOR": "Looking to Buy",
            "SELLING_HAVE": "Have to Sell",
            "FROM_CURRENCY": "From Currency",
            "TO_CURRENCY": "To Currency"
        ],
        "es": [
            "CANCEL": "Cancelar",
            "SEND": "Enviar",
            "BACK": "Atrás",
            "EDIT": "Editar",
            "DELETE": "Eliminar",
            "SAVE": "Guardar",
            "LOADING": "Cargando...",
            "ERROR": "Error",
            "SUCCESS": "Éxito",
            "SEARCH": "Buscar",
            "OK": "OK",
            "OR": "O",
            "SIGN_IN": "Iniciar Sesión",
            "SIGN_UP": "Registrarse",
            "LOGIN": "Iniciar Sesión",
            "SIGNUP": "Registrarse",
            "WELCOME_BACK": "Bienvenido de Nuevo",
            "SIGN_IN_TO_CONTINUE": "Inicia sesión para continuar",
            "SIGNING_IN": "Iniciando Sesión...",
            "DONT_HAVE_ACCOUNT": "¿No tienes cuenta?",
            "JOIN_NICE_TRADERS": "Únete a Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "Empieza a intercambiar con vecinos",
            "CREATING_ACCOUNT": "Creando Cuenta...",
            "ALREADY_HAVE_ACCOUNT": "¿Ya tienes cuenta?",
            "EMAIL": "Correo",
            "PASSWORD": "Contraseña",
            "CONFIRM_PASSWORD": "Confirmar Contraseña",
            "FIRST_NAME": "Nombre",
            "LAST_NAME": "Apellido",
            "PHONE_NUMBER": "Teléfono",
            "ENTER_FIRST_NAME": "Ingresa tu nombre",
            "ENTER_LAST_NAME": "Ingresa tu apellido",
            "ENTER_EMAIL": "Ingresa tu correo",
            "ENTER_PHONE": "Ingresa tu teléfono",
            "ENTER_PASSWORD": "Ingresa tu contraseña",
            "CREATE_PASSWORD": "Crea una contraseña",
            "CONFIRM_PASSWORD_PLACEHOLDER": "Confirma tu contraseña",
            "FIRST_NAME_REQUIRED": "El nombre es requerido",
            "LAST_NAME_REQUIRED": "El apellido es requerido",
            "EMAIL_REQUIRED": "El correo es requerido",
            "PHONE_REQUIRED": "El teléfono es requerido",
            "PASSWORD_REQUIRED": "La contraseña es requerida",
            "PASSWORD_MIN_LENGTH": "La contraseña debe tener al menos 6 caracteres",
            
            // Profile
            "MY_PROFILE": "Mi Perfil",
            "EDIT_PROFILE": "Editar Perfil",
            "SETTINGS": "Configuración",
            "LANGUAGE": "Idioma",
            "LOGOUT": "Cerrar Sesión",
            "DELETE_ACCOUNT": "Eliminar Cuenta",
            "RATING": "Calificación",
            "TOTAL_EXCHANGES": "Intercambios Totales",
            "SUCCESS_RATE": "Tasa de Éxito",
            "EXCHANGE_STATS": "Estadísticas de Intercambio",
            "MEMBER_SINCE": "Miembro desde",
            "SAVE_CHANGES": "Guardar Cambios",
            "VIEW_EXCHANGE_HISTORY": "Ver Historial de Intercambios",
            "SEE_ALL_PAST_EXCHANGES": "Ver todos tus intercambios pasados",
            "CONTACT_INFORMATION": "Información de Contacto",
            "NOTIFICATIONS": "Notificaciones",
            "PRIVACY": "Privacidad",
            "VIEW_ALL": "Ver Todo",
            "RECENT_EXCHANGES": "Intercambios Recientes",
            "EXCHANGE_HISTORY": "Historial de Intercambios",
            
            // Dashboard
            "LOADING_DASHBOARD": "Cargando tu panel...",
            "ERROR_LOADING_DASHBOARD": "Error al Cargar el Panel",
            "RETRY": "Reintentar",
            "WELCOME": "Bienvenido",
            "EXCHANGES": "intercambios",
            "QUICK_ACTIONS": "Acciones Rápidas",
            "ALL_ACTIVE_EXCHANGES": "Todos los Intercambios Activos",
            "PRIORITY": "PRIORIDAD",
            "NO_ACTIVE_EXCHANGES": "Aún no hay intercambios activos",
            "NO_ACTIVE_EXCHANGES_YET": "Aún No Hay Intercambios Activos",
            "BROWSE_LISTINGS_MESSAGE": "Explora listados y compra acceso de contacto para comenzar a intercambiar monedas",
            "BROWSE_LISTINGS": "Explorar Listados",
            "MY_ACTIVE_LISTINGS": "Mis Listados Activos",
            "NO_ACTIVE_LISTINGS": "Aún no hay listados activos",
            "CREATE_FIRST_LISTING": "Crea Tu Primer Listado",
            "ACTIVE": "ACTIVO",
            "EDIT_LISTING": "Editar Listado",
            
            // Settings Toggles
            "NEW_MESSAGES": "Nuevos Mensajes",
            "EXCHANGE_UPDATES": "Actualizaciones de Intercambio",
            "PUSH_NOTIFICATIONS": "Notificaciones Push",
            "SHOW_LOCATION": "Mostrar Ubicación",
            "ALLOW_DIRECT_MESSAGES": "Permitir Mensajes Directos",
            
            // Navigation
            "HOME": "Inicio",
            "LIST": "Listar",
            "MESSAGES": "Mensajes",
            "LIST_CURRENCY": "Listar Moneda"
        ],
        "fr": [
            "CANCEL": "Annuler",
            "SEND": "Envoyer",
            "BACK": "Retour",
            "EDIT": "Modifier",
            "DELETE": "Supprimer",
            "SAVE": "Enregistrer",
            "LOADING": "Chargement...",
            "ERROR": "Erreur",
            "SUCCESS": "Succès",
            "SEARCH": "Rechercher",
            "OK": "OK",
            "OR": "Ou",
            "SIGN_IN": "Se Connecter",
            "SIGN_UP": "S'inscrire",
            "LOGIN": "Connexion",
            "SIGNUP": "Inscription",
            "WELCOME_BACK": "Bon Retour",
            "SIGN_IN_TO_CONTINUE": "Connectez-vous pour continuer",
            "SIGNING_IN": "Connexion...",
            "DONT_HAVE_ACCOUNT": "Pas de compte?",
            "JOIN_NICE_TRADERS": "Rejoignez Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "Commencez à échanger avec vos voisins",
            "CREATING_ACCOUNT": "Création du Compte...",
            "ALREADY_HAVE_ACCOUNT": "Vous avez déjà un compte?",
            "EMAIL": "Email",
            "PASSWORD": "Mot de Passe",
            "CONFIRM_PASSWORD": "Confirmer le Mot de Passe",
            "FIRST_NAME": "Prénom",
            "LAST_NAME": "Nom",
            "PHONE_NUMBER": "Téléphone",
            "ENTER_FIRST_NAME": "Entrez votre prénom",
            "ENTER_LAST_NAME": "Entrez votre nom",
            "ENTER_EMAIL": "Entrez votre email",
            "ENTER_PHONE": "Entrez votre téléphone",
            "ENTER_PASSWORD": "Entrez votre mot de passe",
            "CREATE_PASSWORD": "Créez un mot de passe",
            "CONFIRM_PASSWORD_PLACEHOLDER": "Confirmez le mot de passe",
            
            // Profile
            "MY_PROFILE": "Mon Profil",
            "EDIT_PROFILE": "Modifier le Profil",
            "SETTINGS": "Paramètres",
            "LANGUAGE": "Langue",
            "LOGOUT": "Déconnexion",
            "DELETE_ACCOUNT": "Supprimer le Compte",
            "RATING": "Note",
            "TOTAL_EXCHANGES": "Échanges Totaux",
            "SUCCESS_RATE": "Taux de Réussite",
            "EXCHANGE_STATS": "Statistiques d'Échange",
            "MEMBER_SINCE": "Membre depuis",
            "SAVE_CHANGES": "Enregistrer les Modifications",
            "VIEW_EXCHANGE_HISTORY": "Voir l'Historique des Échanges",
            "SEE_ALL_PAST_EXCHANGES": "Voir tous vos échanges passés",
            "CONTACT_INFORMATION": "Informations de Contact",
            "NOTIFICATIONS": "Notifications",
            "PRIVACY": "Confidentialité",
            "VIEW_ALL": "Tout Voir",
            "RECENT_EXCHANGES": "Échanges Récents",
            "EXCHANGE_HISTORY": "Historique des Échanges",
            
            // Dashboard
            "LOADING_DASHBOARD": "Chargement de votre tableau de bord...",
            "ERROR_LOADING_DASHBOARD": "Erreur de Chargement du Tableau de Bord",
            "RETRY": "Réessayer",
            "WELCOME": "Bienvenue",
            "EXCHANGES": "échanges",
            "QUICK_ACTIONS": "Actions Rapides",
            "ALL_ACTIVE_EXCHANGES": "Tous les Échanges Actifs",
            "PRIORITY": "PRIORITÉ",
            "NO_ACTIVE_EXCHANGES": "Pas encore d'échanges actifs",
            "NO_ACTIVE_EXCHANGES_YET": "Pas Encore d'Échanges Actifs",
            "BROWSE_LISTINGS_MESSAGE": "Parcourez les annonces et achetez l'accès aux contacts pour commencer à échanger des devises",
            "BROWSE_LISTINGS": "Parcourir les Annonces",
            "MY_ACTIVE_LISTINGS": "Mes Annonces Actives",
            "NO_ACTIVE_LISTINGS": "Pas encore d'annonces actives",
            "CREATE_FIRST_LISTING": "Créez Votre Première Annonce",
            "ACTIVE": "ACTIF",
            "EDIT_LISTING": "Modifier l'Annonce",
            
            // Settings Toggles
            "NEW_MESSAGES": "Nouveaux Messages",
            "EXCHANGE_UPDATES": "Mises à Jour d'Échange",
            "PUSH_NOTIFICATIONS": "Notifications Push",
            "SHOW_LOCATION": "Afficher l'Emplacement",
            "ALLOW_DIRECT_MESSAGES": "Autoriser les Messages Directs",
            
            // Navigation
            "HOME": "Accueil",
            "LIST": "Liste",
            "MESSAGES": "Messages",
            "LIST_CURRENCY": "Lister la Devise"
        ],
        "de": [
            "CANCEL": "Abbrechen",
            "SEND": "Senden",
            "BACK": "Zurück",
            "EDIT": "Bearbeiten",
            "DELETE": "Löschen",
            "SAVE": "Speichern",
            "LOADING": "Laden...",
            "ERROR": "Fehler",
            "SUCCESS": "Erfolg",
            "SEARCH": "Suchen",
            "OK": "OK",
            "OR": "Oder",
            "SIGN_IN": "Anmelden",
            "SIGN_UP": "Registrieren",
            "LOGIN": "Anmeldung",
            "SIGNUP": "Registrierung",
            "WELCOME_BACK": "Willkommen Zurück",
            "SIGN_IN_TO_CONTINUE": "Melden Sie sich an, um fortzufahren",
            "SIGNING_IN": "Anmeldung...",
            "DONT_HAVE_ACCOUNT": "Noch kein Konto?",
            "JOIN_NICE_TRADERS": "Treten Sie Nice Traders bei",
            "START_EXCHANGING_WITH_NEIGHBORS": "Beginnen Sie mit Ihren Nachbarn zu tauschen",
            "CREATING_ACCOUNT": "Konto Erstellen...",
            "ALREADY_HAVE_ACCOUNT": "Haben Sie bereits ein Konto?",
            "EMAIL": "E-Mail",
            "PASSWORD": "Passwort",
            "FIRST_NAME": "Vorname",
            "LAST_NAME": "Nachname",
            "PHONE_NUMBER": "Telefon",
            
            // Profile
            "MY_PROFILE": "Mein Profil",
            "EDIT_PROFILE": "Profil Bearbeiten",
            "SETTINGS": "Einstellungen",
            "LANGUAGE": "Sprache",
            "LOGOUT": "Abmelden",
            "DELETE_ACCOUNT": "Konto Löschen",
            "RATING": "Bewertung",
            "TOTAL_EXCHANGES": "Gesamt-Tauschgeschäfte",
            "SUCCESS_RATE": "Erfolgsquote",
            "EXCHANGE_STATS": "Tausch-Statistiken",
            "MEMBER_SINCE": "Mitglied seit",
            "SAVE_CHANGES": "Änderungen Speichern",
            "VIEW_EXCHANGE_HISTORY": "Tauschverlauf Anzeigen",
            "SEE_ALL_PAST_EXCHANGES": "Alle vergangenen Tauschgeschäfte anzeigen",
            "CONTACT_INFORMATION": "Kontaktinformationen",
            "NOTIFICATIONS": "Benachrichtigungen",
            "PRIVACY": "Datenschutz",
            "VIEW_ALL": "Alle Anzeigen",
            "RECENT_EXCHANGES": "Letzte Tauschgeschäfte",
            "EXCHANGE_HISTORY": "Tauschverlauf",
            
            // Dashboard
            "LOADING_DASHBOARD": "Ihr Dashboard wird geladen...",
            "ERROR_LOADING_DASHBOARD": "Fehler beim Laden des Dashboards",
            "RETRY": "Erneut Versuchen",
            "WELCOME": "Willkommen",
            "EXCHANGES": "Tauschgeschäfte",
            "QUICK_ACTIONS": "Schnellaktionen",
            "ALL_ACTIVE_EXCHANGES": "Alle Aktiven Tauschgeschäfte",
            "PRIORITY": "PRIORITÄT",
            "NO_ACTIVE_EXCHANGES": "Noch keine aktiven Tauschgeschäfte",
            "NO_ACTIVE_EXCHANGES_YET": "Noch Keine Aktiven Tauschgeschäfte",
            "BROWSE_LISTINGS_MESSAGE": "Durchsuchen Sie Angebote und kaufen Sie Kontaktzugriff, um mit dem Währungstausch zu beginnen",
            "BROWSE_LISTINGS": "Angebote Durchsuchen",
            "MY_ACTIVE_LISTINGS": "Meine Aktiven Angebote",
            "NO_ACTIVE_LISTINGS": "Noch keine aktiven Angebote",
            "CREATE_FIRST_LISTING": "Erstellen Sie Ihr Erstes Angebot",
            "ACTIVE": "AKTIV",
            "EDIT_LISTING": "Angebot Bearbeiten",
            
            // Settings Toggles
            "NEW_MESSAGES": "Neue Nachrichten",
            "EXCHANGE_UPDATES": "Tausch-Updates",
            "PUSH_NOTIFICATIONS": "Push-Benachrichtigungen",
            "SHOW_LOCATION": "Standort Anzeigen",
            "ALLOW_DIRECT_MESSAGES": "Direktnachrichten Erlauben",
            
            // Navigation
            "HOME": "Startseite",
            "LIST": "Liste",
            "MESSAGES": "Nachrichten",
            "LIST_CURRENCY": "Währung Auflisten"
        ],
        "sk": [
            "CANCEL": "Zrušiť",
            "SEND": "Odoslať",
            "BACK": "Späť",
            "EDIT": "Upraviť",
            "DELETE": "Vymazať",
            "SAVE": "Uložiť",
            "LOADING": "Načítava sa...",
            "ERROR": "Chyba",
            "SUCCESS": "Úspech",
            "SEARCH": "Hľadať",
            "OK": "OK",
            "OR": "Alebo",
            "SIGN_IN": "Prihlásiť sa",
            "SIGN_UP": "Registrovať sa",
            "LOGIN": "Prihlásenie",
            "SIGNUP": "Registrácia",
            "WELCOME_BACK": "Vitajte späť",
            "SIGN_IN_TO_CONTINUE": "Prihláste sa na pokračovanie",
            "SIGNING_IN": "Prihlasovanie...",
            "DONT_HAVE_ACCOUNT": "Nemáte účet?",
            "JOIN_NICE_TRADERS": "Pripojte sa k Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "Začnite vymieňať so susedmi",
            "CREATING_ACCOUNT": "Vytváranie účtu...",
            "ALREADY_HAVE_ACCOUNT": "Už máte účet?",
            "EMAIL": "Email",
            "PASSWORD": "Heslo",
            "FIRST_NAME": "Meno",
            "LAST_NAME": "Priezvisko",
            "PHONE_NUMBER": "Telefón",
            "CURRENT_LANGUAGE": "Súčasný Jazyk",
            "SELECT_LANGUAGE": "Vybrať Jazyk",
            "LANGUAGE": "Jazyk",
            
            // Profile
            "MY_PROFILE": "Môj Profil",
            "EDIT_PROFILE": "Upraviť Profil",
            "SETTINGS": "Nastavenia",
            "LOGOUT": "Odhlásiť sa",
            "DELETE_ACCOUNT": "Vymazať Účet",
            "RATING": "Hodnotenie",
            "TOTAL_EXCHANGES": "Celkové Výmeny",
            "SUCCESS_RATE": "Úspešnosť",
            "EXCHANGE_STATS": "Štatistiky Výmen",
            "MEMBER_SINCE": "Člen od",
            "SAVE_CHANGES": "Uložiť Zmeny",
            "VIEW_EXCHANGE_HISTORY": "Zobraziť Históriu Výmen",
            "SEE_ALL_PAST_EXCHANGES": "Zobraziť všetky minulé výmeny",
            "CONTACT_INFORMATION": "Kontaktné Informácie",
            "NOTIFICATIONS": "Oznámenia",
            "PRIVACY": "Súkromie",
            "VIEW_ALL": "Zobraziť Všetko",
            "RECENT_EXCHANGES": "Nedávne Výmeny",
            "EXCHANGE_HISTORY": "História Výmen",
            
            // Dashboard
            "LOADING_DASHBOARD": "Načítava sa váš panel...",
            "ERROR_LOADING_DASHBOARD": "Chyba pri Načítaní Panela",
            "RETRY": "Skúsiť Znova",
            "WELCOME": "Vitajte",
            "EXCHANGES": "výmeny",
            "QUICK_ACTIONS": "Rýchle Akcie",
            "ALL_ACTIVE_EXCHANGES": "Všetky Aktívne Výmeny",
            "PRIORITY": "PRIORITA",
            "NO_ACTIVE_EXCHANGES": "Zatiaľ žiadne aktívne výmeny",
            "NO_ACTIVE_EXCHANGES_YET": "Zatiaľ Žiadne Aktívne Výmeny",
            "BROWSE_LISTINGS_MESSAGE": "Prehliadajte si zoznamy a kúpte si prístup ku kontaktom, aby ste mohli začať vymieňať meny",
            "BROWSE_LISTINGS": "Prehliadať Zoznamy",
            "MY_ACTIVE_LISTINGS": "Moje Aktívne Zoznamy",
            "NO_ACTIVE_LISTINGS": "Zatiaľ žiadne aktívne zoznamy",
            "CREATE_FIRST_LISTING": "Vytvorte Svoj Prvý Zoznam",
            "ACTIVE": "AKTÍVNE",
            "EDIT_LISTING": "Upraviť Zoznam",
            
            // Settings Toggles
            "NEW_MESSAGES": "Nové Správy",
            "EXCHANGE_UPDATES": "Aktualizácie Výmen",
            "PUSH_NOTIFICATIONS": "Oznámenia Push",
            "SHOW_LOCATION": "Zobraziť Polohu",
            "ALLOW_DIRECT_MESSAGES": "Povoliť Priame Správy",
            
            // Navigation
            "HOME": "Domov",
            "LIST": "Zoznam",
            "MESSAGES": "Správy",
            "LIST_CURRENCY": "Vypísať Menu"
        ],
        "zh": [
            "CANCEL": "取消",
            "SEND": "发送",
            "BACK": "返回",
            "EDIT": "编辑",
            "DELETE": "删除",
            "SAVE": "保存",
            "LOADING": "加载中...",
            "ERROR": "错误",
            "SUCCESS": "成功",
            "SEARCH": "搜索",
            "OK": "好的",
            "OR": "或",
            "SIGN_IN": "登录",
            "SIGN_UP": "注册",
            "LOGIN": "登录",
            "SIGNUP": "注册",
            "WELCOME_BACK": "欢迎回来",
            "SIGN_IN_TO_CONTINUE": "登录以继续",
            "SIGNING_IN": "正在登录...",
            "DONT_HAVE_ACCOUNT": "没有账户?",
            "JOIN_NICE_TRADERS": "加入Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "开始与邻居交换",
            "CREATING_ACCOUNT": "创建账户...",
            "ALREADY_HAVE_ACCOUNT": "已有账户?",
            "EMAIL": "邮箱",
            "PASSWORD": "密码",
            "CONFIRM_PASSWORD": "确认密码",
            "FIRST_NAME": "名字",
            "LAST_NAME": "姓氏",
            "PHONE_NUMBER": "电话号码",
            "ENTER_FIRST_NAME": "输入名字",
            "ENTER_LAST_NAME": "输入姓氏",
            "ENTER_EMAIL": "输入邮箱",
            "ENTER_PHONE": "输入电话",
            "ENTER_PASSWORD": "输入密码",
            "CREATE_PASSWORD": "创建密码",
            "CONFIRM_PASSWORD_PLACEHOLDER": "确认密码",
            "CURRENT_LANGUAGE": "当前语言",
            "SELECT_LANGUAGE": "选择语言",
            "LANGUAGE": "语言",
            
            // Profile
            "MY_PROFILE": "我的资料",
            "EDIT_PROFILE": "编辑资料",
            "SETTINGS": "设置",
            "LOGOUT": "登出",
            "DELETE_ACCOUNT": "删除账户",
            "RATING": "评分",
            "TOTAL_EXCHANGES": "总交换次数",
            "SUCCESS_RATE": "成功率",
            "EXCHANGE_STATS": "交换统计",
            "MEMBER_SINCE": "会员自",
            "SAVE_CHANGES": "保存更改",
            "VIEW_EXCHANGE_HISTORY": "查看交换历史",
            "SEE_ALL_PAST_EXCHANGES": "查看所有过去的交换",
            "CONTACT_INFORMATION": "联系信息",
            "NOTIFICATIONS": "通知",
            "PRIVACY": "隐私",
            "VIEW_ALL": "查看全部",
            "RECENT_EXCHANGES": "最近交换",
            "EXCHANGE_HISTORY": "交换历史",
            
            // Dashboard
            "LOADING_DASHBOARD": "正在加载您的仪表板...",
            "ERROR_LOADING_DASHBOARD": "加载仪表板时出错",
            "RETRY": "重试",
            "WELCOME": "欢迎",
            "EXCHANGES": "交换",
            "QUICK_ACTIONS": "快速操作",
            "ALL_ACTIVE_EXCHANGES": "所有活跃交换",
            "PRIORITY": "优先",
            "NO_ACTIVE_EXCHANGES": "暂无活跃交换",
            "NO_ACTIVE_EXCHANGES_YET": "暂无活跃交换",
            "BROWSE_LISTINGS_MESSAGE": "浏览列表并购买联系访问权以开始交换货币",
            "BROWSE_LISTINGS": "浏览列表",
            "MY_ACTIVE_LISTINGS": "我的活跃列表",
            "NO_ACTIVE_LISTINGS": "暂无活跃列表",
            "CREATE_FIRST_LISTING": "创建您的第一个列表",
            "ACTIVE": "活跃",
            "EDIT_LISTING": "编辑列表",
            
            // Settings Toggles
            "NEW_MESSAGES": "新消息",
            "EXCHANGE_UPDATES": "交换更新",
            "PUSH_NOTIFICATIONS": "推送通知",
            "SHOW_LOCATION": "显示位置",
            "ALLOW_DIRECT_MESSAGES": "允许直接消息",
            
            // Navigation
            "HOME": "首页",
            "LIST": "列表",
            "MESSAGES": "消息",
            "LIST_CURRENCY": "列出货币"
        ],
        "pt": [
            "CANCEL": "Cancelar",
            "SEND": "Enviar",
            "BACK": "Voltar",
            "EDIT": "Editar",
            "DELETE": "Deletar",
            "SAVE": "Salvar",
            "LOADING": "Carregando...",
            "ERROR": "Erro",
            "SUCCESS": "Sucesso",
            "SEARCH": "Pesquisar",
            "OK": "OK",
            "OR": "Ou",
            "SIGN_IN": "Entrar",
            "SIGN_UP": "Inscrever-se",
            "LOGIN": "Login",
            "SIGNUP": "Inscrição",
            "WELCOME_BACK": "Bem-vindo de volta",
            "SIGN_IN_TO_CONTINUE": "Entre para continuar",
            "SIGNING_IN": "Entrando...",
            "DONT_HAVE_ACCOUNT": "Não tem uma conta?",
            "JOIN_NICE_TRADERS": "Junte-se ao Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "Comece a trocar com vizinhos",
            "CREATING_ACCOUNT": "Criando conta...",
            "ALREADY_HAVE_ACCOUNT": "Já tem uma conta?",
            "EMAIL": "Email",
            "PASSWORD": "Senha",
            "FIRST_NAME": "Primeiro Nome",
            "LAST_NAME": "Sobrenome",
            "PHONE_NUMBER": "Número de Telefone",
            "CURRENT_LANGUAGE": "Idioma Atual",
            "SELECT_LANGUAGE": "Selecionar Idioma",
            "LANGUAGE": "Idioma",
            
            // Profile
            "MY_PROFILE": "Meu Perfil",
            "EDIT_PROFILE": "Editar Perfil",
            "SETTINGS": "Configurações",
            "LOGOUT": "Sair",
            "DELETE_ACCOUNT": "Excluir Conta",
            "RATING": "Avaliação",
            "TOTAL_EXCHANGES": "Trocas Totais",
            "SUCCESS_RATE": "Taxa de Sucesso",
            "EXCHANGE_STATS": "Estatísticas de Troca",
            "MEMBER_SINCE": "Membro desde",
            "SAVE_CHANGES": "Salvar Alterações",
            "VIEW_EXCHANGE_HISTORY": "Ver Histórico de Trocas",
            "SEE_ALL_PAST_EXCHANGES": "Ver todas as trocas passadas",
            "CONTACT_INFORMATION": "Informações de Contato",
            "NOTIFICATIONS": "Notificações",
            "PRIVACY": "Privacidade",
            "VIEW_ALL": "Ver Tudo",
            "RECENT_EXCHANGES": "Trocas Recentes",
            "EXCHANGE_HISTORY": "Histórico de Trocas",
            
            // Dashboard
            "LOADING_DASHBOARD": "Carregando seu painel...",
            "ERROR_LOADING_DASHBOARD": "Erro ao Carregar o Painel",
            "RETRY": "Tentar Novamente",
            "WELCOME": "Bem-vindo",
            "EXCHANGES": "trocas",
            "QUICK_ACTIONS": "Ações Rápidas",
            "ALL_ACTIVE_EXCHANGES": "Todas as Trocas Ativas",
            "PRIORITY": "PRIORIDADE",
            "NO_ACTIVE_EXCHANGES": "Ainda não há trocas ativas",
            "NO_ACTIVE_EXCHANGES_YET": "Ainda Não Há Trocas Ativas",
            "BROWSE_LISTINGS_MESSAGE": "Navegue pelos anúncios e compre acesso de contato para começar a trocar moedas",
            "BROWSE_LISTINGS": "Navegar nos Anúncios",
            "MY_ACTIVE_LISTINGS": "Meus Anúncios Ativos",
            "NO_ACTIVE_LISTINGS": "Ainda não há anúncios ativos",
            "CREATE_FIRST_LISTING": "Crie Seu Primeiro Anúncio",
            "ACTIVE": "ATIVO",
            "EDIT_LISTING": "Editar Anúncio",
            
            // Settings Toggles
            "NEW_MESSAGES": "Novas Mensagens",
            "EXCHANGE_UPDATES": "Atualizações de Troca",
            "PUSH_NOTIFICATIONS": "Notificações Push",
            "SHOW_LOCATION": "Mostrar Localização",
            "ALLOW_DIRECT_MESSAGES": "Permitir Mensagens Diretas",
            
            // Navigation
            "HOME": "Início",
            "LIST": "Lista",
            "MESSAGES": "Mensagens",
            "LIST_CURRENCY": "Listar Moeda"
        ],
        "ja": [
            "CANCEL": "キャンセル",
            "SEND": "送信",
            "BACK": "戻る",
            "EDIT": "編集",
            "DELETE": "削除",
            "SAVE": "保存",
            "LOADING": "読み込み中...",
            "ERROR": "エラー",
            "SUCCESS": "成功",
            "SEARCH": "検索",
            "OK": "OK",
            "OR": "または",
            "SIGN_IN": "ログイン",
            "SIGN_UP": "サインアップ",
            "LOGIN": "ログイン",
            "SIGNUP": "登録",
            "WELCOME_BACK": "お帰りなさい",
            "SIGN_IN_TO_CONTINUE": "続行するにはログインしてください",
            "SIGNING_IN": "ログイン中...",
            "DONT_HAVE_ACCOUNT": "アカウントをお持ちですか?",
            "JOIN_NICE_TRADERS": "Nice Tradersに参加",
            "START_EXCHANGING_WITH_NEIGHBORS": "隣人との交換を開始",
            "CREATING_ACCOUNT": "アカウント作成中...",
            "ALREADY_HAVE_ACCOUNT": "すでにアカウントをお持ちですか?",
            "EMAIL": "メール",
            "PASSWORD": "パスワード",
            "FIRST_NAME": "名前",
            "LAST_NAME": "苗字",
            "PHONE_NUMBER": "電話番号",
            "CURRENT_LANGUAGE": "現在の言語",
            "SELECT_LANGUAGE": "言語を選択",
            "LANGUAGE": "言語",
            
            // Profile
            "MY_PROFILE": "マイプロフィール",
            "EDIT_PROFILE": "プロフィールを編集",
            "SETTINGS": "設定",
            "LOGOUT": "ログアウト",
            "DELETE_ACCOUNT": "アカウント削除",
            "RATING": "評価",
            "TOTAL_EXCHANGES": "総交換回数",
            "SUCCESS_RATE": "成功率",
            "EXCHANGE_STATS": "交換統計",
            "MEMBER_SINCE": "メンバー開始日",
            "SAVE_CHANGES": "変更を保存",
            "VIEW_EXCHANGE_HISTORY": "交換履歴を表示",
            "SEE_ALL_PAST_EXCHANGES": "すべての過去の交換を表示",
            "CONTACT_INFORMATION": "連絡先情報",
            "NOTIFICATIONS": "通知",
            "PRIVACY": "プライバシー",
            "VIEW_ALL": "すべて表示",
            "RECENT_EXCHANGES": "最近の交換",
            "EXCHANGE_HISTORY": "交換履歴",
            
            // Dashboard
            "LOADING_DASHBOARD": "ダッシュボードを読み込んでいます...",
            "ERROR_LOADING_DASHBOARD": "ダッシュボードの読み込みエラー",
            "RETRY": "再試行",
            "WELCOME": "ようこそ",
            "EXCHANGES": "回の交換",
            "QUICK_ACTIONS": "クイックアクション",
            "ALL_ACTIVE_EXCHANGES": "すべてのアクティブな交換",
            "PRIORITY": "優先",
            "NO_ACTIVE_EXCHANGES": "まだアクティブな交換はありません",
            "NO_ACTIVE_EXCHANGES_YET": "まだアクティブな交換はありません",
            "BROWSE_LISTINGS_MESSAGE": "リストを閲覧し、連絡先アクセスを購入して通貨交換を開始しましょう",
            "BROWSE_LISTINGS": "リストを閲覧",
            "MY_ACTIVE_LISTINGS": "マイアクティブリスト",
            "NO_ACTIVE_LISTINGS": "まだアクティブなリストはありません",
            "CREATE_FIRST_LISTING": "最初のリストを作成",
            "ACTIVE": "アクティブ",
            "EDIT_LISTING": "リストを編集",
            
            // Settings Toggles
            "NEW_MESSAGES": "新しいメッセージ",
            "EXCHANGE_UPDATES": "交換更新",
            "PUSH_NOTIFICATIONS": "プッシュ通知",
            "SHOW_LOCATION": "位置を表示",
            "ALLOW_DIRECT_MESSAGES": "ダイレクトメッセージを許可",
            
            // Navigation
            "HOME": "ホーム",
            "LIST": "リスト",
            "MESSAGES": "メッセージ",
            "LIST_CURRENCY": "通貨をリスト"
        ],
        "ru": [
            "CANCEL": "Отмена",
            "SEND": "Отправить",
            "BACK": "Назад",
            "EDIT": "Редактировать",
            "DELETE": "Удалить",
            "SAVE": "Сохранить",
            "LOADING": "Загрузка...",
            "ERROR": "Ошибка",
            "SUCCESS": "Успех",
            "SEARCH": "Поиск",
            "OK": "ОК",
            "OR": "Или",
            "SIGN_IN": "Войти",
            "SIGN_UP": "Зарегистрироваться",
            "LOGIN": "Вход",
            "SIGNUP": "Регистрация",
            "WELCOME_BACK": "С возвращением",
            "SIGN_IN_TO_CONTINUE": "Войдите, чтобы продолжить",
            "SIGNING_IN": "Вход...",
            "DONT_HAVE_ACCOUNT": "Нет аккаунта?",
            "JOIN_NICE_TRADERS": "Присоединитесь к Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "Начните обмениваться с соседями",
            "CREATING_ACCOUNT": "Создание аккаунта...",
            "ALREADY_HAVE_ACCOUNT": "Уже есть аккаунт?",
            "EMAIL": "Email",
            "PASSWORD": "Пароль",
            "FIRST_NAME": "Имя",
            "LAST_NAME": "Фамилия",
            "PHONE_NUMBER": "Номер телефона",
            "CURRENT_LANGUAGE": "Текущий язык",
            "SELECT_LANGUAGE": "Выберите язык",
            "LANGUAGE": "Язык",
            
            // Profile
            "MY_PROFILE": "Мой Профиль",
            "EDIT_PROFILE": "Редактировать Профиль",
            "SETTINGS": "Настройки",
            "LOGOUT": "Выйти",
            "DELETE_ACCOUNT": "Удалить Аккаунт",
            "RATING": "Рейтинг",
            "TOTAL_EXCHANGES": "Всего Обменов",
            "SUCCESS_RATE": "Процент Успеха",
            "EXCHANGE_STATS": "Статистика Обменов",
            "MEMBER_SINCE": "Член с",
            "SAVE_CHANGES": "Сохранить Изменения",
            "VIEW_EXCHANGE_HISTORY": "Посмотреть Историю Обменов",
            "SEE_ALL_PAST_EXCHANGES": "Посмотреть все прошлые обмены",
            "CONTACT_INFORMATION": "Контактная Информация",
            "NOTIFICATIONS": "Уведомления",
            "PRIVACY": "Конфиденциальность",
            "VIEW_ALL": "Посмотреть Все",
            "RECENT_EXCHANGES": "Последние Обмены",
            "EXCHANGE_HISTORY": "История Обменов",
            
            // Dashboard
            "LOADING_DASHBOARD": "Загрузка вашей панели...",
            "ERROR_LOADING_DASHBOARD": "Ошибка Загрузки Панели",
            "RETRY": "Повторить",
            "WELCOME": "Добро пожаловать",
            "EXCHANGES": "обменов",
            "QUICK_ACTIONS": "Быстрые Действия",
            "ALL_ACTIVE_EXCHANGES": "Все Активные Обмены",
            "PRIORITY": "ПРИОРИТЕТ",
            "NO_ACTIVE_EXCHANGES": "Пока нет активных обменов",
            "NO_ACTIVE_EXCHANGES_YET": "Пока Нет Активных Обменов",
            "BROWSE_LISTINGS_MESSAGE": "Просмотрите объявления и купите доступ к контактам, чтобы начать обмен валютами",
            "BROWSE_LISTINGS": "Просмотр Объявлений",
            "MY_ACTIVE_LISTINGS": "Мои Активные Объявления",
            "NO_ACTIVE_LISTINGS": "Пока нет активных объявлений",
            "CREATE_FIRST_LISTING": "Создайте Свое Первое Объявление",
            "ACTIVE": "АКТИВНО",
            "EDIT_LISTING": "Редактировать Объявление",
            
            // Settings Toggles
            "NEW_MESSAGES": "Новые Сообщения",
            "EXCHANGE_UPDATES": "Обновления Обменов",
            "PUSH_NOTIFICATIONS": "Пуш-уведомления",
            "SHOW_LOCATION": "Показать Местоположение",
            "ALLOW_DIRECT_MESSAGES": "Разрешить Личные Сообщения",
            
            // Navigation
            "HOME": "Главная",
            "LIST": "Список",
            "MESSAGES": "Сообщения",
            "LIST_CURRENCY": "Список Валют"
        ],
        "ar": [
            "CANCEL": "إلغاء",
            "SEND": "إرسال",
            "BACK": "رجوع",
            "EDIT": "تعديل",
            "DELETE": "حذف",
            "SAVE": "حفظ",
            "LOADING": "جاري التحميل...",
            "ERROR": "خطأ",
            "SUCCESS": "نجح",
            "SEARCH": "بحث",
            "OK": "حسناً",
            "OR": "أو",
            "SIGN_IN": "تسجيل دخول",
            "SIGN_UP": "إنشاء حساب",
            "LOGIN": "دخول",
            "SIGNUP": "تسجيل",
            "WELCOME_BACK": "أهلا وسهلا",
            "SIGN_IN_TO_CONTINUE": "سجل دخولك للمتابعة",
            "SIGNING_IN": "جاري التسجيل...",
            "DONT_HAVE_ACCOUNT": "ليس لديك حساب؟",
            "JOIN_NICE_TRADERS": "انضم إلى Nice Traders",
            "START_EXCHANGING_WITH_NEIGHBORS": "ابدأ بالتبادل مع الجيران",
            "CREATING_ACCOUNT": "جاري إنشاء الحساب...",
            "ALREADY_HAVE_ACCOUNT": "هل لديك حساب بالفعل؟",
            "EMAIL": "بريد إلكتروني",
            "PASSWORD": "كلمة السر",
            "FIRST_NAME": "الاسم الأول",
            "LAST_NAME": "اسم العائلة",
            "PHONE_NUMBER": "رقم الهاتف",
            "CURRENT_LANGUAGE": "اللغة الحالية",
            "SELECT_LANGUAGE": "اختر اللغة",
            "LANGUAGE": "اللغة",
            
            // Profile
            "MY_PROFILE": "ملفي الشخصي",
            "EDIT_PROFILE": "تعديل الملف الشخصي",
            "SETTINGS": "الإعدادات",
            "LOGOUT": "تسجيل خروج",
            "DELETE_ACCOUNT": "حذف الحساب",
            "RATING": "التقييم",
            "TOTAL_EXCHANGES": "إجمالي التبادلات",
            "SUCCESS_RATE": "معدل النجاح",
            "EXCHANGE_STATS": "إحصائيات التبادل",
            "MEMBER_SINCE": "عضو منذ",
            "SAVE_CHANGES": "حفظ التغييرات",
            "VIEW_EXCHANGE_HISTORY": "عرض سجل التبادل",
            "SEE_ALL_PAST_EXCHANGES": "عرض جميع التبادلات السابقة",
            "CONTACT_INFORMATION": "معلومات الاتصال",
            "NOTIFICATIONS": "الإشعارات",
            "PRIVACY": "الخصوصية",
            "VIEW_ALL": "عرض الكل",
            "RECENT_EXCHANGES": "التبادلات الأخيرة",
            "EXCHANGE_HISTORY": "سجل التبادل",
            
            // Dashboard
            "LOADING_DASHBOARD": "جاري تحميل لوحة التحكم...",
            "ERROR_LOADING_DASHBOARD": "خطأ في تحميل لوحة التحكم",
            "RETRY": "إعادة المحاولة",
            "WELCOME": "مرحباً",
            "EXCHANGES": "تبادلات",
            "QUICK_ACTIONS": "إجراءات سريعة",
            "ALL_ACTIVE_EXCHANGES": "جميع التبادلات النشطة",
            "PRIORITY": "أولوية",
            "NO_ACTIVE_EXCHANGES": "لا توجد تبادلات نشطة بعد",
            "NO_ACTIVE_EXCHANGES_YET": "لا توجد تبادلات نشطة بعد",
            "BROWSE_LISTINGS_MESSAGE": "تصفح القوائم واشترِ الوصول إلى جهات الاتصال لبدء تبادل العملات",
            "BROWSE_LISTINGS": "تصفح القوائم",
            "MY_ACTIVE_LISTINGS": "قوائمي النشطة",
            "NO_ACTIVE_LISTINGS": "لا توجد قوائم نشطة بعد",
            "CREATE_FIRST_LISTING": "إنشاء قائمتك الأولى",
            "ACTIVE": "نشط",
            "EDIT_LISTING": "تعديل القائمة",
            
            // Settings Toggles
            "NEW_MESSAGES": "رسائل جديدة",
            "EXCHANGE_UPDATES": "تحديثات التبادل",
            "PUSH_NOTIFICATIONS": "إشعارات فورية",
            "SHOW_LOCATION": "عرض الموقع",
            "ALLOW_DIRECT_MESSAGES": "السماح بالرسائل المباشرة",
            
            // Navigation
            "HOME": "الرئيسية",
            "LIST": "القائمة",
            "MESSAGES": "الرسائل"
        ],
        "hi": [
            "CANCEL": "रद्द करें",
            "SEND": "भेजें",
            "BACK": "वापस",
            "EDIT": "संपादित करें",
            "DELETE": "हटाएं",
            "SAVE": "सहेजें",
            "LOADING": "लोड हो रहा है...",
            "ERROR": "त्रुटि",
            "SUCCESS": "सफलता",
            "SEARCH": "खोज",
            "OK": "ठीक है",
            "OR": "या",
            "SIGN_IN": "साइन इन करें",
            "SIGN_UP": "साइन अप करें",
            "LOGIN": "लॉगिन",
            "SIGNUP": "पंजीकरण",
            "WELCOME_BACK": "वापसी पर स्वागत है",
            "SIGN_IN_TO_CONTINUE": "जारी रखने के लिए साइन इन करें",
            "SIGNING_IN": "साइन इन हो रहा है...",
            "DONT_HAVE_ACCOUNT": "खाता नहीं है?",
            "JOIN_NICE_TRADERS": "Nice Traders में शामिल हों",
            "START_EXCHANGING_WITH_NEIGHBORS": "पड़ोसियों के साथ विनिमय शुरू करें",
            "CREATING_ACCOUNT": "खाता बना रहे हैं...",
            "ALREADY_HAVE_ACCOUNT": "पहले से खाता है?",
            "EMAIL": "ईमेल",
            "PASSWORD": "पासवर्ड",
            "FIRST_NAME": "पहला नाम",
            "LAST_NAME": "अंतिम नाम",
            "PHONE_NUMBER": "फोन नंबर",
            "CURRENT_LANGUAGE": "वर्तमान भाषा",
            "SELECT_LANGUAGE": "भाषा चुनें",
            "LANGUAGE": "भाषा",
            
            // Profile
            "MY_PROFILE": "मेरी प्रोफाइल",
            "EDIT_PROFILE": "प्रोफाइल संपादित करें",
            "SETTINGS": "सेटिंग्स",
            "LOGOUT": "लॉगआउट",
            "DELETE_ACCOUNT": "खाता हटाएं",
            "RATING": "रेटिंग",
            "TOTAL_EXCHANGES": "कुल विनिमय",
            "SUCCESS_RATE": "सफलता दर",
            "EXCHANGE_STATS": "विनिमय आंकड़े",
            "MEMBER_SINCE": "सदस्य से",
            "SAVE_CHANGES": "परिवर्तन सहेजें",
            "VIEW_EXCHANGE_HISTORY": "विनिमय इतिहास देखें",
            "SEE_ALL_PAST_EXCHANGES": "सभी पिछले विनिमय देखें",
            "CONTACT_INFORMATION": "संपर्क जानकारी",
            "NOTIFICATIONS": "सूचनाएं",
            "PRIVACY": "गोपनीयता",
            "VIEW_ALL": "सभी देखें",
            "RECENT_EXCHANGES": "हाल के विनिमय",
            "EXCHANGE_HISTORY": "विनिय इतिहास",
            
            // Dashboard
            "LOADING_DASHBOARD": "आपका डैशबोर्ड लोड हो रहा है...",
            "ERROR_LOADING_DASHBOARD": "डैशबोर्ड लोड करने में त्रुटि",
            "RETRY": "पुनः प्रयास करें",
            "WELCOME": "स्वागत है",
            "EXCHANGES": "विनिमय",
            "QUICK_ACTIONS": "त्वरित क्रियाएं",
            "ALL_ACTIVE_EXCHANGES": "सभी सक्रिय विनिमय",
            "PRIORITY": "प्राथमिकता",
            "NO_ACTIVE_EXCHANGES": "अभी तक कोई सक्रिय विनिमय नहीं",
            "NO_ACTIVE_EXCHANGES_YET": "अभी तक कोई सक्रिय विनिमय नहीं",
            "BROWSE_LISTINGS_MESSAGE": "मुद्राओं का आदान-प्रदान शुरू करने के लिए सूचियां ब्राउज़ करें और संपर्क पहुंच खरीदें",
            "BROWSE_LISTINGS": "सूचियां ब्राउज़ करें",
            "MY_ACTIVE_LISTINGS": "मेरी सक्रिय सूचियां",
            "NO_ACTIVE_LISTINGS": "अभी तक कोई सक्रिय सूचियां नहीं",
            "CREATE_FIRST_LISTING": "अपनी पहली सूची बनाएं",
            "ACTIVE": "सक्रिय",
            "EDIT_LISTING": "सूची संपादित करें",
            
            // Settings Toggles
            "NEW_MESSAGES": "नए संदेश",
            "EXCHANGE_UPDATES": "विनिमय अपडेट",
            "PUSH_NOTIFICATIONS": "पुश सूचनाएं",
            "SHOW_LOCATION": "स्थान दिखाएं",
            "ALLOW_DIRECT_MESSAGES": "सीधे संदेश की अनुमति दें",
            
            // Navigation
            "HOME": "होम",
            "LIST": "सूची",
            "MESSAGES": "संदेश",
            "LIST_CURRENCY": "मुद्रा सूचीबद्ध करें"
        ]
    ]
    
    func localize(_ key: String) -> String {
        // Use languageVersion in logic to create dependency for SwiftUI
        let selectedLanguage = languageVersion > -1 ? currentLanguage : "en"
        
        // Try to get translation for selected language
        if let languageDict = translations[selectedLanguage],
           let translated = languageDict[key] {
            return translated
        }
        
        // Fallback to English
        if let englishDict = translations["en"],
           let translated = englishDict[key] {
            return translated
        }
        
        // Last resort: return the key itself
        return key
    }
    
    // MARK: - Currency Formatting
    
    func formatCurrency(amount: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: currentLanguage)
        
        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return formatted
        }
        return "\(currency) \(amount)"
    }
    
    // MARK: - Date Formatting
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatDateTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Number Formatting
    
    func formatNumber(number: Double, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        
        if let formatted = formatter.string(from: NSNumber(value: number)) {
            return formatted
        }
        return "\(number)"
    }
    
    // MARK: - Text Direction
    
    func isRightToLeft() -> Bool {
        return currentLanguage == "ar"
    }
    
    // MARK: - Common Translations
    
    var cancel: String { localize("CANCEL") }
    var send: String { localize("SEND") }
    var back: String { localize("BACK") }
    var edit: String { localize("EDIT") }
    var delete: String { localize("DELETE") }
    var save: String { localize("SAVE") }
    var loading: String { localize("LOADING") }
    var error: String { localize("ERROR") }
    var success: String { localize("SUCCESS") }
    var search: String { localize("SEARCH") }
    var filter: String { localize("FILTER") }
    var sort: String { localize("SORT") }
    var noResults: String { localize("NO_RESULTS") }
    var confirmation: String { localize("CONFIRMATION") }
    
    // Auth strings
    var signIn: String { localize("SIGN_IN") }
    var signUp: String { localize("SIGN_UP") }
    var email: String { localize("EMAIL") }
    var password: String { localize("PASSWORD") }
    var confirmPassword: String { localize("CONFIRM_PASSWORD") }
    var firstName: String { localize("FIRST_NAME") }
    var lastName: String { localize("LAST_NAME") }
    var forgotPassword: String { localize("FORGOT_PASSWORD") }
    var invalidEmail: String { localize("INVALID_EMAIL") }
    var passwordMismatch: String { localize("PASSWORD_MISMATCH") }
    
    // Listing strings
    var createListing: String { localize("CREATE_LISTING") }
    var editListing: String { localize("EDIT_LISTING") }
    var myListings: String { localize("MY_LISTINGS") }
    var listingDetails: String { localize("LISTING_DETAILS") }
    var amount: String { localize("AMOUNT") }
    var currency: String { localize("CURRENCY") }
    var location: String { localize("LOCATION") }
    var listingDescription: String { localize("DESCRIPTION") }
    var noListings: String { localize("NO_LISTINGS") }
    
    // Contact/Payment strings
    var paymentReceived: String { localize("PAYMENT_RECEIVED") }
    var purchaseContact: String { localize("PURCHASE_CONTACT") }
    var sendMessage: String { localize("SEND_MESSAGE") }
    var newMessage: String { localize("NEW_MESSAGE") }
    
    // Meeting strings
    var meetingProposed: String { localize("MEETING_PROPOSED") }
    var proposeMeeting: String { localize("PROPOSE_MEETING") }
    var meetingTime: String { localize("MEETING_TIME") }
    var meetingLocation: String { localize("MEETING_LOCATION") }
    var acceptMeeting: String { localize("ACCEPT_MEETING") }
    var declineMeeting: String { localize("DECLINE_MEETING") }
    
    // Profile strings
    var myProfile: String { localize("MY_PROFILE") }
    var editProfile: String { localize("EDIT_PROFILE") }
    var settings: String { localize("SETTINGS") }
    var language: String { localize("LANGUAGE") }
    var logout: String { localize("LOGOUT") }
    var deleteAccount: String { localize("DELETE_ACCOUNT") }
    var rating: String { localize("RATING") }
    var totalExchanges: String { localize("TOTAL_EXCHANGES") }
    
    // Dashboard strings
    var dashboard: String { localize("DASHBOARD") }
    var purchasedContacts: String { localize("PURCHASED_CONTACTS") }
    var recentExchanges: String { localize("RECENT_EXCHANGES") }
    var exchangeHistory: String { localize("EXCHANGE_HISTORY") }
    
    // Search strings
    var searchListings: String { localize("SEARCH_LISTINGS") }
    var buyingLooking: String { localize("BUYING_LOOKING_FOR") }
    var sellingHave: String { localize("SELLING_HAVE") }
    var fromCurrency: String { localize("FROM_CURRENCY") }
    var toCurrency: String { localize("TO_CURRENCY") }
}

// Extension for easier access in SwiftUI views
extension String {
    static func localize(_ key: String) -> String {
        return LocalizationManager.shared.localize(key)
    }
}
