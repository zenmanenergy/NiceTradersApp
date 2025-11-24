//
//  EditListingView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI
import CoreLocation

struct EditListingView: View {
    let listingId: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    @StateObject private var locationManager = LocationManager()
    
    // Form data
    @State private var selectedCurrency: Currency?
    @State private var amount: String = ""
    @State private var selectedAcceptCurrency: Currency?
    @State private var location: String = ""
    @State private var locationRadius: String = "5"
    @State private var meetingPreference: String = "public"
    @State private var availableUntil: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    
    // UI state
    @State private var currentStep = 1
    @State private var showAllCurrencies = false
    @State private var showAllAcceptCurrencies = false
    @State private var searchQuery = ""
    @State private var searchQueryAccept = ""
    @State private var locationStatus: LocationStatus = .detected // Start as detected for editing
    @State private var isSubmitting = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var fieldErrors: [String: String] = [:]
    @State private var navigateToDashboard = false
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    
    let totalSteps = 3
    
    enum LocationStatus {
        case unset, detecting, detected
    }
    
    let locationRadiusOptions = [
        ("1", "Within 1 mile"),
        ("3", "Within 3 miles"),
        ("5", "Within 5 miles"),
        ("10", "Within 10 miles"),
        ("25", "Within 25 miles")
    ]
    
