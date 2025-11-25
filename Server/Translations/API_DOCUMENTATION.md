# Translations API Documentation

## Overview
The Translations API provides endpoints for managing application translations stored in a MySQL database. It supports multi-language support with timestamp-based cache invalidation for client-side caching.

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
- **en** (English)
- **es** (Spanish)
- **fr** (French)
- **de** (German)
- **pt** (Portuguese)
- **ja** (Japanese)
- **zh** (Chinese)
- **ru** (Russian)
- **ar** (Arabic)
- **hi** (Hindi)
- **sk** (Slovak)

## API Endpoints

### 1. GET /Translations/GetTranslations
Get all translations for a specific language.

**Parameters:**
- `language` (query, required): Language code (e.g., 'en', 'es', 'fr')
  - Default: 'en'

**Response:**
```json
{
  "success": true,
  "language": "en",
  "translations": {
    "auth_login": "Login",
    "auth_signup": "Sign Up",
    "auth_email": "Email",
    ...
  },
  "last_updated": "2024-01-15T10:30:45.123456",
  "count": 176
}
```

**HTTP Status:**
- 200: Success
- 404: Language not found
- 500: Server error

---

### 2. GET /Translations/GetLastUpdated
Get the last update timestamp for all languages. Useful for checking if cached translations need to be refreshed.

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "last_updated": {
    "en": "2024-01-15T10:30:45.123456",
    "es": "2024-01-14T15:22:10.654321",
    "fr": "2024-01-12T08:15:30.987654",
    ...
  }
}
```

**HTTP Status:**
- 200: Success
- 500: Server error

---

### 3. GET /Admin/Translations/GetLanguages
Get list of all supported languages.

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "languages": ["ar", "de", "en", "es", "fr", "hi", "ja", "pt", "ru", "sk", "zh"],
  "count": 11
}
```

**HTTP Status:**
- 200: Success
- 500: Server error

---

### 4. GET /Admin/Translations/GetTranslationKeys
Get list of all translation keys.

**Parameters:** None

**Response:**
```json
{
  "success": true,
  "keys": [
    "auth_confirm_password",
    "auth_email",
    "auth_email_exists",
    ...
  ],
  "count": 176
}
```

**HTTP Status:**
- 200: Success
- 500: Server error

---

### 5. GET /Admin/Translations/GetTranslationsByKey
Get translations for a specific key across all languages.

**Parameters:**
- `key` (query, required): Translation key name

**Response:**
```json
{
  "success": true,
  "translation_key": "auth_login",
  "translations": {
    "en": {
      "value": "Login",
      "updated_at": "2024-01-15T10:30:45"
    },
    "es": {
      "value": "Iniciar sesión",
      "updated_at": "2024-01-14T15:22:10"
    },
    ...
  }
}
```

**HTTP Status:**
- 200: Success
- 400: Missing required parameter
- 404: Key not found
- 500: Server error

---

### 6. POST /Admin/Translations/UpdateTranslation
Update a single translation.

**Request Body:**
```json
{
  "translation_key": "auth_login",
  "language_code": "en",
  "translation_value": "Sign In"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Translation updated successfully",
  "translation_key": "auth_login",
  "language_code": "en"
}
```

**HTTP Status:**
- 200: Success
- 400: Missing required fields
- 500: Server error

---

### 7. POST /Admin/Translations/BulkUpdateTranslations
Update multiple translations for a language in a single request.

**Request Body:**
```json
{
  "language_code": "es",
  "translations": {
    "auth_login": "Iniciar sesión",
    "auth_signup": "Registrarse",
    "auth_email": "Correo electrónico",
    ...
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Updated 3 translations",
  "language_code": "es",
  "updated_count": 3
}
```

**HTTP Status:**
- 200: Success
- 400: Missing required fields
- 500: Server error

---

### 8. DELETE /Admin/Translations/DeleteTranslation
Delete a translation.

**Parameters:**
- `key` (query, required): Translation key
- `language` (query, required): Language code

**Response:**
```json
{
  "success": true,
  "message": "Translation deleted successfully"
}
```

**HTTP Status:**
- 200: Success
- 400: Missing required parameters
- 404: Translation not found
- 500: Server error

---

## Usage Examples

### iOS Client: Fetch and Cache Translations
```swift
// 1. Check if translations need update
let lastUpdated = UserDefaults.standard.object(forKey: "translations_updated_at") as? String

// 2. Fetch last updated from server
let response = await fetch("/Translations/GetLastUpdated")
let serverLastUpdated = response.last_updated["en"]

// 3. If server is newer, download full translations
if serverLastUpdated > lastUpdated {
    let translationsResponse = await fetch("/Translations/GetTranslations?language=en")
    let translations = translationsResponse.translations
    
    // 4. Cache locally
    UserDefaults.standard.set(translations, forKey: "translations")
    UserDefaults.standard.set(serverLastUpdated, forKey: "translations_updated_at")
}

// 5. Use cached translations
let translation = UserDefaults.standard.dictionary(forKey: "translations")?["auth_login"] ?? "Login"
```

### Admin: Update a Translation
```bash
curl -X POST http://localhost:5000/Admin/Translations/UpdateTranslation \
  -H "Content-Type: application/json" \
  -d '{
    "translation_key": "auth_login",
    "language_code": "en",
    "translation_value": "Sign In"
  }'
```

### Admin: Bulk Update Spanish Translations
```bash
curl -X POST http://localhost:5000/Admin/Translations/BulkUpdateTranslations \
  -H "Content-Type: application/json" \
  -d '{
    "language_code": "es",
    "translations": {
      "auth_login": "Iniciar sesión",
      "auth_signup": "Registrarse",
      "auth_email": "Correo electrónico"
    }
  }'
```

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description"
}
```

The message field contains human-readable error details for debugging.

## Implementation Notes

1. **Timestamps**: All `updated_at` timestamps are in ISO 8601 format with milliseconds
2. **Caching**: Clients should use the `GetLastUpdated` endpoint to check if cached translations are stale
3. **Idempotency**: `UpdateTranslation` uses `ON DUPLICATE KEY UPDATE`, so it's safe to call multiple times
4. **Performance**: Database indexes on `language_code` and `updated_at` optimize query performance
5. **Data Integrity**: UNIQUE constraint on (translation_key, language_code) prevents duplicate entries

## Future Enhancements

1. **Authentication**: Add admin authentication to protect write operations
2. **Pagination**: Add pagination for large translation sets
3. **Search**: Add search functionality for translation keys/values
4. **History**: Track translation change history
5. **Audit Logging**: Log all translation modifications with user info
