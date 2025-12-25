# Localization Editor - Technical Reference

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (SvelteKit)                    │
│  ┌─────────────┬──────────────┬──────────────────────────┐  │
│  │ ViewList    │ English      │ LanguageTranslator       │  │
│  │ - Search    │ Editor       │ - 11 language cards      │  │
│  │ - View list │ - Edit value │ - Edit buttons per lang  │  │
│  │ - Key list  │ - Strategy   │ - Status indicators      │  │
│  │             │ - Save       │ - Timestamps             │  │
│  └─────────────┴──────────────┴──────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Status Tab: Validation, Coverage, Orphaned Keys      │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP REST API
┌────────────────────┴────────────────────────────────────────┐
│                  Backend (Flask Python)                     │
│  AdminTranslations.py                                       │
│  - GetViewInventory (list views/keys)                      │
│  - UpdateEnglish (cascade changes)                         │
│  - BulkUpdate (batch operations)                           │
│  - GetDetails (get translations)                           │
│  - ValidateKeys (consistency check)                        │
│  - ScanCodeForKeys (re-scan iOS)                           │
│  - GetHistory (audit trail)                                │
│  - CreateBackup (backup snapshot)                          │
│  - RollbackTranslation (restore version)                   │
│                                                             │
│  TranslationHistory.py                                      │
│  - record_translation_change()                             │
│  - get_translation_history()                               │
│  - create_backup()                                          │
│  - rollback_translation()                                  │
└────────────────────┬────────────────────────────────────────┘
                     │ PyMySQL
┌────────────────────┴────────────────────────────────────────┐
│                    MySQL Database                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ translations (extended)                              │  │
│  │ - id, translation_key, language_code, value          │  │
│  │ - updated_by, status, notes (NEW)                    │  │
│  │ - Updated_at timestamp, created_at                   │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ translation_history (NEW)                            │  │
│  │ - id, translation_key, language_code                 │  │
│  │ - old_value, new_value, changed_by, changed_at       │  │
│  │ - change_reason (UPDATE/ROLLBACK/BULK_UPDATE)        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ view_translation_keys_cache (NEW)                    │  │
│  │ - view_id, view_path, translation_keys (JSON)        │  │
│  │ - key_count, last_scanned_at                         │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ translation_backups (NEW)                            │  │
│  │ - id, backup_name, backup_data (JSON)                │  │
│  │ - created_at, created_by, record_count               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Database Schema

### translations (Modified)

```sql
CREATE TABLE translations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    translation_key VARCHAR(255) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    translation_value LONGTEXT NOT NULL,
    updated_by INT DEFAULT NULL,           -- NEW: User who updated
    status VARCHAR(50) DEFAULT 'active',   -- NEW: active/review_needed/deprecated
    notes TEXT DEFAULT NULL,               -- NEW: Context about translation
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_translation (translation_key, language_code),
    KEY idx_translation_key (translation_key),
    KEY idx_language_code (language_code),
    KEY idx_updated_at (updated_at)
);
```

### translation_history (New)

```sql
CREATE TABLE translation_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    translation_key VARCHAR(255) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    old_value LONGTEXT,
    new_value LONGTEXT NOT NULL,
    changed_by INT DEFAULT NULL,
    change_reason VARCHAR(100) DEFAULT 'MANUAL',  -- MANUAL/ROLLBACK/BULK_UPDATE
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    KEY idx_translation_key (translation_key),
    KEY idx_language_code (language_code),
    KEY idx_changed_at (changed_at)
);
```

### translation_backups (New)

```sql
CREATE TABLE translation_backups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    backup_name VARCHAR(255) NOT NULL,
    backup_data LONGTEXT NOT NULL,  -- JSON with all translations
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    record_count INT DEFAULT 0,  -- Count of translations backed up
    KEY idx_created_at (created_at),
    KEY idx_backup_name (backup_name)
);
```

### view_translation_keys_cache (New)

```sql
CREATE TABLE view_translation_keys_cache (
    id INT AUTO_INCREMENT PRIMARY KEY,
    view_id VARCHAR(255) NOT NULL,
    view_type VARCHAR(100) NOT NULL,  -- e.g., 'SwiftUI'
    view_path VARCHAR(500) NOT NULL,  -- Path to source file
    translation_keys JSON NOT NULL,   -- Array of keys used
    key_count INT DEFAULT 0,
    last_scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_view (view_id, view_path),
    KEY idx_view_type (view_type),
    KEY idx_last_scanned (last_scanned_at)
);
```