    // All currencies (same as CreateListingView)
    let currencies: [Currency] = [
        Currency(code: "USD", name: "US Dollar", popular: true),
        Currency(code: "EUR", name: "Euro", popular: true),
        Currency(code: "GBP", name: "British Pound", popular: true),
        Currency(code: "JPY", name: "Japanese Yen", popular: true),
        Currency(code: "CAD", name: "Canadian Dollar", popular: true),
        Currency(code: "AUD", name: "Australian Dollar", popular: true),
        Currency(code: "CHF", name: "Swiss Franc", popular: true),
        Currency(code: "CNY", name: "Chinese Yuan", popular: false),
        Currency(code: "SEK", name: "Swedish Krona", popular: false),
        Currency(code: "NOK", name: "Norwegian Krone", popular: false),
        Currency(code: "DKK", name: "Danish Krone", popular: false),
        Currency(code: "PLN", name: "Polish Złoty", popular: false),
        Currency(code: "CZK", name: "Czech Koruna", popular: false),
        Currency(code: "HUF", name: "Hungarian Forint", popular: false),
        Currency(code: "RUB", name: "Russian Ruble", popular: false),
        Currency(code: "KRW", name: "South Korean Won", popular: false),
        Currency(code: "SGD", name: "Singapore Dollar", popular: false),
        Currency(code: "HKD", name: "Hong Kong Dollar", popular: false),
        Currency(code: "NZD", name: "New Zealand Dollar", popular: false),
        Currency(code: "MXN", name: "Mexican Peso", popular: false),
        Currency(code: "BRL", name: "Brazilian Real", popular: false),
        Currency(code: "INR", name: "Indian Rupee", popular: false),
        Currency(code: "ZAR", name: "South African Rand", popular: false),
        Currency(code: "TRY", name: "Turkish Lira", popular: false),
        Currency(code: "THB", name: "Thai Baht", popular: false),
        Currency(code: "IDR", name: "Indonesian Rupiah", popular: false),
        Currency(code: "MYR", name: "Malaysian Ringgit", popular: false),
        Currency(code: "PHP", name: "Philippine Peso", popular: false),
        Currency(code: "AED", name: "UAE Dirham", popular: false),
        Currency(code: "SAR", name: "Saudi Riyal", popular: false),
        Currency(code: "ILS", name: "Israeli Shekel", popular: false),
        Currency(code: "ARS", name: "Argentine Peso", popular: false),
        Currency(code: "CLP", name: "Chilean Peso", popular: false),
        Currency(code: "COP", name: "Colombian Peso", popular: false),
        Currency(code: "PEN", name: "Peruvian Sol", popular: false),
        Currency(code: "EGP", name: "Egyptian Pound", popular: false),
        Currency(code: "NGN", name: "Nigerian Naira", popular: false),
        Currency(code: "KES", name: "Kenyan Shilling", popular: false),
        Currency(code: "RON", name: "Romanian Leu", popular: false),
        Currency(code: "BGN", name: "Bulgarian Lev", popular: false),
        Currency(code: "HRK", name: "Croatian Kuna", popular: false),
        Currency(code: "ISK", name: "Icelandic Króna", popular: false),
        Currency(code: "UAH", name: "Ukrainian Hryvnia", popular: false),
        Currency(code: "VND", name: "Vietnamese Dong", popular: false),
        Currency(code: "PKR", name: "Pakistani Rupee", popular: false),
        Currency(code: "BDT", name: "Bangladeshi Taka", popular: false),
        Currency(code: "LKR", name: "Sri Lankan Rupee", popular: false),
        Currency(code: "QAR", name: "Qatari Riyal", popular: false),
        Currency(code: "KWD", name: "Kuwaiti Dinar", popular: false),
        Currency(code: "BHD", name: "Bahraini Dinar", popular: false),
        Currency(code: "OMR", name: "Omani Rial", popular: false),
        Currency(code: "JOD", name: "Jordanian Dinar", popular: false),
        Currency(code: "MAD", name: "Moroccan Dirham", popular: false),
        Currency(code: "TND", name: "Tunisian Dinar", popular: false),
        Currency(code: "DZD", name: "Algerian Dinar", popular: false),
        Currency(code: "GHS", name: "Ghanaian Cedi", popular: false),
        Currency(code: "UGX", name: "Ugandan Shilling", popular: false),
        Currency(code: "TZS", name: "Tanzanian Shilling", popular: false),
        Currency(code: "ETB", name: "Ethiopian Birr", popular: false),
        Currency(code: "ZMW", name: "Zambian Kwacha", popular: false),
        Currency(code: "MWK", name: "Malawian Kwacha", popular: false),
        Currency(code: "MUR", name: "Mauritian Rupee", popular: false),
        Currency(code: "SCR", name: "Seychellois Rupee", popular: false),
        Currency(code: "BWP", name: "Botswana Pula", popular: false),
        Currency(code: "NAD", name: "Namibian Dollar", popular: false),
        Currency(code: "SZL", name: "Swazi Lilangeni", popular: false),
        Currency(code: "LSL", name: "Lesotho Loti", popular: false),
        Currency(code: "AOA", name: "Angolan Kwanza", popular: false),
        Currency(code: "MZN", name: "Mozambican Metical", popular: false),
        Currency(code: "RWF", name: "Rwandan Franc", popular: false),
        Currency(code: "BIF", name: "Burundian Franc", popular: false),
        Currency(code: "CDF", name: "Congolese Franc", popular: false),
        Currency(code: "XAF", name: "Central African CFA Franc", popular: false),
        Currency(code: "XOF", name: "West African CFA Franc", popular: false),
        Currency(code: "KZT", name: "Kazakhstani Tenge", popular: false),
        Currency(code: "UZS", name: "Uzbekistani Som", popular: false),
        Currency(code: "AZN", name: "Azerbaijani Manat", popular: false),
        Currency(code: "GEL", name: "Georgian Lari", popular: false),
        Currency(code: "AMD", name: "Armenian Dram", popular: false),
        Currency(code: "KGS", name: "Kyrgyzstani Som", popular: false),
        Currency(code: "TJS", name: "Tajikistani Somoni", popular: false),
        Currency(code: "TMT", name: "Turkmenistani Manat", popular: false),
        Currency(code: "AFN", name: "Afghan Afghani", popular: false),
        Currency(code: "IRR", name: "Iranian Rial", popular: false),
        Currency(code: "IQD", name: "Iraqi Dinar", popular: false),
        Currency(code: "SYP", name: "Syrian Pound", popular: false),
        Currency(code: "LBP", name: "Lebanese Pound", popular: false),
        Currency(code: "YER", name: "Yemeni Rial", popular: false),
        Currency(code: "NPR", name: "Nepalese Rupee", popular: false),
        Currency(code: "BTN", name: "Bhutanese Ngultrum", popular: false),
        Currency(code: "MVR", name: "Maldivian Rufiyaa", popular: false),
        Currency(code: "MMK", name: "Myanmar Kyat", popular: false),
        Currency(code: "LAK", name: "Lao Kip", popular: false),
        Currency(code: "KHR", name: "Cambodian Riel", popular: false),
        Currency(code: "BND", name: "Brunei Dollar", popular: false),
        Currency(code: "TWD", name: "New Taiwan Dollar", popular: false),
        Currency(code: "MOP", name: "Macanese Pataca", popular: false),
        Currency(code: "MNT", name: "Mongolian Tögrög", popular: false),
        Currency(code: "KPW", name: "North Korean Won", popular: false),
        Currency(code: "FJD", name: "Fijian Dollar", popular: false),
        Currency(code: "PGK", name: "Papua New Guinean Kina", popular: false),
        Currency(code: "SBD", name: "Solomon Islands Dollar", popular: false),
        Currency(code: "VUV", name: "Vanuatu Vatu", popular: false),
        Currency(code: "WST", name: "Samoan Tālā", popular: false),
        Currency(code: "TOP", name: "Tongan Paʻanga", popular: false),
        Currency(code: "BYN", name: "Belarusian Ruble", popular: false),
        Currency(code: "MDL", name: "Moldovan Leu", popular: false),
        Currency(code: "RSD", name: "Serbian Dinar", popular: false),
        Currency(code: "MKD", name: "Macedonian Denar", popular: false),
        Currency(code: "ALL", name: "Albanian Lek", popular: false),
        Currency(code: "BAM", name: "Bosnia-Herzegovina Mark", popular: false),
        Currency(code: "CUP", name: "Cuban Peso", popular: false),
        Currency(code: "DOP", name: "Dominican Peso", popular: false),
        Currency(code: "GTQ", name: "Guatemalan Quetzal", popular: false),
        Currency(code: "HNL", name: "Honduran Lempira", popular: false),
        Currency(code: "NIO", name: "Nicaraguan Córdoba", popular: false),
        Currency(code: "PAB", name: "Panamanian Balboa", popular: false),
        Currency(code: "CRC", name: "Costa Rican Colón", popular: false),
        Currency(code: "JMD", name: "Jamaican Dollar", popular: false),
        Currency(code: "TTD", name: "Trinidad & Tobago Dollar", popular: false),
        Currency(code: "BBD", name: "Barbadian Dollar", popular: false),
        Currency(code: "BZD", name: "Belize Dollar", popular: false),
        Currency(code: "BSD", name: "Bahamian Dollar", popular: false),
        Currency(code: "HTG", name: "Haitian Gourde", popular: false),
        Currency(code: "XCD", name: "East Caribbean Dollar", popular: false),
        Currency(code: "AWG", name: "Aruban Florin", popular: false),
        Currency(code: "ANG", name: "Netherlands Antillean Guilder", popular: false),
        Currency(code: "SRD", name: "Surinamese Dollar", popular: false),
        Currency(code: "GYD", name: "Guyanese Dollar", popular: false),
        Currency(code: "PYG", name: "Paraguayan Guaraní", popular: false),
        Currency(code: "UYU", name: "Uruguayan Peso", popular: false),
        Currency(code: "BOB", name: "Bolivian Boliviano", popular: false),
        Currency(code: "VES", name: "Venezuelan Bolívar", popular: false)
    ]
    
