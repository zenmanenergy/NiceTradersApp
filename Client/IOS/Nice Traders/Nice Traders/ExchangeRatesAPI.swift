//
//  ExchangeRatesAPI.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import Foundation

struct ExchangeRate: Codable {
    let fromCurrency: String
    let toCurrency: String
    let rate: Double
    let date: String
}

struct CurrencyInfo {
    let code: String
    let name: String
    let symbol: String
}

class ExchangeRatesAPI {
    static let shared = ExchangeRatesAPI()
    
    private var cachedRates: [String: Double] = [:]
    private var lastFetchDate: Date?
    
    // MARK: - Formatting
    
    /**
     * Format amount based on rounding preference
     */
    func formatAmount(_ amount: Double, shouldRound: Bool? = false) -> String {
        if shouldRound ?? false {
            return String(format: "%.0f", amount)
        } else {
            return String(format: "%.2f", amount)
        }
    }
    
    // MARK: - API Functions
    
    /**
     * Download latest exchange rates from API and save to database
     */
    func downloadExchangeRates(completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(Settings.shared.baseURL)/ExchangeRates/Download")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    completion(true, nil)
                } else {
                    completion(false, "Failed to download exchange rates")
                }
            }
        }.resume()
    }
    
    /**
     * Get all current exchange rates from database
     */
    func getExchangeRates(date: String? = nil, completion: @escaping ([String: Double]?, String?) -> Void) {
        var urlString = "\(Settings.shared.baseURL)/ExchangeRates/GetRates"
        
        if let date = date {
            urlString += "?date=\(date)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let rates = json["rates"] as? [String: Double] {
                    
                    self.cachedRates = rates
                    self.lastFetchDate = Date()
                    completion(rates, nil)
                } else {
                    completion(nil, "Failed to get exchange rates")
                }
            }
        }.resume()
    }
    
    /**
     * Get exchange rate between two specific currencies
     */
    func getExchangeRate(from fromCurrency: String, to toCurrency: String, completion: @escaping (Double?, String?) -> Void) {
        var components = URLComponents(string: "\(Settings.shared.baseURL)/ExchangeRates/GetRate")!
        components.queryItems = [
            URLQueryItem(name: "fromCurrency", value: fromCurrency),
            URLQueryItem(name: "toCurrency", value: toCurrency)
        ]
        
        guard let url = components.url else {
            completion(nil, "Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let rate = json["rate"] as? Double {
                    completion(rate, nil)
                } else {
                    completion(nil, "Failed to get exchange rate")
                }
            }
        }.resume()
    }
    
    /**
     * Convert an amount from one currency to another
     */
    func convertAmount(_ amount: Double, from fromCurrency: String, to toCurrency: String, completion: @escaping (Double?, String?) -> Void) {
        var components = URLComponents(string: "\(Settings.shared.baseURL)/ExchangeRates/Convert")!
        components.queryItems = [
            URLQueryItem(name: "amount", value: String(amount)),
            URLQueryItem(name: "fromCurrency", value: fromCurrency),
            URLQueryItem(name: "toCurrency", value: toCurrency)
        ]
        
        guard let url = components.url else {
            completion(nil, "Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "Network error")
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    if let success = json["success"] as? Bool, success,
                       let convertedAmount = json["converted_amount"] as? Double {
                        completion(convertedAmount, nil)
                    } else {
                        let errorMsg = json["error"] as? String ?? "Failed to convert amount"
                        completion(nil, errorMsg)
                    }
                } else {
                    completion(nil, "Failed to parse response")
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Functions
    
    /**
     * Format currency amount for display
     */
    func formatCurrencyAmount(_ amount: Double, currency: String, showSymbol: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = showSymbol ? .currency : .decimal
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    /**
     * Get currency symbol for a currency code
     */
    func getCurrencySymbol(_ currencyCode: String) -> String {
        let symbols: [String: String] = [
            "USD": "$",
            "EUR": "€",
            "GBP": "£",
            "JPY": "¥",
            "CNY": "¥",
            "INR": "₹",
            "CAD": "C$",
            "AUD": "A$",
            "CHF": "Fr",
            "SEK": "kr",
            "NOK": "kr",
            "DKK": "kr",
            "PLN": "zł",
            "CZK": "Kč",
            "HUF": "Ft",
            "RUB": "₽",
            "BRL": "R$",
            "MXN": "$",
            "ZAR": "R",
            "KRW": "₩",
            "SGD": "S$",
            "HKD": "HK$",
            "NZD": "NZ$",
            "TRY": "₺",
            "THB": "฿"
        ]
        
        return symbols[currencyCode] ?? currencyCode
    }
    
    /**
     * Get list of major currency codes
     */
    func getMajorCurrencies() -> [CurrencyInfo] {
        return [
            CurrencyInfo(code: "USD", name: "US Dollar", symbol: "$"),
            CurrencyInfo(code: "EUR", name: "Euro", symbol: "€"),
            CurrencyInfo(code: "GBP", name: "British Pound", symbol: "£"),
            CurrencyInfo(code: "JPY", name: "Japanese Yen", symbol: "¥"),
            CurrencyInfo(code: "CNY", name: "Chinese Yuan", symbol: "¥"),
            CurrencyInfo(code: "INR", name: "Indian Rupee", symbol: "₹"),
            CurrencyInfo(code: "CAD", name: "Canadian Dollar", symbol: "C$"),
            CurrencyInfo(code: "AUD", name: "Australian Dollar", symbol: "A$"),
            CurrencyInfo(code: "CHF", name: "Swiss Franc", symbol: "Fr"),
            CurrencyInfo(code: "SEK", name: "Swedish Krona", symbol: "kr"),
            CurrencyInfo(code: "NOK", name: "Norwegian Krone", symbol: "kr"),
            CurrencyInfo(code: "DKK", name: "Danish Krone", symbol: "kr"),
            CurrencyInfo(code: "PLN", name: "Polish Zloty", symbol: "zł"),
            CurrencyInfo(code: "CZK", name: "Czech Koruna", symbol: "Kč"),
            CurrencyInfo(code: "HUF", name: "Hungarian Forint", symbol: "Ft"),
            CurrencyInfo(code: "RUB", name: "Russian Ruble", symbol: "₽"),
            CurrencyInfo(code: "BRL", name: "Brazilian Real", symbol: "R$"),
            CurrencyInfo(code: "MXN", name: "Mexican Peso", symbol: "$"),
            CurrencyInfo(code: "ZAR", name: "South African Rand", symbol: "R"),
            CurrencyInfo(code: "KRW", name: "South Korean Won", symbol: "₩"),
            CurrencyInfo(code: "SGD", name: "Singapore Dollar", symbol: "S$"),
            CurrencyInfo(code: "HKD", name: "Hong Kong Dollar", symbol: "HK$"),
            CurrencyInfo(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$")
        ]
    }
    
    /**
     * Calculate converted amount using cached rates or fallback
     */
    func calculateReceiveAmount(from: String, to: String, amount: String, shouldRound: Bool = false) -> String {
        guard let amountValue = Double(amount), amountValue > 0 else { return "0" }
        
        // If we have cached rates, use them
        if !cachedRates.isEmpty {
            let fromRate = cachedRates[from] ?? 1.0
            let toRate = cachedRates[to] ?? 1.0
            let usdAmount = amountValue / fromRate
            let targetAmount = usdAmount * toRate
            
            // Format based on rounding preference
            if shouldRound {
                return String(format: "%.0f", targetAmount)
            } else {
                if targetAmount >= 100 {
                    return String(format: "%.2f", targetAmount)
                } else if targetAmount >= 10 {
                    return String(format: "%.2f", targetAmount)
                } else {
                    return String(format: "%.4f", targetAmount)
                }
            }
        }
        
        // Fallback to mock rates if no cached rates available
        let mockRates: [String: Double] = [
            "USD": 1.0, "EUR": 0.863, "GBP": 0.756, "JPY": 156.18,
            "CAD": 1.4, "AUD": 1.53, "CHF": 0.804, "CNY": 7.08,
            "SEK": 9.46, "NZD": 1.74, "MXN": 18.31, "BRL": 5.35,
            "INR": 89.44, "ZAR": 17.12, "KRW": 1467.67, "SGD": 1.3,
            "HKD": 7.78, "NOK": 10.14, "DKK": 6.44, "PLN": 3.66,
            "CZK": 20.85, "HUF": 329.16, "RUB": 77.91, "TRY": 42.5,
            "THB": 32.16
        ]
        
        let fromRate = mockRates[from] ?? 1.0
        let toRate = mockRates[to] ?? 1.0
        let usdAmount = amountValue / fromRate
        let targetAmount = usdAmount * toRate
        
        // Format based on rounding preference
        if shouldRound {
            return String(format: "%.0f", targetAmount)
        } else if targetAmount >= 100 {
            return String(format: "%.2f", targetAmount)
        } else if targetAmount >= 10 {
            return String(format: "%.2f", targetAmount)
        } else {
            return String(format: "%.4f", targetAmount)
        }
    }
    
    /**
     * Check if rates need to be refreshed (older than 1 hour)
     */
    func shouldRefreshRates() -> Bool {
        guard let lastFetch = lastFetchDate else { return true }
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return lastFetch < oneHourAgo
    }
    
    /**
     * Refresh rates if needed
     */
    func refreshRatesIfNeeded(completion: ((Bool) -> Void)? = nil) {
        if shouldRefreshRates() {
            getExchangeRates { rates, error in
                completion?(error == nil)
            }
        } else {
            completion?(true)
        }
    }
    
    /**
     * Convert amount synchronously using cached rates (for immediate display)
     */
    func convertAmountSync(_ amount: Double, from fromCurrency: String, to toCurrency: String) -> Double? {
        // If we have cached rates, use them
        if !cachedRates.isEmpty {
            let fromRate = cachedRates[fromCurrency] ?? 1.0
            let toRate = cachedRates[toCurrency] ?? 1.0
            let usdAmount = amount / fromRate
            let targetAmount = usdAmount * toRate
            return targetAmount
        }
        
        // Fallback to mock rates if no cached rates available
        let mockRates: [String: Double] = [
            "USD": 1.0, "EUR": 0.863, "GBP": 0.756, "JPY": 156.18,
            "CAD": 1.4, "AUD": 1.53, "CHF": 0.804, "CNY": 7.08,
            "SEK": 9.46, "NZD": 1.74, "MXN": 18.31, "BRL": 5.35,
            "INR": 89.44, "ZAR": 17.12, "KRW": 1467.67, "SGD": 1.3,
            "HKD": 7.78, "NOK": 10.14, "DKK": 6.44, "PLN": 3.66,
            "CZK": 20.85, "HUF": 329.16, "RUB": 77.91, "TRY": 42.5,
            "THB": 32.16
        ]
        
        let fromRate = mockRates[fromCurrency] ?? 1.0
        let toRate = mockRates[toCurrency] ?? 1.0
        let usdAmount = amount / fromRate
        let targetAmount = usdAmount * toRate
        
        // Return full precision - formatting will be done at display level
        return targetAmount
    }
}
