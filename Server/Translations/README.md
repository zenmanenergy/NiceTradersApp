# Translations Module

This module manages multi-language translations for the Nice Traders application using a MySQL database backend.

## Architecture Overview

### Database-Driven Translation System
Instead of hardcoding translations in the app, this system stores all translations in a MySQL database. This allows:
- **No recompilation needed** to add/update translations
- **Easy language addition** without code changes
- **Efficient caching** with timestamp-based invalidation
- **Admin management** of translations via API endpoints
- **Scalability** to support many more languages in the future

### Components

#### 1. Database (`translations` table)
- Stores translation key-value pairs for 11 languages
- Uses timestamp-based cache invalidation
- Enforces uniqueness on (translation_key, language_code)
- Optimized with indexes on language_code and updated_at

#### 2. Backend API (`Translations.py` and `AdminTranslations.py`)
- **Public endpoints** (in `Translations.py`):
  - `/Translations/GetTranslations` - Fetch all translations for a language
  - `/Translations/GetLastUpdated` - Fetch update timestamps for cache checking

- **Admin endpoints** (in `AdminTranslations.py`):
  - `/Admin/Translations/GetLanguages` - List all supported languages
  - `/Admin/Translations/GetTranslationKeys` - List all translation keys
  - `/Admin/Translations/GetTranslationsByKey` - Get a key across all languages
  - `/Admin/Translations/UpdateTranslation` - Update a single translation
  - `/Admin/Translations/BulkUpdateTranslations` - Update multiple translations
  - `/Admin/Translations/DeleteTranslation` - Delete a translation

#### 3. iOS Client (Future Implementation)
The iOS app will:
1. Fetch translations on app startup
2. Check server for updates on each app launch
3. Cache translations locally with timestamp
4. Only download if server is newer
5. Fallback to English if translation missing

## Current Status

### ✅ Completed
- Database schema created and verified
- Migration scripts executed successfully
- All 176 translation keys × 11 languages migrated to database
- Backend API endpoints implemented
- Flask app configured with blueprints
- API documentation written

### ⏳ In Progress
- iOS LocalizationManager refactoring (to fetch from server)
- Caching mechanism in iOS (UserDefaults)
- Sync logic with timestamp checking

### 📝 Remaining
- Complete authentic translations for non-English languages (currently using English as placeholders)
- iOS implementation of translation sync
- Admin UI/Dashboard for managing translations
- Add authentication to admin endpoints
- Complete CreateListingView and EditListingView localization

## Translation Keys (176 total)

### Authentication & Signup (18 keys)
- auth_* keys for login, signup, password reset, etc.

### Forms & Validation (25 keys)
- form_* keys for common form elements
- validation_* keys for error messages

### Listings (45 keys)
- listing_* keys for creating, editing, viewing listings
- status_* keys for listing status indicators

### Dashboard (17 keys)
- dashboard_* keys for dashboard UI elements
- stats_* keys for statistics display

### Profile & Settings (30 keys)
- profile_* keys for user profile
- settings_* keys for app settings

### Navigation (15 keys)
- nav_* keys for navigation menu items
- bottom_* keys for bottom navigation

### Messages & Notifications (20 keys)
- message_* keys for chat and messaging
- notification_* keys for push notifications

### Other UI Elements (6 keys)
- button_* keys for common buttons
- label_* keys for UI labels

## Database Schema

```sql
CREATE TABLE translations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    translation_key VARCHAR(255) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    translation_value LONGTEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_key_lang (translation_key, language_code),
    INDEX idx_language (language_code),
    INDEX idx_updated (updated_at)
);
```

## Supported Languages

| Code | Language | Status |
|------|----------|--------|
| en | English | ✅ Complete |
| es | Spanish | ⏳ Placeholder (English) |
| fr | French | ⏳ Placeholder (English) |
| de | German | ⏳ Placeholder (English) |
| pt | Portuguese | ⏳ Placeholder (English) |
| ja | Japanese | ⏳ Placeholder (English) |
| zh | Chinese | ⏳ Placeholder (English) |
| ru | Russian | ⏳ Placeholder (English) |
| ar | Arabic | ⏳ Placeholder (English) |
| hi | Hindi | ⏳ Placeholder (English) |
| sk | Slovak | ⏳ Placeholder (English) |

## API Endpoints Reference

See `API_DOCUMENTATION.md` for complete endpoint documentation.

### Quick Reference

