//
//  LocalizationManager.swift
//  Nice Traders
//
//  Handles all localization and internationalization for the app
//

import Foundation
import CoreLocation
import Combine

class LocalizationManager: NSObject, ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            languageVersion += 1
        }
    }
    
    @Published var languageVersion: Int = 0  // Increment this to force view updates
    
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
    }
    
    // MARK: - Language Detection from GPS
    
    /// Detect user's language based on their current GPS location
    /// Falls back to system locale if GPS access is unavailable
    func initializeLanguageFromLocation(_ locationManager: CLLocationManager) {
        // If we already have a saved preference, use it
        if UserDefaults.standard.string(forKey: "AppLanguage") != nil {
            return
        }
        
        // Try to detect from GPS location
        if let currentLocation = locationManager.location {
            LocationLanguageDetector.detectLanguageFromLocation(currentLocation) { [weak self] detectedLanguage in
                DispatchQueue.main.async {
                    // Save the detected language
                    UserDefaults.standard.set(detectedLanguage, forKey: "AppLanguage")
                    self?.currentLanguage = detectedLanguage
                }
            }
        }
    }
    
    // MARK: - Backend Synchronization
    
    private func saveLanguagePreferenceToBackend(languageCode: String, userId: String) {
        let backendURL = URLComponents(string: "http://localhost:5000/api/profile/update")?.url ?? URL(fileURLWithPath: "")
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "user_id": userId,
            "preferred_language": languageCode
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error saving language preference: \(error.localizedDescription)")
                }
            }.resume()
        } catch {
            print("Error encoding language preference: \(error.localizedDescription)")
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
            
            // Dashboard
            "DASHBOARD": "Dashboard",
            "PURCHASED_CONTACTS": "Purchased Contacts",
            "RECENT_EXCHANGES": "Recent Exchanges",
            "EXCHANGE_HISTORY": "Exchange History",
            
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
            "PASSWORD_MIN_LENGTH": "La contraseña debe tener al menos 6 caracteres"
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
            "CONFIRM_PASSWORD_PLACEHOLDER": "Confirmez le mot de passe"
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
            "PHONE_NUMBER": "Telefon"
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
            "PHONE_NUMBER": "Telefón"
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