## API Endpoint Details

### 1. GetViewInventory

**Endpoint**: `GET /Admin/Translations/GetViewInventory`

**Response**:
```json
{
    "success": true,
    "data": {
        "views": [
            {
                "view_id": "auth_welcome",
                "view_name": "AuthWelcome",
                "view_path": "/Nice Traders/Views/Auth/WelcomeView.swift",
                "language": "SwiftUI",
                "key_count": 8,
                "keys": ["WELCOME_BACK", "SIGN_IN", "CREATE_ACCOUNT", ...]
            }
        ],
        "languages": ["en", "ja", "es", "fr", "de", "ar", "hi", "pt", "ru", "sk", "zh"],
        "statistics": {
            "total_views": 31,
            "total_keys": 519,
            "total_languages": 11,
            "total_translations": 5709
        }
    }
}
```

### 2. UpdateEnglish

**Endpoint**: `POST /Admin/Translations/UpdateEnglish`

**Request**:
```json
{
    "translation_key": "WELCOME_BACK",
    "english_value": "Welcome back to NiceTraders!",
    "strategy": "mark_for_review",  // "mark_for_review" or "clear_others"
    "notes": "Updated greeting message"
}
```

**Response**:
```json
{
    "success": true,
    "message": "English translation updated successfully",
    "affected_languages": 10,  // Number of other languages affected
    "history_record": {
        "id": 12345,
        "old_value": "Welcome back",
        "new_value": "Welcome back to NiceTraders!",
        "changed_at": "2025-12-25T10:30:00Z"
    }
}
```

### 3. BulkUpdate

**Endpoint**: `POST /Admin/Translations/BulkUpdate`

**Request**:
```json
{
    "updates": [
        {
            "key": "WELCOME_BACK",
            "language": "ja",
            "value": "ようこそ！"
        },
        {
            "key": "WELCOME_BACK",
            "language": "es",
            "value": "¡Bienvenido!"
        }
    ]
}
```

**Response**:
```json
{
    "success": true,
    "updates_applied": 2,
    "updates_failed": 0,
    "results": [
        {"key": "WELCOME_BACK", "language": "ja", "status": "success"},
        {"key": "WELCOME_BACK", "language": "es", "status": "success"}
    ]
}
```

### 4. GetDetails

**Endpoint**: `GET /Admin/Translations/GetDetails?key=WELCOME_BACK`

**Response**:
```json
{
    "success": true,
    "data": {
        "key": "WELCOME_BACK",
        "translations": {
            "en": {
                "value": "Welcome back!",
                "status": "active",
                "updated_at": "2025-12-25T10:30:00Z"
            },
            "ja": {
                "value": "おかえりなさい",
                "status": "active",
                "updated_at": "2025-12-24T15:20:00Z"
            }
        },
        "usage": {
            "view_count": 2,
            "views": [
                "AuthWelcome",
                "DashboardHome"
            ]
        }
    }
}
```

### 5. ValidateKeys

**Endpoint**: `POST /Admin/Translations/ValidateKeys`

**Response**:
```json
{
    "success": true,
    "validation_results": {
        "database_keys": 519,
        "code_keys": 477,
        "coverage_percentage": 91.7,
        "orphaned_keys": 161,  // In DB but not in code
        "missing_keys": 19,    // In code but not in DB
        "orphaned_examples": ["OLD_KEY_1", "OLD_KEY_2", ...],
        "missing_examples": ["NEW_KEY_1", "NEW_KEY_2", ...],
        "by_language": {
            "en": 100,
            "ja": 95,
            "es": 92
        }
    }
}
```

### 6. ScanCodeForKeys

**Endpoint**: `POST /Admin/Translations/ScanCodeForKeys`

**Response**:
```json
{
    "success": true,
    "scan_results": {
        "views_scanned": 31,
        "keys_found": 477,
        "new_keys_added": 5,
        "keys_removed": 2,
        "cache_updated": true,
        "scan_duration_seconds": 1.23
    }
}
```

### 7. GetHistory

**Endpoint**: `GET /Admin/Translations/GetHistory?key=WELCOME_BACK&language=en&limit=10`

