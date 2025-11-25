# iOS Translation Integration Guide

This guide explains how to integrate the backend translation system with the iOS app.

## Overview

The translation system uses a 3-step approach:
1. **Server**: Database stores all translations by key/language
2. **Network**: iOS fetches translations and checks for updates
3. **Client**: iOS caches translations locally with timestamp-based invalidation

## Implementation Steps

### Step 1: Update LocalizationManager.swift

Replace the hardcoded dictionaries with API calls:

```swift
import Foundation

class TranslationManager {
    static let shared = TranslationManager()
    
    private var translations: [String: String] = [:]
    private var currentLanguage: String = "en"
    private let baseURL = "http://your-server.com"  // TODO: Configure
    
    // MARK: - Initialization
    
    func initialize(language: String) async {
        self.currentLanguage = language
        
        // Try to load from cache first
        if let cached = loadFromCache(language: language) {
            self.translations = cached
            
            // But check if server has newer data
            await checkForUpdates(language: language)
        } else {
            // No cache, download from server
            await downloadTranslations(language: language)
        }
    }
    
    // MARK: - Public API
    
    func get(_ key: String) -> String {
        return translations[key] ?? key
    }
    
    func changeLanguage(to language: String) async {
        self.currentLanguage = language
        await initialize(language: language)
    }
    
    // MARK: - Server Communication
    
    private func downloadTranslations(language: String) async {
        let endpoint = "\(baseURL)/Translations/GetTranslations"
        let url = URL(string: "\(endpoint)?language=\(language)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(TranslationsResponse.self, from: data)
            
            if response.success {
                self.translations = response.translations
                self.saveToCache(translations: response.translations, 
                               language: language, 
                               timestamp: response.last_updated)
            }
        } catch {
            print("❌ Error downloading translations: \(error)")
            // Translations will remain as-is (empty or previously cached)
        }
    }
    
    private func checkForUpdates(language: String) async {
        let endpoint = "\(baseURL)/Translations/GetLastUpdated"
        guard let url = URL(string: endpoint) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LastUpdatedResponse.self, from: data)
            
            if response.success,
               let serverTimestamp = response.last_updated[language],
               let cachedTimestamp = getCachedTimestamp(language: language) {
                
                // If server is newer, download updates
                if serverTimestamp > cachedTimestamp {
                    await downloadTranslations(language: language)
                }
            }
        } catch {
            print("⚠️ Error checking for updates: \(error)")
        }
    }
    
    // MARK: - Caching
    
    private func saveToCache(translations: [String: String], 
                            language: String, 
                            timestamp: String?) {
        let key = "translations_\(language)"
        let timestampKey = "translations_\(language)_timestamp"
        
        UserDefaults.standard.setValue(translations, forKey: key)
        UserDefaults.standard.setValue(timestamp, forKey: timestampKey)
    }
    
    private func loadFromCache(language: String) -> [String: String]? {
        let key = "translations_\(language)"
        return UserDefaults.standard.dictionary(forKey: key) as? [String: String]
    }
    
    private func getCachedTimestamp(language: String) -> String? {
        let key = "translations_\(language)_timestamp"
        return UserDefaults.standard.string(forKey: key)
    }
    
    // MARK: - Data Models
    
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
}
```

### Step 2: Update App Initialization

Update your app startup to initialize translations:

```swift
@main
struct NiceTradersApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        // Get user's preferred language
                        let preferredLanguage = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "en"
                        
                        // Initialize translation system
                        await TranslationManager.shared.initialize(language: preferredLanguage)
                    }
                }
        }
    }
}
```

### Step 3: Update Login/Signup Flow

After login/signup, refresh translations:

```swift
// In LoginView or after successful login
func handleLoginSuccess(language: String) async {
    // Store preferred language
    UserDefaults.standard.set(language, forKey: "preferredLanguage")
    
    // Refresh translations
    await TranslationManager.shared.initialize(language: language)
}
```

### Step 4: Update Views

Replace text literals with translation calls:

```swift
// Before:
Text("Login")

// After:
Text(TranslationManager.shared.get("auth_login"))
```

Or create a helper extension:

```swift
extension View {
    func localized(_ key: String) -> String {
        TranslationManager.shared.get(key)
    }
}

// Usage:
Text(String(localized: "auth_login"))  // Using the extension
```

### Step 5: Implement Language Selector

In Settings or Profile view:

