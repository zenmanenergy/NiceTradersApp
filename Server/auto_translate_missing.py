#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Auto-Translate Missing Translations
Finds translations that are still in English and translates them to the correct language.
Uses Google Translate API via googletrans library.
"""

import pymysql
import sys

# Try to import googletrans, if not available, provide instructions
try:
    from googletrans import Translator
    HAS_TRANSLATOR = True
except ImportError:
    HAS_TRANSLATOR = False
    print("⚠️  googletrans-py library not found!")
    print("Install it with: pip install googletrans-py")
    print("")

# Language code mapping (ISO 639-1 codes used by Google Translate)
LANGUAGE_CODES = {
    'ar': 'ar',  # Arabic
    'de': 'de',  # German
    'es': 'es',  # Spanish
    'fr': 'fr',  # French
    'hi': 'hi',  # Hindi
    'ja': 'ja',  # Japanese
    'pt': 'pt',  # Portuguese
    'ru': 'ru',  # Russian
    'sk': 'sk',  # Slovak
    'zh': 'zh-cn',  # Chinese (Simplified)
}

def get_untranslated_items(target_language=None):
    """Query database for untranslated items"""
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    language_filter = ""
    if target_language:
        language_filter = f"AND t1.language_code = '{target_language}'"
    
    query = f"""
        SELECT 
            t1.id,
            t1.translation_key,
            t1.language_code,
            t1.translation_value,
            t2.translation_value as english_value
        FROM translations t1
        JOIN translations t2 
            ON t1.translation_key = t2.translation_key 
            AND t2.language_code = 'en'
        WHERE t1.language_code != 'en'
            AND t1.translation_value = t2.translation_value
            {language_filter}
        ORDER BY t1.translation_key, t1.language_code
    """
    
    cursor.execute(query)
    results = cursor.fetchall()
    
    cursor.close()
    db.close()
    
    return results

def translate_text(text, target_language):
    """Translate text using Google Translate"""
    if not HAS_TRANSLATOR:
        return None
    
    try:
        translator = Translator()
        
        # Map our language codes to Google Translate codes
        google_lang_code = LANGUAGE_CODES.get(target_language, target_language)
        
        # Translate from English to target language
        result = translator.translate(text, src='en', dest=google_lang_code)
        
        return result.text
    except Exception as e:
        print(f"  ⚠️  Translation error: {str(e)}")
        return None

def update_translation(record_id, translated_text):
    """Update the translation in the database"""
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    query = """
        UPDATE translations 
        SET translation_value = %s, updated_at = NOW()
        WHERE id = %s
    """
    
    cursor.execute(query, (translated_text, record_id))
    db.commit()
    
    cursor.close()
    db.close()

def translate_language(target_language):
    """Translate all untranslated items for a specific language"""
    print(f"🎯 Processing language: {target_language}")
    print("")
    
    # Get untranslated items for this language
    untranslated = get_untranslated_items(target_language)
    
    if not untranslated:
        print(f"  ✅ No untranslated items for {target_language}")
        print("")
        return 0
    
    print(f"  Found {len(untranslated)} untranslated items")
    
    if not HAS_TRANSLATOR:
        print("  ❌ Cannot proceed without googletrans-py library")
        return 0
    
    # Translate and update
    success_count = 0
    error_count = 0
    
    for idx, item in enumerate(untranslated, 1):
        record_id = item[0]
        translation_key = item[1]
        language_code = item[2]
        current_value = item[3]
        english_value = item[4]
        
        print(f"    [{idx}/{len(untranslated)}] {translation_key}...", end=' ')
        
        # Translate
        translated = translate_text(english_value, language_code)
        
        if translated and translated != english_value:
            # Update database
            update_translation(record_id, translated)
            print(f"✅ '{translated}'")
            success_count += 1
        else:
            print(f"⚠️  Failed")
            error_count += 1
    
    print(f"  ✅ Translated: {success_count} | ⚠️  Errors: {error_count}")
    print("")
    
    return success_count

def main():
    # Check for command line argument
    target_language = None
    if len(sys.argv) > 1:
        target_language = sys.argv[1]
        if target_language not in LANGUAGE_CODES:
            print(f"❌ Invalid language code: {target_language}")
            print(f"Valid codes: {', '.join(LANGUAGE_CODES.keys())}")
            sys.exit(1)
    
    if target_language:
        # Single language mode
        print(f"🎯 Targeting language: {target_language}")
        print("")
        
        untranslated = get_untranslated_items(target_language)
        
        if not untranslated:
            print(f"✅ No untranslated items found for {target_language}!")
            return
        
        print(f"Found {len(untranslated)} untranslated items")
        print("")
        
        response = input(f"Auto-translate {len(untranslated)} items for {target_language}? (y/n): ")
        
        if response.lower() != 'y':
            print("Cancelled.")
            return
        
        print("")
        translate_language(target_language)
    else:
        # All languages mode
        print("🔍 Finding untranslated items across all languages...")
        print("")
        
        untranslated = get_untranslated_items()
        
        if not untranslated:
            print("✅ No untranslated items found! All translations are complete.")
            return
        
        if not HAS_TRANSLATOR:
            print("❌ Cannot proceed without googletrans-py library")
            print("Install it with: pip install googletrans-py")
            sys.exit(1)
        
        # Group by language for reporting
        by_language = {}
        for item in untranslated:
            lang = item[2]
            if lang not in by_language:
                by_language[lang] = 0
            by_language[lang] += 1
        
        print("📊 Untranslated items by language:")
        for lang, count in sorted(by_language.items()):
            print(f"  {lang}: {count} items")
        print(f"\nTotal: {len(untranslated)} items across {len(by_language)} languages")
        print("")
        
        response = input("Auto-translate ALL languages? (y/n): ")
        
        if response.lower() != 'y':
            print("Cancelled.")
            return
        
        print("")
        print("🔄 Starting auto-translation for all languages...")
        print("="*60)
        print("")
        
        # Process each language
        total_success = 0
        for lang in sorted(LANGUAGE_CODES.keys()):
            if lang in by_language:
                total_success += translate_language(lang)
        
        print("="*60)
        print(f"✅ Total translations completed: {total_success}")
        print("="*60)
        print("")
    
    # Show final summary
    print("📊 Final check - remaining untranslated items:")
    remaining = get_untranslated_items(target_language)
    if not remaining:
        print("  ✅ None! All translations complete.")
    else:
        by_language = {}
        for item in remaining:
            lang = item[2]
            if lang not in by_language:
                by_language[lang] = 0
            by_language[lang] += 1
        
        for lang, count in sorted(by_language.items()):
            print(f"  {lang}: {count} items")

if __name__ == '__main__':
    main()
