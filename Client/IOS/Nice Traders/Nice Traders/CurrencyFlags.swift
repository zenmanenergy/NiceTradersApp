//
//  CurrencyFlags.swift
//  Nice Traders
//
//  Currency code to country flag emoji mapping
//  Each currency is mapped to its primary issuing country's flag
//

import Foundation

struct CurrencyFlags {
    /// Maps currency codes to their country flag emojis
    static let flagMap: [String: String] = [
        // Major Currencies
        "USD": "🇺🇸", // United States
        "EUR": "🇪🇺", // European Union
        "GBP": "🇬🇧", // United Kingdom
        "JPY": "🇯🇵", // Japan
        "CAD": "🇨🇦", // Canada
        "AUD": "🇦🇺", // Australia
        "CHF": "🇨🇭", // Switzerland
        
        // Asia-Pacific
        "CNY": "🇨🇳", // China
        "SEK": "🇸🇪", // Sweden
        "NOK": "🇳🇴", // Norway
        "DKK": "🇩🇰", // Denmark
        "KRW": "🇰🇷", // South Korea
        "SGD": "🇸🇬", // Singapore
        "HKD": "🇭🇰", // Hong Kong
        "NZD": "🇳🇿", // New Zealand
        "TWD": "🇹🇼", // Taiwan
        "MOP": "🇲🇴", // Macau
        "MNT": "🇲🇳", // Mongolia
        "KPW": "🇰🇵", // North Korea
        "BND": "🇧🇳", // Brunei
        "LAK": "🇱🇦", // Laos
        "KHR": "🇰🇭", // Cambodia
        "MMK": "🇲🇲", // Myanmar
        "FJD": "🇫🇯", // Fiji
        "PGK": "🇵🇬", // Papua New Guinea
        "SBD": "🇸🇧", // Solomon Islands
        "VUV": "🇻🇺", // Vanuatu
        "WST": "🇼🇸", // Samoa
        "TOP": "🇹🇴", // Tonga
        
        // Europe
        "PLN": "🇵🇱", // Poland
        "CZK": "🇨🇿", // Czech Republic
        "HUF": "🇭🇺", // Hungary
        "RON": "🇷🇴", // Romania
        "BGN": "🇧🇬", // Bulgaria
        "HRK": "🇭🇷", // Croatia
        "ISK": "🇮🇸", // Iceland
        "UAH": "🇺🇦", // Ukraine
        "BYN": "🇧🇾", // Belarus
        "RUB": "🇷🇺", // Russia
        "MDL": "🇲🇩", // Moldova
        "RSD": "🇷🇸", // Serbia
        "MKD": "🇲🇰", // North Macedonia
        "ALL": "🇦🇱", // Albania
        "BAM": "🇧🇦", // Bosnia-Herzegovina
        "KZT": "🇰🇿", // Kazakhstan
        "UZS": "🇺🇿", // Uzbekistan
        "AZN": "🇦🇿", // Azerbaijan
        "GEL": "🇬🇪", // Georgia
        "AMD": "🇦🇲", // Armenia
        "KGS": "🇰🇬", // Kyrgyzstan
        "TJS": "🇹🇯", // Tajikistan
        "TMT": "🇹🇲", // Turkmenistan
        
        // Americas
        "MXN": "🇲🇽", // Mexico
        "BRL": "🇧🇷", // Brazil
        "ARS": "🇦🇷", // Argentina
        "CLP": "🇨🇱", // Chile
        "COP": "🇨🇴", // Colombia
        "PEN": "🇵🇪", // Peru
        "PYG": "🇵🇾", // Paraguay
        "UYU": "🇺🇾", // Uruguay
        "BOB": "🇧🇴", // Bolivia
        "VES": "🇻🇪", // Venezuela
        "CUP": "🇨🇺", // Cuba
        "DOP": "🇩🇴", // Dominican Republic
        "GTQ": "🇬🇹", // Guatemala
        "HNL": "🇭🇳", // Honduras
        "NIO": "🇳🇮", // Nicaragua
        "PAB": "🇵🇦", // Panama
        "CRC": "🇨🇷", // Costa Rica
        "JMD": "🇯🇲", // Jamaica
        "TTD": "🇹🇹", // Trinidad & Tobago
        "BBD": "🇧🇧", // Barbados
        "BZD": "🇧🇿", // Belize
        "BSD": "🇧🇸", // Bahamas
        "HTG": "🇭🇹", // Haiti
        "XCD": "🇦🇬", // East Caribbean (Antigua & Barbuda)
        "AWG": "🇦🇼", // Aruba
        "ANG": "🇳🇱", // Netherlands Antilles
        "SRD": "🇸🇷", // Suriname
        "GYD": "🇬🇾", // Guyana
        
        // Middle East & Central Asia
        "AED": "🇦🇪", // UAE
        "SAR": "🇸🇦", // Saudi Arabia
        "ILS": "🇮🇱", // Israel
        "TRY": "🇹🇷", // Turkey
        "QAR": "🇶🇦", // Qatar
        "KWD": "🇰🇼", // Kuwait
        "BHD": "🇧🇭", // Bahrain
        "OMR": "🇴🇲", // Oman
        "JOD": "🇯🇴", // Jordan
        "MAD": "🇲🇦", // Morocco
        "TND": "🇹🇳", // Tunisia
        "DZD": "🇩🇿", // Algeria
        "EGP": "🇪🇬", // Egypt
        "AFN": "🇦🇫", // Afghanistan
        "IRR": "🇮🇷", // Iran
        "IQD": "🇮🇶", // Iraq
        "SYP": "🇸🇾", // Syria
        "LBP": "🇱🇧", // Lebanon
        "YER": "🇾🇪", // Yemen
        
        // South Asia
        "INR": "🇮🇳", // India
        "PKR": "🇵🇰", // Pakistan
        "BDT": "🇧🇩", // Bangladesh
        "LKR": "🇱🇰", // Sri Lanka
        "NPR": "🇳🇵", // Nepal
        "BTN": "🇧🇹", // Bhutan
        "MVR": "🇲🇻", // Maldives
        
        // Southeast Asia
        "THB": "🇹🇭", // Thailand
        "IDR": "🇮🇩", // Indonesia
        "MYR": "🇲🇾", // Malaysia
        "PHP": "🇵🇭", // Philippines
        "VND": "🇻🇳", // Vietnam
        
        // Africa
        "ZAR": "🇿🇦", // South Africa
        "NGN": "🇳🇬", // Nigeria
        "KES": "🇰🇪", // Kenya
        "GHS": "🇬🇭", // Ghana
        "UGX": "🇺🇬", // Uganda
        "TZS": "🇹🇿", // Tanzania
        "ETB": "🇪🇹", // Ethiopia
        "ZMW": "🇿🇲", // Zambia
        "MWK": "🇲🇼", // Malawi
        "MUR": "🇲🇺", // Mauritius
        "SCR": "🇸🇨", // Seychelles
        "BWP": "🇧🇼", // Botswana
        "NAD": "🇳🇦", // Namibia
        "SZL": "🇸🇿", // Eswatini
        "LSL": "🇱🇸", // Lesotho
        "AOA": "🇦🇴", // Angola
        "MZN": "🇲🇿", // Mozambique
        "RWF": "🇷🇼", // Rwanda
        "BIF": "🇧🇮", // Burundi
        "CDF": "🇨🇩", // Democratic Republic of Congo
        "XAF": "🇨🇲", // Central African CFA Franc (Cameroon)
        "XOF": "🇧🇯", // West African CFA Franc (Benin)
        
        // Additional currencies (verify these are all used in system)
        "QAR": "🇶🇦", // Qatar (alternate code, primary is QAR)
    ]
    