    var filteredCurrencies: [Currency] {
        currencies.filter { currency in
            let matchesSearch = searchQuery.isEmpty ||
                currency.code.lowercased().contains(searchQuery.lowercased()) ||
                currency.name.lowercased().contains(searchQuery.lowercased())
            let showPopular = !showAllCurrencies ? currency.popular : true
            return matchesSearch && showPopular
        }
    }
    
    var filteredAcceptCurrencies: [Currency] {
        currencies.filter { currency in
            let matchesSearch = searchQueryAccept.isEmpty ||
                currency.code.lowercased().contains(searchQueryAccept.lowercased()) ||
                currency.name.lowercased().contains(searchQueryAccept.lowercased())
            let showPopular = !showAllAcceptCurrencies ? currency.popular : true
            let notSameCurrency = currency.code != selectedCurrency?.code
            return matchesSearch && showPopular && notSameCurrency
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading listing...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Header
                    headerView
                    
                    // Progress indicator
                    progressView
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 0) {
                            if let errorMessage = errorMessage, showError {
                                errorBanner(errorMessage)
                            }
                            
                            if currentStep == 1 {
                                step1View
                            } else if currentStep == 2 {
                                step2View
                            } else if currentStep == 3 {
                                step3View
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 100)
                    }
                    
                    Spacer()
                    
                    // Footer actions
                    footerView
                    
                    // Delete section
                    deleteSectionView
                }
            }
            .background(Color(hex: "f8fafc"))
            .navigationBarHidden(true)
            .alert("Delete Listing", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive, action: confirmDelete)
            } message: {
                Text("Are you sure you want to delete this listing? This action cannot be undone.")
            }
        .onAppear {
            ExchangeRatesAPI.shared.refreshRatesIfNeeded()
            loadListingData()
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("Edit Listing")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Progress View
    var progressView: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "e2e8f0"))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "718096"))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "e2e8f0"))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Error Banner
    func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Text("⚠️")
                .font(.system(size: 20))
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "c53030"))
            
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "fed7d7"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "feb2b2"), lineWidth: 1)
        )
        .cornerRadius(8)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Step Views (reusing CreateListingView components)
    var step1View: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 8) {
                Text("What currency do you have?")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text("Select the currency you want to exchange")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "718096"))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Currency You Have
            VStack(alignment: .leading, spacing: 8) {
                Text("Currency You Have")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                if selectedCurrency == nil {
                    currencySearchField(searchQuery: $searchQuery)
                    currencyGrid(currencies: filteredCurrencies, onSelect: { currency in
                        selectedCurrency = currency
                        searchQuery = ""
                        if selectedAcceptCurrency?.code == currency.code {
                            selectedAcceptCurrency = nil
                        }
                    })
                    
                    if !showAllCurrencies {
                        Button(action: { showAllCurrencies = true }) {
                            Text("Show More Currencies")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "667eea"))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(hex: "cbd5e0"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                        }
                    }
                } else {
                    selectedCurrencyView(currency: selectedCurrency!, onClear: {
                        selectedCurrency = nil
                    })
                }
                
                if let error = fieldErrors["currency"] {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "e53e3e"))
                }
            }
            
            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount You Have")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                HStack {
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16))
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(fieldErrors["amount"] != nil ? Color(hex: "e53e3e") : Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                    
                    Text(selectedCurrency?.code ?? "Currency")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "718096"))
                        .padding(.leading, 8)
                }
                
                if let error = fieldErrors["amount"] {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "e53e3e"))
                } else {
                    Text("How much of this currency do you have available?")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a0aec0"))
                }
            }
            
            // Accept Currency
            VStack(alignment: .leading, spacing: 8) {
                Text("What currency will you accept?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                if selectedAcceptCurrency == nil {
                    currencySearchField(searchQuery: $searchQueryAccept)
                    currencyGrid(currencies: filteredAcceptCurrencies, onSelect: { currency in
                        selectedAcceptCurrency = currency
                        searchQueryAccept = ""
                    })
                    
                    if !showAllAcceptCurrencies {
                        Button(action: { showAllAcceptCurrencies = true }) {
                            Text("Show all currencies")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "667eea"))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color(hex: "cbd5e0"), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                        }
                    }
                } else {
                    selectedCurrencyView(currency: selectedAcceptCurrency!, onClear: {
                        selectedAcceptCurrency = nil
                    })
                    
                    if let from = selectedCurrency, let to = selectedAcceptCurrency, !amount.isEmpty {
                        exchangePreview(from: from, to: to, amount: amount)
                    }
                }
                
                Text("Select the currency you're willing to accept in exchange")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "a0aec0"))
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 2: Location and Preferences
    var step2View: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 8) {
                Text("Where can you meet?")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text("Update your meeting preferences")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "718096"))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Location (always detected for editing)
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Location")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                locationDetectedView
                
                Text("Your exact location stays private - others see general area only")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "a0aec0"))
            }
            
            // Distance Radius
            VStack(alignment: .leading, spacing: 8) {
                Text("Meeting Distance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Menu {
                    ForEach(locationRadiusOptions, id: \.0) { option in
                        Button(action: {
                            locationRadius = option.0
                        }) {
                            Text(option.1)
                        }
                    }
                } label: {
                    HStack {
                        Text(locationRadiusOptions.first(where: { $0.0 == locationRadius })?.1 ?? "Within 5 miles")
                            .foregroundColor(Color(hex: "2d3748"))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color(hex: "718096"))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                }
                
                Text("How far are you willing to travel to meet?")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "a0aec0"))
            }
            
            // Meeting Preference
            VStack(alignment: .leading, spacing: 8) {
                Text("Meeting Preference")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                VStack(spacing: 12) {
                    Button(action: {
                        meetingPreference = "public"
                    }) {
                        HStack {
                            Image(systemName: meetingPreference == "public" ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(meetingPreference == "public" ? Color(hex: "667eea") : Color(hex: "cbd5e0"))
                            
                            Text("Public places only (Recommended)")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "4a5568"))
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(meetingPreference == "public" ? Color(hex: "667eea") : Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                    }
                    
                    Button(action: {
                        meetingPreference = "flexible"
                    }) {
                        HStack {
                            Image(systemName: meetingPreference == "flexible" ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(meetingPreference == "flexible" ? Color(hex: "667eea") : Color(hex: "cbd5e0"))
                            
                            Text("Flexible meeting locations")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "4a5568"))
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(meetingPreference == "flexible" ? Color(hex: "667eea") : Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                    }
                }
            }
            
            // Available Until
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Until")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                DatePicker("", selection: $availableUntil, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(fieldErrors["availableUntil"] != nil ? Color(hex: "e53e3e") : Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                
                if let error = fieldErrors["availableUntil"] {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "e53e3e"))
                } else {
                    Text("When should this listing expire?")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a0aec0"))
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Step 3: Review
    var step3View: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 8) {
                Text("Review your changes")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text("Make sure everything looks correct")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "718096"))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            // Listing Preview
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        if let currency = selectedCurrency {
                            Image(currency.code.lowercased())
                                .resizable()
                                .frame(width: 28, height: 21)
                                .cornerRadius(3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                                )
                        }
                        
                        Text("\(amount) \(selectedCurrency?.code ?? "")")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                    }
                    
                    if let from = selectedCurrency, let to = selectedAcceptCurrency {
                        Text("Market Rate → \(calculateReceiveAmount(from: from.code, to: to.code, amount: amount)) \(to.code)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "667eea"))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
                .overlay(
                    Rectangle()
                        .fill(Color(hex: "e2e8f0"))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Meeting Distance:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Spacer()
                        
                        Text("Within \(locationRadius) miles")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                    
                    HStack {
                        Text("Meeting:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Spacer()
                        
                        Text(meetingPreference == "public" ? "Public places only" : "Flexible locations")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                    
                    HStack {
                        Text("Available until:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Spacer()
                        
                        Text(availableUntil, style: .date)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
            )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Footer View
    var footerView: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                Button(action: prevStep) {
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "4a5568"))
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color(hex: "e2e8f0"))
                        .cornerRadius(12)
                }
            }
            
            if currentStep < totalSteps {
                Button(action: nextStep) {
                    Text("Next")
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
                        .shadow(color: Color(hex: "667eea").opacity(0.3), radius: 15, x: 0, y: 4)
                }
            } else {
                Button(action: handleSubmit) {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Updating...")
                        } else {
                            Text("Update Listing")
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
                    .shadow(color: Color(hex: "667eea").opacity(0.3), radius: 15, x: 0, y: 4)
                }
                .disabled(isSubmitting)
                .opacity(isSubmitting ? 0.7 : 1.0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: "e2e8f0"))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Delete Section
    var deleteSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Danger Zone")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "c53030"))
                
                Text("Once you delete this listing, there is no going back. Please be certain.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "718096"))
                    .lineSpacing(4)
            }
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 8) {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Deleting...")
                    } else {
                        Text("Delete This Listing")
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color(hex: "e53e3e"))
                .cornerRadius(8)
            }
            .disabled(isDeleting)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "fed7d7"), lineWidth: 2)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Helper Views (reusing from CreateListingView)
    func currencySearchField(searchQuery: Binding<String>) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "a0aec0"))
                .padding(.leading, 16)
            
            TextField("Search currencies...", text: searchQuery)
                .font(.system(size: 16))
                .padding(.vertical, 14)
                .padding(.trailing, 16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
        )
    }
    
    func currencyGrid(currencies: [Currency], onSelect: @escaping (Currency) -> Void) -> some View {
        VStack(spacing: 12) {
            ForEach(currencies) { currency in
                Button(action: {
                    onSelect(currency)
                }) {
                    HStack(spacing: 16) {
                        Image(currency.code.lowercased())
                            .resizable()
                            .frame(width: 24, height: 18)
                            .cornerRadius(2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "2d3748"))
                            
                            Text(currency.name)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "718096"))
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                }
            }
        }
    }
    
    func selectedCurrencyView(currency: Currency, onClear: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(currency.code.lowercased())
                .resizable()
                .frame(width: 24, height: 18)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                )
            
            Text(currency.code)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(currency.name)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "718096"))
            
            Spacer()
            
            Button(action: onClear) {
                Text("Change")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "667eea"))
                    .underline()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "667eea"), lineWidth: 2)
        )
    }
    
    func exchangePreview(from: Currency, to: Currency, amount: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text("\(amount) \(from.code)")
                    .font(.system(size: 18, weight: .bold))
                
                Text("→")
                    .font(.system(size: 20))
                    .opacity(0.8)
                
                Text("\(calculateReceiveAmount(from: from.code, to: to.code, amount: amount)) \(to.code)")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            
            Text("Amount you'll receive (at market rate)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
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
    
    var locationDetectedView: some View {
        HStack(spacing: 12) {
            Text("✅")
                .font(.system(size: 20))
            
            Text("Location detected")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "276749"))
            
            Spacer()
            
            Button(action: handleUpdateLocation) {
                Text("Update")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "667eea"))
                    .underline()
            }
        }
        .padding(16)
        .background(Color(hex: "f0fff4"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "9ae6b4"), lineWidth: 1)
        )
    }
    
    // MARK: - Functions
    func goBack() {
        dismiss()
    }
    
    func nextStep() {
        if validateCurrentStep() {
            currentStep += 1
        }
    }
    
    func prevStep() {
        currentStep -= 1
        fieldErrors = [:]
    }
    
    func validateCurrentStep() -> Bool {
        fieldErrors = [:]
        
        if currentStep == 1 {
            if selectedCurrency == nil {
                fieldErrors["currency"] = "Please select a currency"
                return false
            }
            if amount.isEmpty || Int(amount) ?? 0 <= 0 {
                fieldErrors["amount"] = "Please enter a valid amount"
                return false
            }
            if selectedAcceptCurrency == nil {
                fieldErrors["acceptCurrency"] = "Please select what currency you will accept"
                return false
            }
        } else if currentStep == 2 {
            if locationStatus != .detected {
                fieldErrors["location"] = "Please detect your location first"
                return false
            }
        }
        
        return true
    }
    
    func handleUpdateLocation() {
        locationStatus = .detecting
        locationManager.requestLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let coordinate = locationManager.location?.coordinate {
                location = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            } else {
                location = "37.7749, -122.4194"
            }
            locationStatus = .detected
        }
    }
    
    func calculateReceiveAmount(from: String, to: String, amount: String) -> String {
        guard let amountValue = Double(amount) else { return "0" }
        
        let rates: [String: Double] = [
            "USD": 1.0, "EUR": 0.85, "GBP": 0.73, "JPY": 110.0,
            "CAD": 1.25, "AUD": 1.35, "CHF": 0.92, "CNY": 6.45,
            "SEK": 8.5, "NZD": 1.4, "MXN": 20.0, "BRL": 5.3
        ]
        
        let fromRate = rates[from] ?? 1.0
        let toRate = rates[to] ?? 1.0
        let usdAmount = amountValue / fromRate
        let targetAmount = usdAmount * toRate
        
        return String(Int(targetAmount.rounded()))
    }
    
    func loadListingData() {
        guard SessionManager.shared.sessionId != nil else {
            errorMessage = "Session not found"
            showError = true
            isLoading = false
            return
        }
        
        // In a real app, fetch listing data from API
        // For now, using mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Mock data population
            selectedCurrency = currencies.first { $0.code == "USD" }
            amount = "500"
            selectedAcceptCurrency = currencies.first { $0.code == "EUR" }
            location = "37.7749, -122.4194"
            locationRadius = "5"
            meetingPreference = "public"
            availableUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            
            isLoading = false
        }
    }
    
    func handleSubmit() {
        guard validateCurrentStep() else { return }
        
        isSubmitting = true
        fieldErrors = [:]
        showError = false
        
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "You must be logged in to update this listing"
            showError = true
            isSubmitting = false
            return
        }
        
        guard let haveCurrency = selectedCurrency,
              let acceptCurrency = selectedAcceptCurrency else {
            isSubmitting = false
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let availableUntilString = dateFormatter.string(from: availableUntil)
        
        // Extract lat/lng from location string
        let locationParts = location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let latitude = locationParts.count > 0 ? locationParts[0] : ""
        let longitude = locationParts.count > 1 ? locationParts[1] : ""
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Listings/UpdateListing")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(listingId)),
            URLQueryItem(name: "currency", value: haveCurrency.code),
            URLQueryItem(name: "amount", value: amount),
            URLQueryItem(name: "acceptCurrency", value: acceptCurrency.code),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "latitude", value: latitude),
            URLQueryItem(name: "longitude", value: longitude),
            URLQueryItem(name: "locationRadius", value: locationRadius),
            URLQueryItem(name: "meetingPreference", value: meetingPreference),
            URLQueryItem(name: "availableUntil", value: availableUntilString)
        ]
        
        guard let url = components.url else {
            errorMessage = "Invalid URL"
            showError = true
            isSubmitting = false
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No response from server"
                    showError = true
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        dismiss()
                    } else {
                        errorMessage = json["error"] as? String ?? "Failed to update listing"
                        showError = true
                    }
                } else {
                    errorMessage = "Invalid response from server"
                    showError = true
                }
            }
        }.resume()
    }
    
    func confirmDelete() {
        isDeleting = true
        
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "Session not found"
            showError = true
            isDeleting = false
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Listings/DeleteListing")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(listingId)),
            URLQueryItem(name: "permanent", value: "true")
        ]
        
        guard let url = components.url else {
            errorMessage = "Invalid URL"
            showError = true
            isDeleting = false
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isDeleting = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No response from server"
                    showError = true
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        dismiss()
                    } else {
                        errorMessage = json["error"] as? String ?? "Failed to delete listing"
                        showError = true
                    }
                } else {
                    errorMessage = "Invalid response from server"
                    showError = true
                }
            }
        }.resume()
    }
}

extension EditListingView {
    func refreshExchangeRates() {
        ExchangeRatesAPI.shared.refreshRatesIfNeeded()
    }
}

#Preview {
    EditListingView(listingId: "1")
}
