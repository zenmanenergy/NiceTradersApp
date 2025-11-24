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
        }
    }
    
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
    
    func localize(_ key: String) -> String {
        let localizedString = NSLocalizedString(
            key,
            tableName: "Localizable",
            bundle: Bundle.main,
            comment: ""
        )
        return localizedString
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