**Response**:
```json
{
    "success": true,
    "data": [
        {
            "id": 12345,
            "translation_key": "WELCOME_BACK",
            "language_code": "en",
            "old_value": "Welcome back",
            "new_value": "Welcome back to NiceTraders!",
            "changed_by": 1,
            "change_reason": "MANUAL",
            "changed_at": "2025-12-25T10:30:00Z"
        },
        {
            "id": 12344,
            "translation_key": "WELCOME_BACK",
            "language_code": "en",
            "old_value": "Welcome",
            "new_value": "Welcome back",
            "changed_by": 1,
            "change_reason": "MANUAL",
            "changed_at": "2025-12-20T09:15:00Z"
        }
    ]
}
```

### 8. CreateBackup

**Endpoint**: `POST /Admin/Translations/CreateBackup`

**Request**:
```json
{
    "backup_name": "pre_release_v2.0",
    "description": "Backup before v2.0 release"
}
```

**Response**:
```json
{
    "success": true,
    "backup": {
        "id": 1,
        "backup_name": "pre_release_v2.0",
        "created_at": "2025-12-25T11:00:00Z",
        "record_count": 5709
    }
}
```

### 9. RollbackTranslation

**Endpoint**: `POST /Admin/Translations/RollbackTranslation`

**Request**:
```json
{
    "translation_key": "WELCOME_BACK",
    "language_code": "en",
    "version": 1  // Which history record to restore
}
```

**Response**:
```json
{
    "success": true,
    "message": "Translation rolled back successfully",
    "restored": {
        "old_value": "Welcome back to NiceTraders!",
        "new_value": "Welcome back",
        "restored_at": "2025-12-25T11:05:00Z"
    }
}
```

## Code Examples

### Python: Update Translation

```python
import requests
import pymysql

# Update English translation
url = "http://localhost:9000/Admin/Translations/UpdateEnglish"
payload = {
    "translation_key": "WELCOME_BACK",
    "english_value": "Welcome back, user!",
    "strategy": "mark_for_review",
    "notes": "Updated to be more friendly"
}
response = requests.post(url, json=payload)
print(response.json())
```

### Python: Bulk Translations

```python
import requests

# Batch update multiple translations
url = "http://localhost:9000/Admin/Translations/BulkUpdate"
payload = {
    "updates": [
        {"key": "WELCOME_BACK", "language": "ja", "value": "おかえりなさい"},
        {"key": "SIGN_IN", "language": "ja", "value": "サインイン"},
        {"key": "WELCOME_BACK", "language": "es", "value": "¡Bienvenido!"},
    ]
}
response = requests.post(url, json=payload)
for result in response.json()["results"]:
    print(f"{result['key']} ({result['language']}): {result['status']}")
```

### JavaScript/Svelte: Fetch Inventory

```javascript
// In Svelte component
import { onMount } from 'svelte';

let views = [];
let loading = true;
let error = null;

onMount(async () => {
    try {
        const response = await fetch('/Admin/Translations/GetViewInventory');
        const data = await response.json();
        if (data.success) {
            views = data.data.views;
        } else {
            error = "Failed to load views";
        }
    } catch (e) {
        error = e.message;
    } finally {
        loading = false;
    }
});
```

### JavaScript/Svelte: Handle History Rollback

```javascript
async function rollbackTranslation(key, language, version) {
    const response = await fetch('/Admin/Translations/RollbackTranslation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            translation_key: key,
            language_code: language,
            version: version
        })
    });
    
    const data = await response.json();
    if (data.success) {
        // Reload translation and notify user
        alert("Rollback successful!");
        // Refresh the view
        location.reload();
    } else {
        alert("Rollback failed: " + data.error);
    }
}
```

## Scanner Implementation

### iOS Scanner Logic

Located in: `scan_ios_translations.py`

```python
import re
import os
import json

def scan_swift_file(filepath):
    """Extract localization keys from Swift file"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Pattern: localizationManager.localize("KEY_NAME")
    pattern = r'localizationManager\.localize\("([^"]+)"\)'
    matches = re.findall(pattern, content)
    
    return list(set(matches))  # Remove duplicates

def scan_ios_views(base_path):
    """Scan all Swift files in iOS app"""
    views_inventory = {}
    
    for root, dirs, files in os.walk(base_path):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                keys = scan_swift_file(filepath)
                
                if keys:  # Only if file has translations
                    view_name = file.replace('.swift', '')
                    views_inventory[view_name] = {
                        'path': filepath,
                        'keys': sorted(keys),
                        'key_count': len(keys)
                    }
    
    return views_inventory
```

## History Tracking

### Record Change

Located in: `TranslationHistory.py`

