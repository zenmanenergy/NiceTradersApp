//
//  LocalizationManager.swift
//  Nice Traders
//
//  Handles all localization and internationalization for the app
//  Uses API-based translations from backend with smart caching
//

import Foundation
import CoreLocation
import Combine

class LocalizationManager: NSObject, ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            print("🔴 [LocalizationManager] currentLanguage changed: '\(oldValue)' → '\(currentLanguage)'")
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            print("🔴 [LocalizationManager] Saved to UserDefaults: \(currentLanguage)")
            languageVersion += 1
            print("🔴 [LocalizationManager] languageVersion incremented to: \(languageVersion)")
            objectWillChange.send()
            
            // Download translations for new language
            Task {
                await downloadTranslations(language: currentLanguage)
            }
            
            // Also save to backend via SessionManager if user is authenticated
            if let userId = SessionManager.shared.userId {
                self.saveLanguagePreferenceToBackend(languageCode: currentLanguage, userId: userId)
            }
        }
    }
    
    @Published var languageVersion: Int = 0
    
    static let shared = LocalizationManager()
    
    // In-memory cache of translations
    private var cachedTranslations: [String: String] = [:]
    
    // Fallback hardcoded translations for when API is unavailable
    private let fallbackTranslations: [String: [String: String]] = [
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
        ]
    ]
    
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
    
    private let baseURL = "http://localhost:5000"
    
    private init() {
        super.init()
        
        print("🟠 [LocalizationManager] Initializing...")
        
        // Try to load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            print("🟠 [LocalizationManager] Found saved language in UserDefaults: \(savedLanguage)")
            self.currentLanguage = savedLanguage
        } else {
            print("🟠 [LocalizationManager] No saved language, auto-detecting...")
            // Auto-detect from system locale first
            let systemLocale = Locale.preferredLanguages.first ?? "en"
            let languageCode = String(systemLocale.prefix(2))
            self.currentLanguage = supportedLanguages[languageCode] != nil ? languageCode : "en"
            print("🟠 [LocalizationManager] Auto-detected language: \(self.currentLanguage)")
        }
        
        print("🟠 [LocalizationManager] Initialized with language: \(self.currentLanguage), version: \(self.languageVersion)")
        
        // Load cached translations and check for updates
        Task {
            // First load from cache
            if let cached = loadFromCache(language: self.currentLanguage) {
                self.cachedTranslations = cached
                print("📦 [LocalizationManager] Loaded \(cached.count) cached translations")
            }
            
            // Then check for server updates in background
            await checkForUpdates(language: self.currentLanguage)
            
            // If user is logged in, load their preferred language from backend
            if SessionManager.shared.isLoggedIn {
                await loadUserPreferredLanguageFromBackend()
            }
        }
    }
    
    // MARK: - Localization
    
    func localize(_ key: String) -> String {
        // Use languageVersion in logic to create dependency for SwiftUI
        let selectedLanguage = languageVersion > -1 ? currentLanguage : "en"
        
        // Try cached translations first
        if let translated = cachedTranslations[key] {
            return translated
        }
        
        // Fallback to hardcoded translations
        if let languageDict = fallbackTranslations[selectedLanguage],
           let translated = languageDict[key] {
            return translated
        }
        
        if let englishDict = fallbackTranslations["en"],
           let translated = englishDict[key] {
            return translated
        }
        
        // Last resort: return the key itself
        return key
    }
    
    // MARK: - Server Communication
    
    /// Download translations for a specific language from the API
    private func downloadTranslations(language: String) async {
        let endpoint = "\(baseURL)/Translations/GetTranslations"
        guard let url = URL(string: "\(endpoint)?language=\(language)") else {
            print("⚠️ [LocalizationManager] Invalid URL: \(endpoint)")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TranslationsResponse.self, from: data)
            
            if response.success {
                self.cachedTranslations = response.translations
                self.saveToCache(translations: response.translations, 
                               language: language, 
                               timestamp: response.last_updated)
                print("✅ [LocalizationManager] Downloaded \(response.count) translations for \(language)")
                DispatchQueue.main.async {
                    self.languageVersion += 1
                }
            } else {
                print("⚠️ [LocalizationManager] Server returned error for language: \(language)")
            }
        } catch {
            print("⚠️ [LocalizationManager] Error downloading translations: \(error.localizedDescription)")
        }
    }
    
    /// Check if translations on server are newer than cached version
    private func checkForUpdates(language: String) async {
        let endpoint = "\(baseURL)/Translations/GetLastUpdated"
        guard let url = URL(string: endpoint) else {
            print("⚠️ [LocalizationManager] Invalid URL: \(endpoint)")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LastUpdatedResponse.self, from: data)
            
            if response.success,
               let serverTimestamp = response.last_updated[language],
               let cachedTimestamp = getCachedTimestamp(language: language) {
                
                // If server is newer, download updates
                if serverTimestamp > cachedTimestamp {
                    print("🔄 [LocalizationManager] Translations are outdated, downloading new version")
                    await downloadTranslations(language: language)
                }
            } else if response.success && getCachedTimestamp(language: language) == nil {
                // No cached version, download from server
                await downloadTranslations(language: language)
            }
        } catch {
            print("⚠️ [LocalizationManager] Error checking translation updates: \(error.localizedDescription)")
        }
    }
    
    /// Load language preference from backend (backward compatibility)
    func loadLanguageFromBackend() {
        // This is now handled automatically during initialization
        // Check for updates in background
        Task {
            await checkForUpdates(language: self.currentLanguage)
        }
    }
    
    /// Load user's preferred language from backend database
    /// Called during initialization if user is logged in
    private func loadUserPreferredLanguageFromBackend() async {
        guard let userId = SessionManager.shared.userId else {
            print("⚠️ [LocalizationManager] User not logged in, skipping backend language load")
            return
        }
        
        let endpoint = "\(baseURL)/Profile/GetUserProfile"
        guard let url = URL(string: "\(endpoint)?user_id=\(userId)") else {
            print("⚠️ [LocalizationManager] Invalid URL for profile endpoint")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(UserProfileResponse.self, from: data)
            
            if response.success, let preferredLanguage = response.preferred_language {
                // Only update if it's different from current and is a supported language
                if supportedLanguages[preferredLanguage] != nil && preferredLanguage != self.currentLanguage {
                    print("📥 [LocalizationManager] Loaded preferred language from backend: \(preferredLanguage)")
                    DispatchQueue.main.async {
                        self.currentLanguage = preferredLanguage
                    }
                }
            }
        } catch {
            print("⚠️ [LocalizationManager] Error loading preferred language from backend: \(error.localizedDescription)")
            // Continue with current language if backend fails
        }
    }
    
    // MARK: - Caching
    
    private func saveToCache(translations: [String: String], 
                            language: String, 
                            timestamp: String?) {
        let key = "translations_\(language)"
        let timestampKey = "translations_\(language)_timestamp"
        
        UserDefaults.standard.setValue(translations, forKey: key)
        if let timestamp = timestamp {
            UserDefaults.standard.setValue(timestamp, forKey: timestampKey)
        }
        print("📦 [LocalizationManager] Cached \(translations.count) translations for \(language)")
    }
    
    private func loadFromCache(language: String) -> [String: String]? {
        let key = "translations_\(language)"
        let cached = UserDefaults.standard.dictionary(forKey: key) as? [String: String]
        if cached != nil {
            print("📥 [LocalizationManager] Loaded cached translations for \(language)")
        }
        return cached
    }
    
    private func getCachedTimestamp(language: String) -> String? {
        let key = "translations_\(language)_timestamp"
        return UserDefaults.standard.string(forKey: key)
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

// MARK: - API Data Structures

struct TranslationsResponse: Codable {
    let success: Bool
    let language: String
    let translations: [String: String]
    let last_updated: String
    let count: Int
}

struct LastUpdatedResponse: Codable {
    let success: Bool
    let last_updated: [String: String]
}

struct UserProfileResponse: Codable {
    let success: Bool
    let preferred_language: String?
    
    // Flexible decoding to handle different API response formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        
        // Try to decode preferred_language from various possible field names
        if let lang = try container.decodeIfPresent(String.self, forKey: .preferred_language) {
            preferred_language = lang
        } else if let lang = try container.decodeIfPresent(String.self, forKey: .preferredLanguage) {
            preferred_language = lang
        } else {
            preferred_language = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encodeIfPresent(preferred_language, forKey: .preferred_language)
    }
    
    enum CodingKeys: String, CodingKey {
        case success
        case preferred_language
        case preferredLanguage
    }
}

// Extension for easier access in SwiftUI views
extension String {
    static func localize(_ key: String) -> String {
        return LocalizationManager.shared.localize(key)
    }
}
