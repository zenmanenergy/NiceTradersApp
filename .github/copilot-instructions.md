# GitHub Copilot Custom Instructions for NiceTradersApp

## Database Connection

**IMPORTANT:** When you need to connect to the MySQL database, use these credentials:

### Connection Details
- **Host:** localhost
- **User:** stevenelson
- **Password:** mwitcitw711
- **Database:** nicetraders
- **Library:** PyMySQL (NOT mysql-connector)

### Virtual Environment Location
The virtual environment is in the **Server directory**:
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
venv/bin/python3
```

### Running SQL Queries from Terminal
To execute SQL queries on the local database, use this pattern:
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server && venv/bin/python3 << 'EOF'
import pymysql
db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
cursor = db.cursor()
cursor.execute('YOUR SQL HERE')
results = cursor.fetchall()
for row in results:
    print(row)
db.commit()
cursor.close()
db.close()
EOF
```

For queries with DictCursor (returns dictionaries):
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server && venv/bin/python3 << 'EOF'
import pymysql
import pymysql.cursors
db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders', cursorclass=pymysql.cursors.DictCursor)
cursor = db.cursor()
cursor.execute('YOUR SQL HERE')
results = cursor.fetchall()
for row in results:
    print(row)
db.commit()
cursor.close()
db.close()
EOF
```

### Standard Connection Template (for Python scripts)
```python
import pymysql

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)
cursor = db.cursor()

# Your SQL here
cursor.execute("SELECT * FROM table_name")
results = cursor.fetchall()

db.commit()
cursor.close()
db.close()
```

### Common Mistakes to AVOID
- ❌ DO NOT use `mysql.connector` - it's not installed
- ❌ DO NOT use `root` user with `root` password - wrong credentials
- ❌ DO NOT use `python3` directly - it doesn't have pymysql installed
- ❌ DO NOT look for venv at project root - it's in Server directory
- ❌ DO NOT create diagnostic Flask routes for database testing
- ✅ ALWAYS use `Server/venv/bin/python3` (cd to Server first)
- ✅ ALWAYS use PyMySQL
- ✅ ALWAYS use credentials from above (stevenelson/mwitcitw711)

### Reference
The canonical connection code is in: `Server/_Lib/Database.py`

## Project Structure

### Backend (Flask)
- **Location:** `/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server`
- **Run:** `./Server/run.sh`

### iOS App
- **Location:** `/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders`
- **i18n:** Uses `LocalizationManager.shared.localize("KEY")` pattern
- **Translations:** Stored in database `translations` table, cached locally

### Migrations
- **Location:** `Server/migrations/`
- **Naming:** `00X_description.sql`

## i18n (Internationalization)

### iOS Pattern
All user-facing strings must use:
```swift
@ObservedObject var localizationManager = LocalizationManager.shared

Text(localizationManager.localize("TRANSLATION_KEY"))
```

**CRITICAL: When adding ANY new text to iOS views:**
1. NEVER use hardcoded strings like `Text("Welcome")`
2. ALWAYS use `localizationManager.localize("KEY_NAME")`
3. IMMEDIATELY add translations to database for ALL languages:
   - English (en)
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

### Adding New Translations (REQUIRED FOR ALL NEW TEXT)
1. **Database:** Add to `translations` table with ALL language codes
2. **Fallback:** Add English fallback to `LocalizationManager.swift` in `fallbackTranslations` dictionary
3. **Naming:** Use UPPERCASE_SNAKE_CASE for translation keys (e.g., `WELCOME_BACK`, `SIGN_IN`)
4. **Script:** Run `Server/fix_missing_translations.py` to verify all translations exist

### Translation Insertion Template
```python
# Use this to add translations for new text
import pymysql
db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
cursor = db.cursor()

translations = [
    ("NEW_KEY", "en", "English text"),
    ("NEW_KEY", "ja", "日本語テキスト"),
    ("NEW_KEY", "es", "Texto en español"),
    ("NEW_KEY", "fr", "Texte français"),
    ("NEW_KEY", "de", "Deutscher Text"),
    # Add ar, hi, pt, ru, sk, zh as well
]

for key, lang, value in translations:
    cursor.execute("INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s", (key, lang, value, value))

db.commit()
cursor.close()
db.close()
```

### Backend API
- `GET /Translations/GetAllTranslations` - **PRIMARY:** Get all translations for all languages (single call)
- `GET /Translations/GetTranslations?language=XX` - Legacy: Get translations for specific language
- `GET /Translations/GetLastUpdated` - Check translation timestamps
- `POST /Admin/Translations/Add` - Add new translation

### How i18n Caching Works
1. **First load:** App calls `/Translations/GetAllTranslations` and caches ALL languages locally
2. **Language switch:** App uses cached data instantly (no server call)
3. **Update check:** App periodically checks `max(updated_at)` timestamp
4. **Re-download:** Only downloads all translations if timestamp is newer than cache

This means translations for all languages are downloaded once and stored locally. Changing languages is instant using client-side data.

## Shell Commands
Default shell is **zsh** - generate commands for zsh, not bash.

When i say "compile and fix" that means run the IOS compiler immediately and repair any bugs. It does not mean try to search the code for errors. Just run the compiler and see if it works.

## Compilation Commands

### iOS Compilation
**Quick compile and check:**
```bash
cd "/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders" && xcodebuild build -scheme "Nice Traders" -configuration Debug 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"
```

**Full build output:**
```bash
cd "/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders" && xcodebuild build -scheme "Nice Traders" -configuration Debug
```

**Paths to remember:**
- **Xcode Project:** `/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders.xcodeproj`
- **Swift Files:** `/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders/*.swift`
- **Build Output Location:** `~/Library/Developer/Xcode/DerivedData/Nice_Traders-*/Build/Products/Debug-iphoneos/`

### Backend Compilation
**Run Flask server:**
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server && ./run.sh
```

**Or with flask directly:**
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server && flask --app flask_app run --host=0.0.0.0 --port=9000 --reload
```

If you need to write a python script don't just run the code in the command line, put it into a file. name the file: /scriptMadeByAi.py put it in the root folder. Then run it

Do NOT make summary documents unless I specifically ask for them.

Do not compile unless I ask you to.

I don't need excessive explanations of the code you write. Just write the code.

## Debugging Rules

**If you are working on the same problem for more than 2 attempts without resolution:**
1. Add comprehensive debugging print statements to the code
2. Ask the user to run the app and show you the debug output
3. Do NOT continue guessing - wait for the actual debug data before making more changes