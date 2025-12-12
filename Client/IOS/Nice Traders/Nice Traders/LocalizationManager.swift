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
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
            UserDefaults.standard.synchronize()
            languageVersion += 1
            objectWillChange.send()
            
            // Switch to the new language immediately from cached data
            if let allCached = loadAllTranslationsFromCache(),
               let languageTranslations = allCached[currentLanguage] {
                self.cachedTranslations = languageTranslations
            } else {
                self.cachedTranslations = [:]
            }
            
            // Save language preference to backend
            self.saveLanguagePreferenceToBackend(languageCode: currentLanguage)
        }
    }
    
    @Published var languageVersion: Int = 0
    
    static let shared = LocalizationManager()
    
    // In-memory cache of translations for current language
    private var cachedTranslations: [String: String] = [:]
    
    // Fallback hardcoded translations - MINIMAL, only for bootstrap
    // All translations should come from the database API
    private let fallbackTranslations: [String: [String: String]] = [
        "en": [
            "LOADING": "Loading...",
            "ERROR": "Error",
            "CANCEL": "Cancel",
            // ContentView temporary fallback
            "NICE_TRADERS_HEADER": "NICE Traders",
            "NEIGHBORHOOD_CURRENCY_EXCHANGE": "Neighborhood International Currency Exchange",
            "EXCHANGE_CURRENCY_LOCALLY": "Exchange Currency Locally",
            "LANDING_PAGE_DESCRIPTION": "Connect with neighbors to exchange foreign currency safely and affordably. Skip the expensive fees and get the cash you need from your community.",
            "FIND_NEARBY": "Find Nearby",
            "FIND_NEARBY_DESC": "See currency exchanges happening in your neighborhood",
            "BETTER_RATES": "Better Rates",
            "BETTER_RATES_DESC": "Avoid high bank and airport exchange fees",
            "SAFE_EXCHANGES": "Safe Exchanges",
            "SAFE_EXCHANGES_DESC": "Meet in public places with user ratings for safety",
            "GET_STARTED": "Get Started",
            "LEARN_MORE": "Learn More",
            "LANDING_FOOTER": "Join thousands of travelers saving money on currency exchange",
            "ALREADY_HAVE_ACCOUNT": "Already have an account?",
            "SIGN_IN": "Sign In",
            "CHECKING_SESSION": "Checking session...",
            // High-priority UI labels
            "EXCHANGE_RATES": "Exchange Rates",
            "CURRENCY_CONVERTER": "Currency Converter",
            "AMOUNT": "Amount",
            "FROM": "From",
            "TO": "To",
            "CONVERT": "Convert",
            "RESULT": "Result",
            "CURRENT_RATES": "Current Rates",
            "NO_RATES_AVAILABLE": "No rates available",
            "TAP_REFRESH_RATES": "Tap refresh to load exchange rates",
            "SEARCH_CURRENCY": "Search Currency",
            "SELECT_CURRENCY": "Select currency",
            "TRY_ADJUSTING_SEARCH": "Try adjusting your search or check back later for new listings.",
            "MEETING_LABEL": "Meeting:",
            "AVAILABLE_UNTIL": "Available until:",
            "CONTACT_TRADER": "Contact Trader",
            "EXCHANGE_DETAILS": "Exchange Details",
            "TRADER_INFORMATION": "Trader Information",
            "MEETING_LOCATION": "Meeting Location *",
            "DATE": "Date *",
            "TIME": "Time *",
            "OPTIONAL_MESSAGE": "Optional Message",
            "SEND_PROPOSAL": "Send Proposal",
            "MEETING_PROPOSALS": "Meeting Proposals",
            "MEMBER_SINCE": "Member since",
            "APPROXIMATE_AREA": "Approximate area - exact location shared after purchase",
            "EXACT_LOCATION": "Exact location - meeting time confirmed",
            // LoginView
            "WELCOME_BACK": "Welcome Back",
            "SIGN_IN_TO_CONTINUE": "Sign in to continue",
            "EMAIL": "Email",
            "ENTER_EMAIL": "Enter email",
            "PASSWORD": "Password",
            "ENTER_PASSWORD": "Enter password",
            "FORGOT_PASSWORD": "Forgot Password?",
            "FORGOT_PASSWORD_COMING_SOON": "Password recovery is coming soon!",
            "SIGNING_IN": "Signing in...",
            "DONT_HAVE_ACCOUNT": "Don't have an account?",
            "SIGN_UP": "Sign Up",
            "LOGIN": "Login",
            "OK": "OK",
            "EMAIL_REQUIRED": "Email is required",
            "INVALID_EMAIL": "Invalid email address",
            "PASSWORD_REQUIRED": "Password is required",
            "INVALID_URL": "Invalid URL",
            "NETWORK_ERROR": "Network error",
            "NO_DATA_RECEIVED": "No data received",
            "INVALID_LOGIN_CREDENTIALS": "Invalid email or password",
            "FAILED_PARSE_RESPONSE": "Failed to parse response",
            "WILLING_TO_ROUND_TO_NEAREST_DOLLAR": "Willing to round to the nearest dollar?",
            "EXAMPLE_ROUNDING": "e.g., 10.47 USD → 10 USD",
            "PROPOSE_LOCATION": "Propose Location",
            "CONFIRM_LOCATION_PROPOSAL": "Confirm Location Proposal",
            "PROPOSED_LOCATION": "Proposed Location",
            "ACCEPT_LOCATION": "Accept Location",
            "REJECT_LOCATION": "Reject Location",
            "COUNTER_PROPOSE_LOCATION": "Counter Propose Location",
            "LOCATION_PROPOSED": "Location Proposed",
            "AWAITING_LOCATION_RESPONSE": "Awaiting Location Response",
            "WAITING_FOR_LOCATION_ACCEPTANCE": "Waiting for location acceptance",
            "LOCATION_ACCEPTED": "Location Accepted",
            "PROPOSED_BY": "Proposed by",
            "MESSAGE": "Message",
        ]
    ]
    
    @Published var supportedLanguages: [String: String] = [:]
    
    private let baseURL: String = Settings.shared.baseURL
    
    private override init() {
        // Initialize before super.init()
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
        
        
        // Load all cached translations and check for updates
        Task {
            // First, load supported languages from backend
            await self.loadSupportedLanguages()
            
            // Load all translations from cache
            if let allCached = self.loadAllTranslationsFromCache(),
               let languageTranslations = allCached[self.currentLanguage] {
                self.cachedTranslations = languageTranslations
            }
            
            // Check if we need to download updates
            await self.checkForUpdates()
            
            // If user is logged in, load their preferred language from backend
            await self.loadUserPreferredLanguageFromBackend()
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
    
    /// Download ALL translations for ALL languages from the API (single call)
    private func downloadAllTranslations() async {
        let endpoint = "\(baseURL)/Translations/GetAllTranslations"
        guard let url = URL(string: endpoint) else {
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10.0  // 10 second timeout for larger payload
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AllTranslationsResponse.self, from: data)
            
            if response.success {
                // Save all translations to cache (both file and UserDefaults)
                self.saveAllTranslationsToCache(
                    translations: response.translations,
                    timestamp: response.last_updated
                )
                
                // Update current language's in-memory cache
                if let currentLangTranslations = response.translations[self.currentLanguage] {
                    self.cachedTranslations = currentLangTranslations
                    
                    // Trigger UI update
                    Task { @MainActor in
                        self.languageVersion += 1
                    }
                } else {
                }
            } else {
            }
        } catch let error as NSError {
            // Network errors are expected when offline
            if error.domain == NSURLErrorDomain {
            } else {
            }
        } catch {
        }
    }
    
    /// Check if translations on server are newer than cached version
    private func checkForUpdates() async {
        let endpoint = "\(baseURL)/Translations/GetLastUpdated"
        guard let url = URL(string: endpoint) else {
            return
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0  // 5 second timeout
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(LastUpdatedResponse.self, from: data)
            
            guard response.success else {
                return
            }
            
            // Get the max timestamp from server (across all languages)
            let serverTimestamps = response.last_updated.values
            guard let maxServerTimestamp = serverTimestamps.max() else {
                return
            }
            
            let cachedTimestamp = getGlobalCachedTimestamp()
            
            // Always download if no cache exists
            if cachedTimestamp == nil {
                await downloadAllTranslations()
            } 
            // If server timestamp is newer, download updates
            else if maxServerTimestamp > cachedTimestamp! {
                await downloadAllTranslations()
            } else {
            }
        } catch let error as NSError {
            // Network errors are expected when offline - silently continue with cached data
            if error.domain == NSURLErrorDomain {
            } else {
            }
        } catch {
        }
    }
    
    /// Load language preference from backend (backward compatibility)
    func loadLanguageFromBackend() {
        // This is now handled automatically during initialization
        // Check for updates in background
        Task {
            await checkForUpdates()
        }
    }
    
    /// Load user's preferred language from backend database
    /// Called during initialization if user is logged in
    private func loadUserPreferredLanguageFromBackend() async {
        // Check if user is logged in (get sessionId from UserDefaults)
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            return
        }
        
        let endpoint = "\(baseURL)/Profile/GetProfile"
        guard let url = URL(string: "\(endpoint)?SessionId=\(sessionId)") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            if let profileData = jsonResponse["profile"] as? [String: Any],
               let preferredLanguage = profileData["preferred_language"] as? String,
               !preferredLanguage.isEmpty {
                
                if supportedLanguages[preferredLanguage] != nil && preferredLanguage != self.currentLanguage {
                    Task { @MainActor in
                        self.currentLanguage = preferredLanguage
                        UserDefaults.standard.set(preferredLanguage, forKey: "AppLanguage")
                    }
                }
            }
        } catch {
        }
    }
    
    // MARK: - Caching
    
    /// Get the file path for storing translations in Documents directory
    private func getTranslationsFilePath() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("translations_all.json")
    }
    
    /// Save all translations for all languages to local cache (both UserDefaults and file)
    private func saveAllTranslationsToCache(translations: [String: [String: String]], timestamp: String?) {
        let key = "translations_all"
        let timestampKey = "translations_global_timestamp"
        
        // Convert to JSON-serializable format
        guard let jsonData = try? JSONSerialization.data(withJSONObject: translations, options: .prettyPrinted) else {
            return
        }
        
        // Save to UserDefaults (for quick access)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.setValue(jsonString, forKey: key)
        }
        
        // Save to file (for persistence and larger datasets)
        if let filePath = getTranslationsFilePath() {
            do {
                try jsonData.write(to: filePath, options: .atomic)
            } catch {
            }
        }
        
        if let timestamp = timestamp {
            UserDefaults.standard.setValue(timestamp, forKey: timestampKey)
        } else {
        }
        UserDefaults.standard.synchronize()
    }
    
    /// Load all translations for all languages from local cache (file first, then UserDefaults)
    private func loadAllTranslationsFromCache() -> [String: [String: String]]? {
        // Try loading from file first (more reliable for larger datasets)
        if let filePath = getTranslationsFilePath(),
           FileManager.default.fileExists(atPath: filePath.path) {
            do {
                let jsonData = try Data(contentsOf: filePath)
                if let translations = try JSONSerialization.jsonObject(with: jsonData) as? [String: [String: String]] {
                    let timestamp = getGlobalCachedTimestamp()
                    let totalKeys = translations.values.reduce(0) { $0 + $1.count }
                    return translations
                }
            } catch {
            }
        }
        
        // Fallback to UserDefaults
        let key = "translations_all"
        if let jsonString = UserDefaults.standard.string(forKey: key),
           let jsonData = jsonString.data(using: .utf8),
           let translations = try? JSONSerialization.jsonObject(with: jsonData) as? [String: [String: String]] {
            let timestamp = getGlobalCachedTimestamp()
            let totalKeys = translations.values.reduce(0) { $0 + $1.count }
            return translations
        }
        return nil
    }
    
    /// Get the global cached timestamp (max across all languages)
    private func getGlobalCachedTimestamp() -> String? {
        let key = "translations_global_timestamp"
        let timestamp = UserDefaults.standard.string(forKey: key)
        if timestamp == nil {
        }
        return timestamp
    }
    
    // Legacy methods for backward compatibility
    private func saveToCache(translations: [String: String], 
                            language: String, 
                            timestamp: String?) {
        let key = "translations_\(language)"
        let timestampKey = "translations_\(language)_timestamp"
        
        UserDefaults.standard.setValue(translations, forKey: key)
        if let timestamp = timestamp {
            UserDefaults.standard.setValue(timestamp, forKey: timestampKey)
        } else {
        }
        UserDefaults.standard.synchronize()
    }
    
    private func loadFromCache(language: String) -> [String: String]? {
        let key = "translations_\(language)"
        let cached = UserDefaults.standard.dictionary(forKey: key) as? [String: String]
        if let cached = cached {
            let timestamp = getCachedTimestamp(language: language)
        } else {
        }
        return cached
    }
    
    private func getCachedTimestamp(language: String) -> String? {
        let key = "translations_\(language)_timestamp"
        let timestamp = UserDefaults.standard.string(forKey: key)
        if timestamp == nil {
        }
        return timestamp
    }
    
    /// Detect user's language based on their current GPS location
    /// Falls back to system locale if GPS access is unavailable
    func initializeLanguageFromLocation(_ locationManager: CLLocationManager) {
        // If we already have a saved preference, use it
        if UserDefaults.standard.string(forKey: "AppLanguage") != nil {
            return
        }
        
        // Location-based language detection can be extended here
        // For now, we rely on system locale detection
    }
    
    // MARK: - Backend Synchronization
    
    /// Load the list of supported languages from the backend
    private func loadSupportedLanguages() async {
        let endpoint = "\(baseURL)/Translations/GetLastUpdated"
        guard let url = URL(string: endpoint) else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LastUpdatedResponse.self, from: data)
            
            if response.success {
                // Build language map from available languages
                var languageMap: [String: String] = [:]
                for languageCode in response.last_updated.keys {
                    // Get the language display name from the LANGUAGE_NAME translation key
                    // For now, use the language code as the display name
                    // TODO: Fetch proper language names from a dedicated endpoint
                    languageMap[languageCode] = languageCode
                }
                
                Task { @MainActor in
                    self.supportedLanguages = languageMap
                }
            }
        } catch {
            // Fall back to empty dict - languages will still be usable
        }
    }
    
    func saveLanguagePreferenceToBackend(languageCode: String) {
        // Get sessionId from UserDefaults (safe access without SessionManager dependency)
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            return
        }
        
        guard let backendURL = URLComponents(string: "\(baseURL)/Profile/UpdateProfile")?.url else {
            return
        }
        
        var request = URLRequest(url: backendURL)
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
                    return
                }
                
                // Parse response
                if let data = data {
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let success = jsonResponse["success"] as? Bool {
                            if success {
                            } else {
                                let errorMsg = jsonResponse["error"] as? String ?? "Unknown error"
                            }
                        }
                    } catch {
                    }
                }
            }.resume()
        } catch {
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
    var descriptionText: String { localize("DESCRIPTION") }
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

struct AllTranslationsResponse: Codable {
    let success: Bool
    let translations: [String: [String: String]]
    let last_updated: String
    let total_count: Int
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