    /// Get flag emoji for a currency code
    /// - Parameter currencyCode: ISO 4217 currency code (e.g., "USD")
    /// - Returns: Country flag emoji or currency code if not found
    static func flagForCurrency(_ currencyCode: String) -> String {
        return flagMap[currencyCode.uppercased()] ?? currencyCode
    }
    
    /// Get formatted currency display with flag
    /// - Parameters:
    ///   - code: Currency code
    ///   - name: Currency name
    /// - Returns: Formatted string like "🇺🇸 USD - US Dollar"
    static func formattedCurrencyWithFlag(code: String, name: String) -> String {
        let flag = flagForCurrency(code)
        return "\(flag) \(code) - \(name)"
    }
    
    /// Check if a currency has a flag mapping
    /// - Parameter currencyCode: ISO 4217 currency code
    /// - Returns: True if flag is available
    static func hasFlagForCurrency(_ currencyCode: String) -> Bool {
        return flagMap[currencyCode.uppercased()] != nil
    }
    
    /// Get all currencies that are missing flag mappings
    /// - Parameter currencies: Array of Currency objects
    /// - Returns: Array of currency codes without flags
    static func missingFlags(from currencies: [Currency]) -> [String] {
        return currencies
            .map { $0.code }
            .filter { !hasFlagForCurrency($0) }
    }
}

/// Extension to Currency struct for convenience methods
extension Currency {
    /// Get flag emoji for this currency
    var flag: String {
        return CurrencyFlags.flagForCurrency(code)
    }
    
    /// Get formatted display with flag
    var displayWithFlag: String {
        return CurrencyFlags.formattedCurrencyWithFlag(code: code, name: name)
    }
}