```python
def record_translation_change(translation_key, language_code, 
                             old_value, new_value, changed_by, 
                             change_reason='MANUAL'):
    """Record a translation change in history"""
    
    cursor.execute("""
        INSERT INTO translation_history
        (translation_key, language_code, old_value, new_value, changed_by, change_reason)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (translation_key, language_code, old_value, new_value, 
          changed_by, change_reason))
    
    db.commit()
    return cursor.lastrowid
```

### Get History

```python
def get_translation_history(translation_key, language_code=None, limit=50):
    """Retrieve change history for a translation"""
    
    if language_code:
        cursor.execute("""
            SELECT * FROM translation_history
            WHERE translation_key = %s AND language_code = %s
            ORDER BY changed_at DESC
            LIMIT %s
        """, (translation_key, language_code, limit))
    else:
        cursor.execute("""
            SELECT * FROM translation_history
            WHERE translation_key = %s
            ORDER BY changed_at DESC
            LIMIT %s
        """, (translation_key, limit))
    
    columns = [desc[0] for desc in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]
```

## Performance Optimization

### Caching Strategy

1. **View Inventory Cache**
   - Stored in `view_translation_keys_cache` table
   - Updated on-demand via ScanCodeForKeys
   - Reduces repeated file system scans

2. **Database Indexes**
   - `idx_translation_key`: Fast key lookup
   - `idx_language_code`: Fast language filtering
   - `idx_updated_at`: Fast sorting by date

3. **Frontend Caching**
   - Store inventory in localStorage
   - Invalidate on manual refresh
   - Pre-load common views

### Query Performance

```sql
-- Recommended indexes
CREATE INDEX idx_translation_key ON translations(translation_key);
CREATE INDEX idx_language_code ON translations(language_code);
CREATE INDEX idx_updated_at ON translations(updated_at DESC);
CREATE INDEX idx_history_key ON translation_history(translation_key, changed_at DESC);
CREATE INDEX idx_view_cache ON view_translation_keys_cache(last_scanned_at DESC);
```

**Performance targets**:
- Get inventory: < 500ms
- Update single translation: < 100ms
- Bulk update 100 items: < 5 seconds
- Scan iOS code: < 2 seconds (cached)
- Validate keys: < 1 second

## Error Handling

### Common Errors

```python
class TranslationError(Exception):
    """Base exception for translation operations"""
    pass

class TranslationNotFound(TranslationError):
    """Raised when translation key not found"""
    pass

class InvalidLanguage(TranslationError):
    """Raised when language code not supported"""
    pass

class ValidationError(TranslationError):
    """Raised when validation fails"""
    pass

# Usage in API
try:
    update_translation(key, language, value)
except TranslationNotFound:
    return {"success": False, "error": f"Translation key '{key}' not found"}
except InvalidLanguage:
    return {"success": False, "error": f"Language '{language}' not supported"}
except Exception as e:
    return {"success": False, "error": str(e)}, 500
```

## Testing

### Unit Tests

```python
import unittest
from Translations.AdminTranslations import *

class TestAdminTranslations(unittest.TestCase):
    
    def test_get_view_inventory(self):
        """Test getting full inventory"""
        response = get_view_inventory()
        self.assertEqual(response['success'], True)
        self.assertEqual(len(response['data']['views']), 31)
    
    def test_update_english(self):
        """Test updating English translation"""
        response = update_english('TEST_KEY', 'Test Value', 'mark_for_review')
        self.assertEqual(response['success'], True)
    
    def test_rollback(self):
        """Test rollback functionality"""
        response = rollback_translation('TEST_KEY', 'en', 1)
        self.assertEqual(response['success'], True)

if __name__ == '__main__':
    unittest.main()
```

### Integration Tests

See `LOCALIZATION_EDITOR_DEPLOYMENT.md` for full integration test suite.

## Debugging

### Enable Debug Logging

```python
# In AdminTranslations.py
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('AdminTranslations')

# In functions:
logger.debug(f"Updating key: {translation_key} to value: {value}")
logger.info(f"Translation updated successfully")
logger.error(f"Failed to update: {error}")
```

### Database Query Debugging

```bash
# Monitor active queries
SHOW PROCESSLIST;

# Check slow queries
SELECT * FROM mysql.slow_log;

# Enable query logging
SET GLOBAL log_output = 'TABLE';
SET GLOBAL general_log = 'ON';
SELECT * FROM mysql.general_log;
```

---

**Version**: 1.0  
**Last Updated**: December 25, 2025  
**Status**: Production Ready
