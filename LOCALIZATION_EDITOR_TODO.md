# Localization Editor - Web Admin Implementation TODO

## Overview
Build a comprehensive localization editor in the web admin dashboard that:
- Lists every view/page in the iOS app and web admin
- Displays all i18n translation keys and their English values
- Allows editing English translations
- Auto-updates all translations when English changes
- Provides UI to edit translations for all supported languages

---

## Phase 1: Discovery & Cataloging

### 1.1 Scan iOS Views and Extract i18n Keys
- [ ] Create script to parse all `.swift` files in iOS project
- [ ] Extract all `localizationManager.localize("KEY")` calls
- [ ] Extract all `Text(localizationManager.localize("KEY"))` calls
- [ ] Build mapping: View → [i18n Keys]
- [ ] Output: JSON file with all iOS views and their translation keys
- [ ] **Files to scan:**
  - All `.swift` files in `/Client/IOS/Nice Traders/Nice Traders/`
  - Subdirectories: Dashboard/, etc.

### 1.2 Scan Web Admin Views and Extract i18n Keys
- [ ] Create script to parse Svelte/JavaScript files
- [ ] Extract all translation key references from browser admin
- [ ] Build mapping: Web Route → [i18n Keys]
- [ ] **Files to scan:**
  - `/Client/Browser/src/routes/` and all subdirectories
  - `/Client/Browser/src/lib/` components

### 1.3 Get All Supported Languages
- [ ] Query database `translations` table
- [ ] Get distinct `language_code` values
- [ ] Expected languages: en, ja, es, fr, de, ar, hi, pt, ru, sk, zh

### 1.4 Create Comprehensive Translation Key Inventory
- [ ] Combine iOS and web admin keys into single inventory
- [ ] For each key, get:
  - Current English translation
  - All translations in other languages
  - Last modified date
  - Count of views using this key
- [ ] Identify orphaned translation keys (not used in any view)
- [ ] Identify missing translations (keys without values in some languages)

---

## Phase 2: Backend API Endpoints

### 2.1 Get All Views and Their Translation Keys
- [ ] **Endpoint:** `GET /Admin/Translations/GetViewInventory`
- [ ] **Response:** 
  ```json
  {
    "views": [
      {
        "viewId": "LoginView",
        "viewType": "iOS",
        "viewPath": "LoginView.swift",
        "translationKeys": [
          {
            "key": "WELCOME_BACK",
            "englishValue": "Welcome Back",
            "lastModified": "2025-12-20T10:30:00Z"
          }
        ]
      },
      {
        "viewId": "login",
        "viewType": "Web",
        "viewPath": "routes/login/+page.svelte",
        "translationKeys": [...]
      }
    ]
  }
  ```

### 2.2 Update English Translation (with cascading updates)
- [ ] **Endpoint:** `POST /Admin/Translations/UpdateEnglish`
- [ ] **Input:** 
  ```json
  {
    "translationKey": "WELCOME_BACK",
    "newEnglishValue": "Welcome Back to NiceTraders",
    "strategy": "auto_translate" | "manual_review" | "clear_others"
  }
  ```
- [ ] **Behavior:**
  - Update English translation
  - **strategy: auto_translate** → Use translation API to update all other languages
  - **strategy: manual_review** → Mark all other languages for review, don't change them
  - **strategy: clear_others** → Clear all non-English translations, require manual re-entry
- [ ] **Response:** Include old and new values, which translations were affected
- [ ] Log the change with user ID and timestamp

### 2.3 Bulk Update Translations
- [ ] **Endpoint:** `POST /Admin/Translations/BulkUpdate`
- [ ] **Input:**
  ```json
  {
    "updates": [
      {
        "translationKey": "WELCOME_BACK",
        "languageCode": "es",
        "translationValue": "Bienvenido de Vuelta"
      }
    ]
  }
  ```
- [ ] Update multiple translations in single request
- [ ] Return success/failure for each translation

### 2.4 Get Translation Details for Editing
- [ ] **Endpoint:** `GET /Admin/Translations/GetDetails?key=TRANSLATION_KEY`
- [ ] **Response:**
  ```json
  {
    "translationKey": "WELCOME_BACK",
    "englishValue": "Welcome Back",
    "usageCount": 3,
    "usedInViews": [
      {"viewId": "LoginView", "viewType": "iOS"},
      {"viewId": "Dashboard", "viewType": "iOS"}
    ],
    "translations": [
      {"languageCode": "en", "value": "Welcome Back", "lastModified": "2025-12-20T10:30:00Z"},
      {"languageCode": "ja", "value": "ようこそ", "lastModified": "2025-12-15T14:20:00Z"},
      ...
    ]
  }
  ```

### 2.5 Validate Translation Keys Exist in Code
- [ ] **Endpoint:** `POST /Admin/Translations/ValidateKeys`
- [ ] Scan iOS and web admin code
- [ ] Compare against database keys
- [ ] Return:
  - Orphaned keys (in DB, not in code)
  - Missing keys (in code, not in DB)
  - Coverage percentage

