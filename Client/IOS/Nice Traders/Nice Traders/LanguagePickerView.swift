import SwiftUI

struct LanguagePickerView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var successMessageText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current Language Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Language")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(localizationManager.supportedLanguages[localizationManager.currentLanguage] ?? "English")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Language List
                VStack(alignment: .leading, spacing: 0) {
                    Text("Select Language")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    List {
                        ForEach(sortedLanguages(), id: \.code) { language in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(language.displayName)
                                        .font(.body)
                                    Text(language.nativeName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if localizationManager.currentLanguage == language.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectLanguage(language.code)
                            }
                        }
                    }
                }
                
                // Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Label("Your language preference is automatically saved", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                
                if showSuccessMessage {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessageText)
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Methods
    
    private func sortedLanguages() -> [(code: String, displayName: String, nativeName: String)] {
        let languageData: [(code: String, displayName: String, nativeName: String)] = [
            ("en", "English", "English"),
            ("es", "Spanish", "Español"),
            ("fr", "French", "Français"),
            ("de", "German", "Deutsch"),
            ("pt", "Portuguese", "Português"),
            ("ja", "Japanese", "日本語"),
            ("zh", "Chinese", "中文"),
            ("ru", "Russian", "Русский"),
            ("ar", "Arabic", "العربية"),
            ("hi", "Hindi", "हिन्दी"),
            ("sk", "Slovak", "Slovenčina"),
        ]
        return languageData.sorted { $0.displayName < $1.displayName }
    }
    
    private func selectLanguage(_ languageCode: String) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            localizationManager.currentLanguage = languageCode
            successMessageText = "Language changed to \(localizationManager.supportedLanguages[languageCode] ?? languageCode)"
            showSuccessMessage = true
            isLoading = false
            
            // Hide success message after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSuccessMessage = false
                }
            }
        }
    }
}

#Preview {
    LanguagePickerView()
}
