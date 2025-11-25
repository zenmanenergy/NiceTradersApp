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
            objectWillChange.send()
            // Also save to backend via SessionManager if user is authenticated
            if let userId = SessionManager.shared.userId {
                self.saveLanguagePreferenceToBackend(languageCode: currentLanguage, userId: userId)
            }
        }
    }
    
    @Published var languageVersion: Int = 0
    
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
    
    // Translation dictionary
    private let translations: [String: [String: String]] = [
        "en": [
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
            "CURRENT_LANGUAGE": "Current Language",
            "SELECT_LANGUAGE": "Select Language",
            "LANGUAGE": "Language",
            
            // Auth
            "WELCOME_BACK": "Welcome Back",
            "SIGN_IN": "Sign In",
            "SIGN_UP": "Sign Up",
            "SIGN_IN_TO_CONTINUE": "Sign in to your account to continue",
            "EMAIL": "Email",
            "PASSWORD": "Password",
            "CONFIRM_PASSWORD": "Confirm Password",
            "FIRST_NAME": "First Name",
            "LAST_NAME": "Last Name",
            "FORGOT_PASSWORD": "Forgot Password?",
            "INVALID_EMAIL": "Invalid Email",
            "PASSWORD_MISMATCH": "Passwords do not match",
            
            // Listing
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
            "FILTER": "Filtro",
            "SORT": "Ordenar",
            "NO_RESULTS": "Sin resultados",
            "CONFIRMATION": "Confirmación",
            "CURRENT_LANGUAGE": "Idioma Actual",
            "SELECT_LANGUAGE": "Seleccionar Idioma",
            "LANGUAGE": "Idioma",
            
            "WELCOME_BACK": "Bienvenido de vuelta",
            "SIGN_IN": "Iniciar sesión",
            "SIGN_UP": "Registrarse",
            "SIGN_IN_TO_CONTINUE": "Inicia sesión en tu cuenta para continuar",
            "EMAIL": "Correo electrónico",
            "PASSWORD": "Contraseña",
            "CONFIRM_PASSWORD": "Confirmar contraseña",
            "FIRST_NAME": "Nombre",
            "LAST_NAME": "Apellido",
            "FORGOT_PASSWORD": "¿Olvidó su contraseña?",
            "INVALID_EMAIL": "Correo inválido",
            "PASSWORD_MISMATCH": "Las contraseñas no coinciden"
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
            "FILTER": "Filtre",
            "SORT": "Trier",
            "NO_RESULTS": "Aucun résultat",
            "CONFIRMATION": "Confirmation",
            "CURRENT_LANGUAGE": "Langue actuelle",
            "SELECT_LANGUAGE": "Sélectionner la langue",
            "LANGUAGE": "Langue",
            
            "WELCOME_BACK": "Bienvenue",
            "SIGN_IN": "Connexion",
            "SIGN_UP": "S'inscrire",
            "SIGN_IN_TO_CONTINUE": "Connectez-vous à votre compte pour continuer",
            "EMAIL": "Email",
            "PASSWORD": "Mot de passe",
            "CONFIRM_PASSWORD": "Confirmer le mot de passe",
            "FIRST_NAME": "Prénom",
            "LAST_NAME": "Nom",
            "FORGOT_PASSWORD": "Mot de passe oublié ?",
            "INVALID_EMAIL": "Email invalide",
            "PASSWORD_MISMATCH": "Les mots de passe ne correspondent pas"
        ],
        "de": [
            "CANCEL": "Abbrechen",
            "SEND": "Senden",
            "BACK": "Zurück",
            "EDIT": "Bearbeiten",
            "DELETE": "Löschen",
            "SAVE": "Speichern",
            "LOADING": "Wird geladen...",
            "ERROR": "Fehler",
            "SUCCESS": "Erfolg",
            "SEARCH": "Suche",
            "FILTER": "Filter",
            "SORT": "Sortieren",
            "NO_RESULTS": "Keine Ergebnisse",
            "CONFIRMATION": "Bestätigung",
            "CURRENT_LANGUAGE": "Aktuelle Sprache",
            "SELECT_LANGUAGE": "Sprache wählen",
            "LANGUAGE": "Sprache",
            
            "WELCOME_BACK": "Willkommen zurück",
            "SIGN_IN": "Anmelden",
            "SIGN_UP": "Registrieren",
            "SIGN_IN_TO_CONTINUE": "Melden Sie sich an, um fortzufahren",
            "EMAIL": "E-Mail",
            "PASSWORD": "Passwort",
            "CONFIRM_PASSWORD": "Passwort bestätigen",
            "FIRST_NAME": "Vorname",
            "LAST_NAME": "Nachname",
            "FORGOT_PASSWORD": "Passwort vergessen?",
            "INVALID_EMAIL": "Ungültige E-Mail",
            "PASSWORD_MISMATCH": "Passwörter stimmen nicht überein"
        ],
        "sk": [
            "CANCEL": "Zrušiť",
            "SEND": "Poslať",
            "BACK": "Späť",
            "EDIT": "Upraviť",
            "DELETE": "Odstrániť",
            "SAVE": "Uložiť",
            "LOADING": "Načítavanie...",
            "ERROR": "Chyba",
            "SUCCESS": "Úspech",
            "SEARCH": "Hľadať",
            "FILTER": "Filter",
            "SORT": "Zoradiť",
            "NO_RESULTS": "Žiadne výsledky",
            "CONFIRMATION": "Potvrdenie",
            "CURRENT_LANGUAGE": "Aktuálny jazyk",
            "SELECT_LANGUAGE": "Vybrať jazyk",
            "LANGUAGE": "Jazyk",
            
            "WELCOME_BACK": "Vitajte späť",
            "SIGN_IN": "Prihlásiť sa",
            "SIGN_UP": "Zaregistrujte sa",
            "SIGN_IN_TO_CONTINUE": "Prihláste sa do svojho konta",
            "EMAIL": "E-mail",
            "PASSWORD": "Heslo",
            "CONFIRM_PASSWORD": "Potvrdiť heslo",
            "FIRST_NAME": "Meno",
            "LAST_NAME": "Priezvisko",
            "FORGOT_PASSWORD": "Zabudli ste heslo?",
            "INVALID_EMAIL": "Neplatný e-mail",
            "PASSWORD_MISMATCH": "Heslá sa nezhodujú"
        ]
    ]
    
    private init() {
        // Try to load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguage = savedLanguage
        } else {
            // Auto-detect from system locale first
            let systemLocale = Locale.preferredLanguages.first ?? "en"
            let languageCode = String(systemLocale.prefix(2))
            self.currentLanguage = supportedLanguages[languageCode] != nil ? languageCode : "en"
        }
        super.init()
    }
    
    // MARK: - Localization
    
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
    
    // MARK: - Currency Formatting
    
    func formatCurrency(_ amount: Double, currency: String) -> String {
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
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: currentLanguage)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Number Formatting
    
    func formatNumber(_ number: Double, minimumFractionDigits: Int = 0, maximumFractionDigits: Int = 2) -> String {
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
    var description: String { localize("DESCRIPTION") }
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