### 2.6 Auto-Translation Service Integration
- [ ] **Endpoint:** `POST /Admin/Translations/AutoTranslate`
- [ ] **Input:** Translation key and new English value
- [ ] Use Google Translate API or similar
- [ ] Auto-generate translations for all languages
- [ ] Option to review before committing

---

## Phase 3: Frontend UI (Web Admin)

### 3.1 Main Localization Editor Page
- [ ] Create `/Client/Browser/src/routes/localization/+page.svelte`
- [ ] Display three-panel layout:
  1. **Left Panel:** View/Key List
  2. **Middle Panel:** English Editor
  3. **Right Panel:** All Language Translations

### 3.2 Left Panel - View and Key Inventory
- [ ] Filter by:
  - View type (iOS / Web)
  - View name (searchable)
  - Translation key (searchable)
- [ ] Show:
  - View name with icon (iOS vs Web)
  - List of translation keys in that view
  - Number of languages with translations
  - Last modified date
- [ ] Click key to load in middle/right panels

### 3.3 Middle Panel - English Translation Editor
- [ ] Display:
  - Translation key (read-only)
  - Current English value (large editable text area)
  - "Used in X views" badge
  - List of views using this key
  - Last modified by/date
- [ ] Edit controls:
  - Text input field
  - Save button
  - Preview of changes
  - Dropdown for update strategy:
    - "Auto-translate all languages"
    - "Mark others for manual review"
    - "Clear other translations"
  - Confirm button

### 3.4 Right Panel - Translation Editor
- [ ] Tabs for each supported language:
  - English (en) - read-only (mirrors middle panel)
  - Japanese (ja)
  - Spanish (es)
  - French (fr)
  - German (de)
  - Arabic (ar)
  - Hindi (hi)
  - Portuguese (pt)
  - Russian (ru)
  - Slovak (sk)
  - Chinese (zh)
- [ ] For each language:
  - Text area with translation value
  - Last modified indicator
  - Edit button (toggle edit mode)
  - Save button
  - "Needs Review" badge if marked for review
- [ ] Bulk language controls:
  - "Auto-translate all missing"
  - "Mark all for review"

### 3.5 Search and Filter Page
- [ ] Advanced search:
  - By translation key name
  - By view name
  - By language with missing translations
  - By orphaned keys
  - By keys modified in date range
- [ ] Sort options:
  - By view name
  - By last modified date
  - By completion percentage
  - By number of missing translations

### 3.6 Status Dashboard
- [ ] Overall statistics:
  - Total translation keys
  - Completion % for each language
  - Keys needing review
  - Orphaned keys
  - Recently modified keys
- [ ] Charts:
  - Language completion bar chart
  - Modification timeline
  - Missing translations breakdown

### 3.7 Import/Export Functionality
- [ ] Export all translations to JSON
- [ ] Export single language to JSON
- [ ] Import translations from JSON file
- [ ] Dry-run mode to preview changes

---

## Phase 4: Database Schema Updates

### 4.1 Update Translations Table
- [ ] Ensure table has these columns:
  - `translation_key` (PRIMARY KEY part 1)
  - `language_code` (PRIMARY KEY part 2)
  - `translation_value` (TEXT)
  - `updated_at` (TIMESTAMP)
  - `updated_by` (user ID for audit trail)
  - `status` (ENUM: 'active', 'review_needed', 'deprecated')
  - `notes` (optional notes/context)

### 4.2 Create Translation History Table
- [ ] Table: `translation_history`
- [ ] Columns:
  - `id` (PRIMARY KEY)
  - `translation_key`
  - `language_code`
  - `old_value`
  - `new_value`
  - `changed_by` (admin user ID)
  - `changed_at` (TIMESTAMP)
  - `change_reason` (e.g., "English updated", "Manual edit")

### 4.3 Create View Inventory Cache Table
- [ ] Table: `view_translation_keys_cache`
- [ ] Columns:
  - `id` (PRIMARY KEY)
  - `view_id`
  - `view_type` (iOS / Web)
  - `view_path`
  - `translation_keys` (JSON array)
  - `last_scanned_at` (TIMESTAMP)
  - `key_count`

---

## Phase 5: Integration & Safety Features

### 5.1 Backup and Rollback
- [ ] Auto-backup translations before bulk operations
- [ ] Provide rollback endpoint: `POST /Admin/Translations/Rollback/{historyId}`
- [ ] Show backup status in UI

### 5.2 Audit Trail
- [ ] Track all translation changes
- [ ] Show who changed what and when
- [ ] Implement in left sidebar: "View Change History"

### 5.3 Cache Invalidation
- [ ] When translations update, trigger cache clear
- [ ] Notify iOS app to refresh cache
- [ ] Notify web admin to refresh cache