```swift
struct LanguageSettingsView: View {
    @State private var selectedLanguage = "en"
    let languages = ["en", "es", "fr", "de", "pt", "ja", "zh", "ru", "ar", "hi", "sk"]
    
    var body: some View {
        Picker("Language", selection: $selectedLanguage) {
            ForEach(languages, id: \.self) { lang in
                Text(getLanguageName(lang)).tag(lang)
            }
        }
        .onChange(of: selectedLanguage) { newLanguage in
            Task {
                // Save preference
                UserDefaults.standard.set(newLanguage, forKey: "preferredLanguage")
                
                // Update translations
                await TranslationManager.shared.changeLanguage(to: newLanguage)
            }
        }
    }
    
    func getLanguageName(_ code: String) -> String {
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: .identifier, value: code) ?? code
    }
}
```

## Translation Keys

All 176 translation keys are available. Here are some examples:

### Authentication
- `auth_login` → "Login"
- `auth_signup` → "Sign Up"
- `auth_email` → "Email"
- `auth_password` → "Password"
- `auth_forgot_password` → "Forgot Password?"

### Listings
- `listing_title` → "Title"
- `listing_description` → "Description"
- `listing_price` → "Price"
- `listing_category` → "Category"

### Dashboard
- `dashboard_title` → "Dashboard"
- `dashboard_recent_listings` → "Recent Listings"
- `dashboard_messages` → "Messages"

See `API_DOCUMENTATION.md` for the complete list of translation keys.

## API Endpoints Used

### 1. GET /Translations/GetTranslations
```
GET http://your-server.com/Translations/GetTranslations?language=en

Response:
{
  "success": true,
  "language": "en",
  "translations": { ... },
  "last_updated": "2024-01-15T10:30:45.123456",
  "count": 176
}
```

### 2. GET /Translations/GetLastUpdated
```
GET http://your-server.com/Translations/GetLastUpdated

Response:
{
  "success": true,
  "last_updated": {
    "en": "2024-01-15T10:30:45.123456",
    "es": "2024-01-14T15:22:10.654321",
    ...
  }
}
```

## Caching Strategy

The implementation uses a smart caching strategy:

1. **On First Launch**: Downloads all translations for selected language
2. **On Subsequent Launches**: 
   - Loads cached translations immediately (fast)
   - Checks server in background for updates
   - Downloads if server timestamp is newer

3. **On Language Change**: Downloads new language's translations

## Error Handling

The implementation gracefully handles network errors:

```swift
// If server is unreachable:
// - Uses cached translations if available
// - Falls back to showing the translation key itself
// - No crash or error UI shown

// Example:
if let cached = loadFromCache(language: language) {
    self.translations = cached
} else {
    // Start with empty dict, populate when network returns
    self.translations = [:]
}

// User sees key name if translation can't be fetched:
Text(get("missing_translation_key"))  // Shows: "missing_translation_key"
```

## Performance Tips

1. **Lazy Load**: Initialize translations asynchronously, don't block UI
2. **Cache Aggressively**: Use local cache on every app launch
3. **Check Updates Async**: Verify server updates in background
4. **Batch Updates**: Use bulk update endpoint for large translation changes
5. **Minimize Network**: Only download if timestamp differs

## Testing

Test with mock data before integrating with real server:

```swift
#if DEBUG
let mockTranslations: [String: String] = [
    "auth_login": "Login",
    "auth_signup": "Sign Up",
    // ...
]
#endif
```

## Debugging

Enable debug logging:

```swift
// Add to TranslationManager
let debugEnabled = true

private func log(_ message: String) {
    if debugEnabled {
        print("🌐 [TranslationManager] \(message)")
    }
}
```

## Next Steps

1. ✅ Backend API endpoints are ready (see `/Translations` routes)
2. ⏳ Implement TranslationManager in iOS
3. ⏳ Update all views to use translations
4. ⏳ Test on device with different languages
5. ⏳ Add authentic translations for non-English languages

## Related Documentation

- `API_DOCUMENTATION.md` - Complete API reference
- `README.md` - Translations module overview
- `/Admin/Translations/*` - Admin endpoints for managing translations

## Support

If you encounter issues:
1. Check server logs: `python3 flask_app.py`
2. Verify database connection: `SELECT COUNT(*) FROM translations;`
3. Test endpoint directly: `curl http://localhost:5000/Translations/GetTranslations?language=en`
4. Check Xcode console for network errors
