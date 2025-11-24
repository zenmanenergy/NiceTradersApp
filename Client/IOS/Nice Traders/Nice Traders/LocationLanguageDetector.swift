import Foundation
import CoreLocation

/// Detects user's preferred language based on GPS location
class LocationLanguageDetector {
    
    // MARK: - Country Code to Language Mapping
    // Maps ISO 3166-1 alpha-2 country codes to preferred language codes
    private static let countryLanguageMap: [String: String] = [
        // Spanish-speaking countries
        "ES": "es", "MX": "es", "AR": "es", "CO": "es", "PE": "es", "VE": "es",
        "CL": "es", "EC": "es", "BO": "es", "PY": "es", "UY": "es", "GT": "es",
        "CU": "es", "DO": "es", "HN": "es", "SV": "es", "NI": "es", "CR": "es",
        "PA": "es", "PR": "es",
        
        // French-speaking countries
        "FR": "fr", "CA": "fr", "BE": "fr", "CH": "fr", "SN": "fr", "CI": "fr",
        "CM": "fr", "CD": "fr", "CG": "fr", "GA": "fr", "GN": "fr", "ML": "fr",
        "BF": "fr", "NE": "fr", "DJ": "fr", "RE": "fr",
        
        // German-speaking countries
        "DE": "de", "AT": "de",
        
        // Portuguese-speaking countries
        "PT": "pt", "BR": "pt", "AO": "pt", "MZ": "pt", "CV": "pt", "ST": "pt",
        
        // Japanese
        "JP": "ja",
        
        // Chinese
        "CN": "zh", "TW": "zh", "HK": "zh", "MO": "zh", "SG": "zh",
        
        // Russian
        "RU": "ru", "BY": "ru", "KZ": "ru",
        
        // Arabic-speaking countries
        "SA": "ar", "AE": "ar", "EG": "ar", "JO": "ar", "LB": "ar", "SY": "ar",
        "IQ": "ar", "KW": "ar", "QA": "ar", "BH": "ar", "OM": "ar", "YE": "ar",
        "MA": "ar", "DZ": "ar", "TN": "ar", "LY": "ar", "SD": "ar", "PS": "ar",
        "IL": "ar",
        
        // Hindi
        "IN": "hi",
        
        // Slovak
        "SK": "sk",
        
        // Default to English for unlisted countries
        "GB": "en", "US": "en", "IE": "en", "AU": "en", "NZ": "en", "ZA": "en",
    ]
    
    // MARK: - Public Methods
    
    /// Detects the user's language based on their current location
    /// - Parameters:
    ///   - location: The user's current CLLocation
    ///   - completion: Closure called with detected language code (e.g., "es", "fr", "en")
    static func detectLanguageFromLocation(_ location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            // Default to English if geocoding fails
            guard error == nil, let placemark = placemarks?.first else {
                completion("en")
                return
            }
            
            // Get the ISO country code and map it to language
            let countryCode = placemark.isoCountryCode?.uppercased() ?? "US"
            let detectedLanguage = countryLanguageMap[countryCode] ?? "en"
            
            completion(detectedLanguage)
        }
    }
    
    /// Synchronously get language for a country code (for unit testing or immediate access)
    /// - Parameter countryCode: ISO 3166-1 alpha-2 country code (e.g., "US", "ES", "FR")
    /// - Returns: Language code or "en" if not mapped
    static func languageForCountryCode(_ countryCode: String) -> String {
        let code = countryCode.uppercased()
        return countryLanguageMap[code] ?? "en"
    }
    
    /// Get all supported language codes and their display names
    static func getAllSupportedLanguages() -> [(code: String, name: String)] {
        return [
            ("en", "English"),
            ("es", "Español"),
            ("fr", "Français"),
            ("de", "Deutsch"),
            ("pt", "Português"),
            ("ja", "日本語"),
            ("zh", "中文"),
            ("ru", "Русский"),
            ("ar", "العربية"),
            ("hi", "हिन्दी"),
            ("sk", "Slovenčina"),
        ]
    }
}