### 5.4 Validation Rules
- [ ] Prevent empty translations
- [ ] Validate text length (warn if exceeds limits for UI)
- [ ] Prevent special character issues
- [ ] RTL language validation (Arabic, Hindi)

### 5.5 Permissions
- [ ] Restrict to admin users only
- [ ] Add "Translator" role with limited permissions
- [ ] Audit logs for permission violations

---

## Phase 6: Code Scanning & Automation

### 6.1 iOS Swift Scanner
- [ ] Parse `.swift` files
- [ ] Regex patterns:
  - `localizationManager\.localize\("([^"]+)"\)`
  - `Text\(localizationManager\.localize\("([^"]+)"\)\)`
- [ ] Extract view name from file path
- [ ] Generate JSON inventory

### 6.2 Web Admin Scanner
- [ ] Parse `.svelte` and `.js` files
- [ ] Regex patterns for i18n calls (depends on web implementation)
- [ ] Extract route path from file location
- [ ] Generate JSON inventory

### 6.3 Scheduled Sync Job
- [ ] **Job:** Run every hour or on-demand
- [ ] Re-scan iOS and web code
- [ ] Update `view_translation_keys_cache` table
- [ ] Detect new/removed keys
- [ ] Alert admin to orphaned keys
- [ ] Endpoint: `POST /Admin/Translations/ScanCodeForKeys`

---

## Phase 7: Frontend Features (Advanced)

### 7.1 Real-time Collaboration Indicators
- [ ] Show when multiple admins editing same key
- [ ] Lock mechanism to prevent conflicts
- [ ] Show last editor name/time

### 7.2 Translation Context
- [ ] For each key, show:
  - Screenshot of view using this text
  - Expected text length limits
  - Context notes (e.g., "Button label", "Error message")
- [ ] Add ability to add/edit context notes

### 7.3 Translation Memory
- [ ] Suggest translations based on similar keys
- [ ] Show translation history for key
- [ ] "Reuse" option to copy previous translation

### 7.4 Integration with Code Editor
- [ ] Link from translation key to code location
- [ ] "Jump to code" button opens GitHub file at line

---

## Phase 8: Testing & Verification

### 8.1 Unit Tests
- [ ] Test all backend endpoints
- [ ] Test translation update logic
- [ ] Test cascade update behavior
- [ ] Test orphaned key detection

### 8.2 Integration Tests
- [ ] Test iOS app receives updated translations
- [ ] Test web admin receives updated translations
- [ ] Test history/audit trail logging
- [ ] Test cache invalidation

### 8.3 Manual Testing Checklist
- [ ] [ ] Update English translation
- [ ] [ ] Verify all languages auto-update
- [ ] [ ] Verify history is logged
- [ ] [ ] Verify cache is cleared
- [ ] [ ] Verify iOS app displays updated text
- [ ] [ ] Verify web admin displays updated text
- [ ] [ ] Test rollback functionality
- [ ] [ ] Test with special characters
- [ ] [ ] Test with RTL languages

---

## Phase 9: Deployment & Maintenance

### 9.1 Deployment Steps
- [ ] Run database migrations
- [ ] Deploy backend endpoints
- [ ] Deploy frontend UI
- [ ] Update iOS app with any cache refresh logic
- [ ] Test in staging environment

### 9.2 Documentation
- [ ] User guide for localization editor
- [ ] Admin procedures for common tasks
- [ ] Troubleshooting guide
- [ ] API documentation

### 9.3 Monitoring
- [ ] Track translation update frequency
- [ ] Monitor orphaned keys
- [ ] Alert on missing translations
- [ ] Performance metrics for large operations

---

## Implementation Priority

1. **High Priority (MVP)**
   - Phase 1: Discovery & Cataloging
   - Phase 2: Basic CRUD endpoints (2.1-2.3)
   - Phase 3: Basic UI (3.1-3.4)
   - Phase 4: Database updates
   - Phase 5: Basic audit trail

2. **Medium Priority**
   - Phase 2: Remaining endpoints (2.4-2.6)
   - Phase 3: Advanced features (3.5-3.6)
   - Phase 6: Code scanning automation
   - Phase 8: Testing

3. **Low Priority (Nice-to-Have)**
   - Phase 7: Advanced frontend features
   - Phase 9: Full monitoring/deployment

---

## Success Criteria

- ✅ All 40+ iOS views and their translation keys are cataloged
- ✅ All web admin routes and their translation keys are cataloged
- ✅ Admin can view/edit any translation in any language
- ✅ Editing English auto-updates all other languages (with strategy selection)
- ✅ Changes reflect in iOS app and web admin within 5 minutes
- ✅ Full audit trail of all changes
- ✅ Zero orphaned translation keys
- ✅ 100% translation coverage for all languages
- ✅ UI is intuitive and performant with 1000+ translation keys

