#!/usr/bin/env python3
"""
Run this ONCE on your local machine to generate sync_translations.sh
with all 2000 translations embedded directly in the file.
Then copy sync_translations.sh to your server and run it there.
"""
import pymysql
import pymysql.cursors

print("Connecting to local database...")
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

print("Fetching all translations...")
cursor.execute("SELECT * FROM translations")
results = cursor.fetchall()
cursor.close()
db.close()

print(f"Found {len(results)} translations. Generating sync_translations.sh...")

# Generate the .sh file with all data embedded
with open('sync_translations.sh', 'w') as f:
    f.write('#!/bin/bash\n\n')
    f.write('# Generated sync_translations.sh with all 2000+ translations embedded\n')
    f.write('# Run this on the server to import all translations\n\n')
    f.write('mysql -h localhost -u stevenelson -pmwitcitw711 nicetraders << \'EOSQL\'\n\n')
    
    for i, row in enumerate(results, 1):
        key = row['translation_key']
        lang = row['language_code']
        value = row['translation_value']
        updated = row['updated_at']
        
        # Escape for MySQL
        value_escaped = value.replace('\\', '\\\\').replace("'", "\\'")
        key_escaped = key.replace('\\', '\\\\').replace("'", "\\'")
        lang_escaped = lang.replace('\\', '\\\\').replace("'", "\\'")
        updated_escaped = str(updated).replace('\\', '\\\\').replace("'", "\\'")
        
        f.write(f"INSERT INTO translations (translation_key, language_code, translation_value, updated_at) VALUES ('{key_escaped}', '{lang_escaped}', '{value_escaped}', '{updated_escaped}') ON DUPLICATE KEY UPDATE translation_value = '{value_escaped}', updated_at = '{updated_escaped}';\n")
        
        if i % 500 == 0:
            print(f"  Generated {i} statements...")
    
    f.write('\nEOSQL\n\n')
    f.write('echo "✓ Import complete!"\n')

print(f"✓ Generated sync_translations.sh with {len(results)} INSERT statements")
print("✓ File is ready to copy to server and run")
