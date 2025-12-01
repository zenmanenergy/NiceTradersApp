//
//  ExchangeRatesView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct ExchangeRatesView: View {
    @Environment(\.dismiss) var dismiss
    let localizationManager = LocalizationManager.shared
    @State private var exchangeRates: [String: Double] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var fromCurrency = "USD"
    @State private var toCurrency = "EUR"
    @State private var amount = "100"
    @State private var convertedAmount: Double?
    @State private var isConverting = false
    
    let majorCurrencies = ExchangeRatesAPI.shared.getMajorCurrencies()
    
    var body: some View {
        VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Currency Converter
                        converterSection
                        
                        // Exchange Rates List
                        ratesListSection
                    }
                    .padding(24)
                }
                .background(Color(hex: "f8fafc"))
            
            // Bottom Navigation
            BottomNavigation(activeTab: "home")
        }
        .navigationBarHidden(true)
        .onAppear {
            loadExchangeRates()
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text(localizationManager.localize("EXCHANGE_RATES"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                loadExchangeRates()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Converter Section
    var converterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localize("CURRENCY_CONVERTER"))
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(spacing: 16) {
                // Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("AMOUNT"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                        .onTapGesture { }
                        .simultaneousGesture(TapGesture().onEnded { })
                }
                
                // From Currency
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("FROM"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Picker("From Currency", selection: $fromCurrency) {
                        ForEach(majorCurrencies, id: \.code) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.code)
                            }.tag(currency.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                }
                
                // To Currency
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("TO"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Picker("To Currency", selection: $toCurrency) {
                        ForEach(majorCurrencies, id: \.code) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.code)
                            }.tag(currency.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                }
                
                // Convert Button
                Button(action: convertCurrency) {
                    HStack {
                        if isConverting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(localizationManager.localize("CONVERT"))
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isConverting || amount.isEmpty)
                
                // Result
                if let converted = convertedAmount {
                    VStack(spacing: 8) {
                        Text(localizationManager.localize("RESULT"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Text(ExchangeRatesAPI.shared.formatCurrencyAmount(converted, currency: toCurrency))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "667eea"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color(hex: "edf2f7"))
                    .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Rates List Section
    var ratesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localizationManager.localize("CURRENT_RATES"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "e53e3e"))
                    .padding(12)
                    .background(Color(hex: "fed7d7"))
                    .cornerRadius(8)
            }
            
            if exchangeRates.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Text("📊")
                        .font(.system(size: 48))
                    
                    Text(localizationManager.localize("NO_RATES_AVAILABLE"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Text(localizationManager.localize("TAP_REFRESH_RATES"))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(exchangeRates.keys.sorted()), id: \.self) { currency in
                        if let rate = exchangeRates[currency] {
                            HStack {
                                Text(ExchangeRatesAPI.shared.getCurrencySymbol(currency))
                                    .font(.system(size: 18))
                                    .frame(width: 30)
                                
                                Text(currency)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "2d3748"))
                                
                                Spacer()
                                
                                Text(String(format: "%.4f", rate))
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "667eea"))
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            
                            if currency != exchangeRates.keys.sorted().last {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Functions
    func loadExchangeRates() {
        isLoading = true
        errorMessage = nil
        
        ExchangeRatesAPI.shared.getExchangeRates { rates, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error
            } else if let rates = rates {
                exchangeRates = rates
            }
        }
    }
    
    func convertCurrency() {
        guard let amountValue = Double(amount) else { return }
        
        isConverting = true
        convertedAmount = nil
        
        ExchangeRatesAPI.shared.convertAmount(amountValue, from: fromCurrency, to: toCurrency) { result, error in
            isConverting = false
            
            if let result = result {
                convertedAmount = result
            } else if let error = error {
                errorMessage = error
            }
        }
    }
}

#Preview {
    ExchangeRatesView()
}
