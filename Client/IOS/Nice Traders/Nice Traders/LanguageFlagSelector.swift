//
//  LanguageFlagSelector.swift
//  Nice Traders
//
//  A compact language selector button with flag emoji in the corner
//  Shows dropdown menu with language options
//

import SwiftUI

struct LanguageFlagSelector: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var isLoading = false
    @State private var showingPicker = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Button(action: {
                    showingPicker.toggle()
                }) {
                    HStack(spacing: 4) {
                        Text(flagForLanguage(localizationManager.currentLanguage))
                            .font(.title2)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .background(Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .frame(width: 50, height: 50)
            
            if showingPicker {
                VStack(spacing: 8) {
                    ForEach(sortedLanguages(), id: \.code) { language in
                        Button(action: {
                            selectLanguage(language.code)
                            showingPicker = false
                        }) {
                            HStack(spacing: 12) {
                                Text(language.flag)
                                    .font(.title2)
                                
                                Text(language.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                                
                                Spacer()
                                
                                if localizationManager.currentLanguage == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .border(Color(red: 0.4, green: 0.49, blue: 0.92), width: 1)
                .cornerRadius(8)
                .offset(y: 60)
            }
        }
    }
    
    private func selectLanguage(_ languageCode: String) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            localizationManager.currentLanguage = languageCode
            isLoading = false
        }
    }
    
    private func flagForLanguage(_ languageCode: String) -> String {
        let flags: [String: String] = [
            "en": "🇬🇧",
            "es": "🇪🇸",
            "fr": "🇫🇷",
            "de": "🇩🇪",
            "pt": "🇵🇹",
            "ja": "🇯🇵",
            "zh": "🇨🇳",
            "ru": "🇷🇺",
            "ar": "🇸🇦",
            "hi": "🇮🇳",
            "sk": "🇸🇰"
        ]
        return flags[languageCode] ?? "🌐"
    }
    
    private func languageNameForCode(_ languageCode: String) -> String {
        let languages: [String: String] = [
            "en": "English",
            "es": "Español",
            "fr": "Français",
            "de": "Deutsch",
            "pt": "Português",
            "ja": "日本語",
            "zh": "中文",
            "ru": "Русский",
            "ar": "العربية",
            "hi": "हिन्दी",
            "sk": "Slovenčina"
        ]
        return languages[languageCode] ?? "Language"
    }
    
    private func sortedLanguages() -> [(code: String, displayName: String, flag: String)] {
        let languages: [(code: String, displayName: String, flag: String)] = [
            ("en", "English", "🇬🇧"),
            ("es", "Español", "🇪🇸"),
            ("fr", "Français", "🇫🇷"),
            ("de", "Deutsch", "🇩🇪"),
            ("pt", "Português", "🇵🇹"),
            ("ja", "日本語", "🇯🇵"),
            ("zh", "中文", "🇨🇳"),
            ("ru", "Русский", "🇷🇺"),
            ("ar", "العربية", "🇸🇦"),
            ("hi", "हिन्दी", "🇮🇳"),
            ("sk", "Slovenčina", "🇸🇰")
        ]
        return languages.sorted { $0.displayName < $1.displayName }
    }
}

#Preview {
    ZStack {
        Color.white
        
        VStack {
            HStack {
                Spacer()
                LanguageFlagSelector()
                    .padding()
            }
            Spacer()
        }
    }
}