```
GET /Translations/GetTranslations?language=en
GET /Translations/GetLastUpdated

GET /Admin/Translations/GetLanguages
GET /Admin/Translations/GetTranslationKeys
GET /Admin/Translations/GetTranslationsByKey?key=auth_login
POST /Admin/Translations/UpdateTranslation
POST /Admin/Translations/BulkUpdateTranslations
DELETE /Admin/Translations/DeleteTranslation?key=auth_login&language=en
```

## Integration with Flask

The module is integrated into Flask via `flask_app.py`:

```python
from Translations import Translations, AdminTranslations

app.register_blueprint(Translations.translations_bp)
app.register_blueprint(AdminTranslations.admin_translations_bp)
```

## Migration Scripts

### `run_migrations.py`
Executes SQL migration files to create/update database schema.

Usage:
```bash
python3 run_migrations.py
```

### `migrate_translations.py`
Migrates hardcoded translations from LocalizationManager.swift to the database.

Usage:
```bash
python3 migrate_translations.py
```

## Testing

Test script available at `test_translations_api.py`:

```bash
python3 test_translations_api.py
```

This script tests all public endpoints assuming the Flask server is running on http://localhost:5000.

## Next Steps for iOS Integration

1. **Create iOS TranslationManager**
   - Fetch translations from server
   - Cache in UserDefaults
   - Check timestamps for updates

2. **Implement Sync Logic**
   - On app startup: check server
   - On login/signup: refresh translations
   - On each app launch: verify cache freshness

3. **Update Views**
   - Replace LocalizationManager calls with new system
   - Use cached translations
   - Fallback to English on missing keys

4. **Complete Translations**
   - Fill in non-English language translations
   - Use translation management API

## Example: iOS Implementation Pattern

```swift
class TranslationManager {
    static let shared = TranslationManager()
    
    private var cachedTranslations: [String: String] = [:]
    private let userDefaults = UserDefaults.standard
    
    func initialize(language: String) async {
        // Check if cache needs update
        let lastUpdated = userDefaults.string(forKey: "translations_updated_at")
        
        // Fetch server timestamps
        let response = await fetchLastUpdated()
        let serverTime = response["last_updated"][language]
        
        // Update if needed
        if serverTime > lastUpdated {
            await downloadTranslations(for: language)
        }
        
        // Load from cache
        cachedTranslations = userDefaults.dictionary(forKey: "translations") as? [String: String] ?? [:]
    }
    
    func get(_ key: String, language: String = "en") -> String {
        return cachedTranslations[key] ?? key  // Fallback to key name
    }
}
```

## Performance Considerations

1. **Database Indexes**: Optimized for:
   - Fetching all translations for a language
   - Checking update timestamps
   - Filtering by language code

2. **Client-Side Caching**: 
   - Eliminates need to fetch on every app startup
   - Uses timestamp checking for cache invalidation
   - Falls back to English on missing translations

3. **Bulk Operations**: 
   - BulkUpdateTranslations for efficient updates
   - Reduces network requests during translation imports

## Security Notes

⚠️ **Important**: Admin endpoints should be protected with authentication before production deployment. Currently no authentication is required.

Recommended security measures:
1. Add user authentication/authorization
2. Add rate limiting to prevent abuse
3. Log all admin operations for audit trail
4. Add IP whitelisting for admin operations

## Troubleshooting

### Translations not appearing
- Verify database connection
- Check language code in request matches database (case-sensitive)
- Ensure translations table exists and has data

### Import errors
- Confirm Database.py is in _Lib directory
- Check that _Lib directory has __init__.py

### Performance issues
- Verify database indexes exist
- Check database query performance with EXPLAIN
- Consider implementing caching layer

## File Structure

```
Server/
├── Translations/
│   ├── __init__.py                    # Module initialization
│   ├── Translations.py                # Public API endpoints
│   ├── AdminTranslations.py           # Admin API endpoints
│   ├── API_DOCUMENTATION.md           # Complete API reference
│   └── README.md                      # This file
├── migrations/
│   └── create_translations_table.sql  # Database schema
├── run_migrations.py                  # Migration runner
├── migrate_translations.py            # Data migration script
└── test_translations_api.py          # API tests
```

## Related Files

- `flask_app.py` - Main Flask app (registers blueprints)
- `LocalizationManager.swift` - iOS localization manager (to be refactored)
- `database_schema.sql` - Database schema file

## Contact & Support

For questions or issues, refer to the main project README or contact the development team.
