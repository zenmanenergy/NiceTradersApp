//
//  ExchangeHistoryView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct Exchange: Identifiable, Codable {
    let id: String
    let date: String
    let currency: String
    let amount: Int
    let partner: String
    let rating: Int
    let type: String
    let status: String
}

struct ExchangeFilters {
    var type: String = "all"
    var currency: String = "all"
    var status: String = "all"
    var timeframe: String = "all"
}

struct ExchangeHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exchangeHistory: [Exchange] = []
    @State private var filteredHistory: [Exchange] = []
    @State private var isLoading = true
    @State private var filters = ExchangeFilters()
    @State private var availableCurrencies: [String] = []
    
    var totalExchanges: Int {
        exchangeHistory.count
    }
    
    var completedExchanges: Int {
        exchangeHistory.filter { $0.status == "completed" }.count
    }
    
    var boughtExchanges: Int {
        exchangeHistory.filter { $0.type == "bought" }.count
    }
    
    var soldExchanges: Int {
        exchangeHistory.filter { $0.type == "sold" }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Summary Stats
                        summarySection
                        
                        // Filters
                        filtersSection
                        
                        // History List
                        historySection
                    }
                    .padding(24)
                }
                .background(Color(hex: "f8fafc"))
        }
        .navigationBarHidden(true)
        .onAppear {
            loadExchangeHistory()
        }
        .onChange(of: filters.type) { filterHistory() }
        .onChange(of: filters.currency) { filterHistory() }
        .onChange(of: filters.status) { filterHistory() }
        .onChange(of: filters.timeframe) { filterHistory() }
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
            
            Text("Exchange History")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Spacer to balance layout
            Color.clear
                .frame(width: 40, height: 40)
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
    
    // MARK: - Summary Section
    var summarySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            summaryCard(number: totalExchanges, label: "Total Exchanges")
            summaryCard(number: completedExchanges, label: "Completed")
            summaryCard(number: boughtExchanges, label: "Bought")
            summaryCard(number: soldExchanges, label: "Sold")
        }
    }
    
    func summaryCard(number: Int, label: String) -> some View {
        VStack(spacing: 8) {
            Text("\(number)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "667eea"))
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "718096"))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Filters Section
    var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filter History")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
                
                Button(action: clearFilters) {
                    Text("Clear All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "667eea"))
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                filterGroup(label: "Type", selection: $filters.type) {
                    Text("All Types").tag("all")
                    Text("Bought").tag("bought")
                    Text("Sold").tag("sold")
                }
                
                filterGroup(label: "Currency", selection: $filters.currency) {
                    Text("All Currencies").tag("all")
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                
                filterGroup(label: "Status", selection: $filters.status) {
                    Text("All Status").tag("all")
                    Text("Completed").tag("completed")
                    Text("Pending").tag("pending")
                    Text("Cancelled").tag("cancelled")
                }
                
                filterGroup(label: "Timeframe", selection: $filters.timeframe) {
                    Text("All Time").tag("all")
                    Text("Last 30 Days").tag("30days")
                    Text("Last 90 Days").tag("90days")
                    Text("Last Year").tag("1year")
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    func filterGroup<Content: View>(label: String, selection: Binding<String>, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "4a5568"))
            
            Picker(label, selection: selection) {
                content()
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
            )
        }
    }
    
    // MARK: - History Section
    var historySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Exchanges (\(filteredHistory.count))")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
            }
            .padding(24)
            .background(Color.white)
            
            if isLoading {
                loadingView
            } else if filteredHistory.isEmpty {
                emptyStateView
            } else {
                historyList
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading exchange history...")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "718096"))
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("📊")
                .font(.system(size: 48))
            
            Text("No exchanges found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(exchangeHistory.isEmpty ? 
                "You haven't completed any exchanges yet." :
                "No exchanges match your current filters.")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "718096"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    var historyList: some View {
        VStack(spacing: 0) {
            ForEach(filteredHistory) { exchange in
                exchangeItem(exchange)
                
                if exchange.id != filteredHistory.last?.id {
                    Divider()
                        .padding(.leading, 80)
                }
            }
        }
    }
    
    func exchangeItem(_ exchange: Exchange) -> some View {
        Button(action: {
            // Navigate to exchange detail
        }) {
            HStack(spacing: 16) {
                // Icon
                Text(getTypeIcon(exchange.type))
                    .font(.system(size: 24))
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(exchange.currency)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "667eea"))
                            .cornerRadius(4)
                        
                        Text("\(exchange.amount)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Spacer()
                        
                        Text(exchange.status.capitalized)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getStatusColor(exchange.status))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("with \(exchange.partner)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                        
                        Spacer()
                        
                        Text(formatDate(exchange.date))
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Text("⭐")
                                .font(.system(size: 13))
                                .opacity(index < exchange.rating ? 1.0 : 0.3)
                        }
                    }
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "cbd5e0"))
            }
            .padding(24)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Functions
    func loadExchangeHistory() {
        guard let sessionId = SessionManager.shared.sessionId else {
            isLoading = false
            return
        }
        
        let url = URL(string: "\(Settings.shared.baseURL)/Profile/GetExchangeHistory?SessionId=\(sessionId)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let exchangesData = json["exchanges"] as? [[String: Any]] {
                    
                    let decoder = JSONDecoder()
                    exchangeHistory = exchangesData.compactMap { dict -> Exchange? in
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                              let exchange = try? decoder.decode(Exchange.self, from: jsonData) else {
                            return nil
                        }
                        return exchange
                    }
                    
                    filteredHistory = exchangeHistory
                    
                    // Extract unique currencies
                    availableCurrencies = Array(Set(exchangeHistory.map { $0.currency })).sorted()
                }
            }
        }.resume()
    }
    
    func filterHistory() {
        filteredHistory = exchangeHistory.filter { exchange in
            // Type filter
            if filters.type != "all" && exchange.type != filters.type {
                return false
            }
            
            // Currency filter
            if filters.currency != "all" && exchange.currency != filters.currency {
                return false
            }
            
            // Status filter
            if filters.status != "all" && exchange.status != filters.status {
                return false
            }
            
            // Timeframe filter
            if filters.timeframe != "all" {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                guard let exchangeDate = formatter.date(from: exchange.date) else {
                    return true
                }
                
                let now = Date()
                let daysDiff = Calendar.current.dateComponents([.day], from: exchangeDate, to: now).day ?? 0
                
                switch filters.timeframe {
                case "30days":
                    if daysDiff > 30 { return false }
                case "90days":
                    if daysDiff > 90 { return false }
                case "1year":
                    if daysDiff > 365 { return false }
                default:
                    break
                }
            }
            
            return true
        }
    }
    
    func clearFilters() {
        filters = ExchangeFilters()
        filterHistory()
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func getStatusColor(_ status: String) -> Color {
        switch status {
        case "completed":
            return Color(hex: "10b981")
        case "pending":
            return Color(hex: "f59e0b")
        case "cancelled":
            return Color(hex: "ef4444")
        default:
            return Color(hex: "6b7280")
        }
    }
    
    func getTypeIcon(_ type: String) -> String {
        return type == "bought" ? "📥" : "📤"
    }
}

#Preview {
    ExchangeHistoryView()
}
