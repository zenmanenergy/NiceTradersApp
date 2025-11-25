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
            UserDefaults.standard.synchronize()
            print("🔴 [LocalizationManager] Saved to UserDefaults: \(currentLanguage)")
            languageVersion += 1
            print("🔴 [LocalizationManager] languageVersion incremented to: \(languageVersion)")
            objectWillChange.send()
            
            // Immediately load cached translations for this language
            if let cached = self.loadFromCache(language: currentLanguage) {
                self.cachedTranslations = cached
                print("📦 [LocalizationManager] Loaded cached translations for \(currentLanguage)")
            } else {
                print("⚠️ [LocalizationManager] No cached translations for \(currentLanguage)")
                self.cachedTranslations = [:]
            }
            
            // Then download/check for updates in background
            Task {
                await self.checkForUpdates(language: self.currentLanguage)
            }
            
            // Save language preference to backend
            self.saveLanguagePreferenceToBackend(languageCode: currentLanguage)
        }
    }
    
    @Published var languageVersion: Int = 0
    
    static let shared = LocalizationManager()
    
    // In-memory cache of translations
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
        ]
    ]
    
    @Published var supportedLanguages: [String: String] = [:]
    
    private let baseURL = "http://10.10.4.21:9000"
    
    private override init() {
        // Initialize before super.init()
        self.currentLanguage = "en"
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
            // First, load supported languages from backend
            await self.loadSupportedLanguages()
            
            // First load from cache
            if let cached = self.loadFromCache(language: self.currentLanguage) {
                self.cachedTranslations = cached
                print("📦 [LocalizationManager] Loaded \(cached.count) cached translations")
            }
            
            // Then check for server updates in background
            await self.checkForUpdates(language: self.currentLanguage)
            
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
                // Trigger UI update by incrementing version
                Task { @MainActor in
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
            
            guard response.success else {
                print("⚠️ [LocalizationManager] GetLastUpdated returned success: false")
                return
            }
            
            guard let serverTimestamp = response.last_updated[language] else {
                print("⚠️ [LocalizationManager] No timestamp found for language: \(language)")
                return
            }
            
            let cachedTimestamp = getCachedTimestamp(language: language)
            
            // Always download if no cache exists
            if cachedTimestamp == nil {
                print("⚠️ [LocalizationManager] No cached timestamp for \(language), downloading from server")
                await downloadTranslations(language: language)
            } 
            // If server timestamp is newer, download updates
            else if serverTimestamp > cachedTimestamp! {
                print("🔄 [LocalizationManager] Server timestamp newer than cache (\(serverTimestamp) > \(cachedTimestamp!)), downloading updates")
                await downloadTranslations(language: language)
            } else {
                print("✓ [LocalizationManager] Cache is up to date for \(language)")
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
        // Check if user is logged in (get sessionId from UserDefaults)
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            print("ℹ️ [LocalizationManager] User not logged in, skipping backend language load")
            return
        }
        
        let endpoint = "\(baseURL)/Profile/GetProfile"
        guard let url = URL(string: "\(endpoint)?SessionId=\(sessionId)") else {
            print("⚠️ [LocalizationManager] Invalid URL for GetProfile")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("⚠️ [LocalizationManager] Invalid response format")
                return
            }
            
            if let profileData = jsonResponse["profile"] as? [String: Any],
               let preferredLanguage = profileData["preferred_language"] as? String,
               !preferredLanguage.isEmpty {
                
                if supportedLanguages[preferredLanguage] != nil && preferredLanguage != self.currentLanguage {
                    print("📥 [LocalizationManager] Loading user's preferred language from backend: \(preferredLanguage)")
                    Task { @MainActor in
                        self.currentLanguage = preferredLanguage
                        UserDefaults.standard.set(preferredLanguage, forKey: "AppLanguage")
                    }
                }
            }
        } catch {
            print("⚠️ [LocalizationManager] Error loading user profile: \(error.localizedDescription)")
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
            print("📦 [LocalizationManager] Cached \(translations.count) translations for \(language) with timestamp: \(timestamp)")
        } else {
            print("⚠️ [LocalizationManager] Cached \(translations.count) translations for \(language) but NO TIMESTAMP!")
        }
        UserDefaults.standard.synchronize()
    }
    
    private func loadFromCache(language: String) -> [String: String]? {
        let key = "translations_\(language)"
        let cached = UserDefaults.standard.dictionary(forKey: key) as? [String: String]
        if let cached = cached {
            let timestamp = getCachedTimestamp(language: language)
            print("📥 [LocalizationManager] Loaded \(cached.count) cached translations for \(language) (timestamp: \(timestamp ?? "NONE"))")
        } else {
            print("⚠️ [LocalizationManager] No cached translations found for \(language)")
        }
        return cached
    }
    
    private func getCachedTimestamp(language: String) -> String? {
        let key = "translations_\(language)_timestamp"
        let timestamp = UserDefaults.standard.string(forKey: key)
        if timestamp == nil {
            print("⚠️ [LocalizationManager] No cached timestamp for \(language)")
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
        print("ℹ️ [LocalizationManager] Location-based language detection not yet implemented")
    }
    
    // MARK: - Backend Synchronization
    
    /// Load the list of supported languages from the backend
    private func loadSupportedLanguages() async {
        let endpoint = "\(baseURL)/Translations/GetLastUpdated"
        guard let url = URL(string: endpoint) else {
            print("⚠️ [LocalizationManager] Invalid URL for GetLastUpdated")
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
                    print("✅ [LocalizationManager] Loaded \(languageMap.count) supported languages from backend")
                }
            }
        } catch {
            print("⚠️ [LocalizationManager] Error loading supported languages: \(error.localizedDescription)")
            // Fall back to empty dict - languages will still be usable
        }
    }
    
    private func saveLanguagePreferenceToBackend(languageCode: String) {
        // Get sessionId from UserDefaults (safe access without SessionManager dependency)
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            print("ℹ️ [LocalizationManager] User not logged in, language preference not saved to backend")
            return
        }
        
        let backendURL = URLComponents(string: "\(baseURL)/Profile/UpdateProfile")?.url ?? URL(fileURLWithPath: "")
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
                    print("❌ [LocalizationManager] Error saving language preference: \(error.localizedDescription)")
                    return
                }
                
                // Parse response
                if let data = data {
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let success = jsonResponse["success"] as? Bool {
                            if success {
                                print("✅ [LocalizationManager] Language preference saved to backend: \(languageCode)")
                            } else {
                                let errorMsg = jsonResponse["error"] as? String ?? "Unknown error"
                                print("⚠️ [LocalizationManager] Failed to save language preference: \(errorMsg)")
                            }
                        }
                    } catch {
                        print("⚠️ [LocalizationManager] Failed to parse response: \(error.localizedDescription)")
                    }
                }
            }.resume()
        } catch {
            print("❌ [LocalizationManager] Error encoding language preference: \(error.localizedDescription)")
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
