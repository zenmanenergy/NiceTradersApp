import pymysql

# Connect to local database
local_db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)

cursor = local_db.cursor()

# Get all translations
cursor.execute("SELECT translation_key, language_code, translation_value FROM translations")
translations = cursor.fetchall()

cursor.close()
local_db.close()

# Generate INSERT statements
print("-- Translations export")
print("-- Run this on the Hetzner server\n")

for key, lang, value in translations:
    # Escape single quotes in the value
    safe_value = value.replace("'", "''") if value else ''
    safe_key = key.replace("'", "''") if key else ''
    
    print(f"INSERT INTO translations (translation_key, language_code, translation_value) VALUES ('{safe_key}', '{lang}', '{safe_value}') ON DUPLICATE KEY UPDATE translation_value = '{safe_value}';")

print(f"\n-- Total translations: {len(translations)}")
