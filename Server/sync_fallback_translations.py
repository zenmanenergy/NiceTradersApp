#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Sync Fallback Translations to Database
Compares hardcoded fallback translations in iOS with database
and inserts any missing keys for all supported languages.
"""

import pymysql
import sys

# Hardcoded fallback translations from LocalizationManager.swift
FALLBACK_TRANSLATIONS = {
    "LOADING": "Loading...",
    "ERROR": "Error",
    "CANCEL": "Cancel",
    "NICE_TRADERS_HEADER": "NICE Traders",
    "NEIGHBORHOOD_CURRENCY_EXCHANGE": "Neighborhood International Currency Exchange",
    "EXCHANGE_CURRENCY_LOCALLY": "Exchange Currency Locally",
    "LANDING_PAGE_DESCRIPTION": "Connect with neighbors to exchange foreign currency safely and affordably. Skip the expensive fees and get the cash you need from your community.",
    "FIND_NEARBY": "Find Nearby",
    "FIND_NEARBY_DESC": "See currency exchanges happening in your neighborhood",
    "BETTER_RATES": "Better Rates",
    "BETTER_RATES_DESC": "Avoid high bank and airport exchange fees",
    "SAFE_EXCHANGES": "Safe Exchanges",
    "SAFE_EXCHANGES_DESC": "Meet in public places with user ratings for safety",
    "GET_STARTED": "Get Started",
    "LEARN_MORE": "Learn More",
    "LANDING_FOOTER": "Join thousands of travelers saving money on currency exchange",
    "ALREADY_HAVE_ACCOUNT": "Already have an account?",
    "SIGN_IN": "Sign In",
    "CHECKING_SESSION": "Checking session...",
    "EXCHANGE_RATES": "Exchange Rates",
    "CURRENCY_CONVERTER": "Currency Converter",
    "AMOUNT": "Amount",
    "FROM": "From",
    "TO": "To",
    "CONVERT": "Convert",
    "RESULT": "Result",
    "CURRENT_RATES": "Current Rates",
    "NO_RATES_AVAILABLE": "No rates available",
    "TAP_REFRESH_RATES": "Tap refresh to load exchange rates",
    "SEARCH_CURRENCY": "Search Currency",
    "SELECT_CURRENCY": "Select currency",
    "TRY_ADJUSTING_SEARCH": "Try adjusting your search or check back later for new listings.",
    "MEETING_LABEL": "Meeting:",
    "AVAILABLE_UNTIL": "Available until:",
    "CONTACT_TRADER": "Contact Trader",
    "EXCHANGE_DETAILS": "Exchange Details",
    "TRADER_INFORMATION": "Trader Information",
    "MEETING_LOCATION": "Meeting Location *",
    "DATE": "Date *",
    "TIME": "Time *",
    "OPTIONAL_MESSAGE": "Optional Message",
    "SEND_PROPOSAL": "Send Proposal",
    "MEETING_PROPOSALS": "Meeting Proposals",
    "MEMBER_SINCE": "Member since",
    "APPROXIMATE_AREA": "Approximate area - exact location shared after purchase",
    "EXACT_LOCATION": "Exact location - meeting time confirmed",
    "WELCOME_BACK": "Welcome Back",
    "SIGN_IN_TO_CONTINUE": "Sign in to continue",
    "EMAIL": "Email",
    "ENTER_EMAIL": "Enter email",
    "PASSWORD": "Password",
    "ENTER_PASSWORD": "Enter password",
    "FORGOT_PASSWORD": "Forgot Password?",
    "FORGOT_PASSWORD_COMING_SOON": "Password recovery is coming soon!",
    "SIGNING_IN": "Signing in...",
    "DONT_HAVE_ACCOUNT": "Don't have an account?",
    "SIGN_UP": "Sign Up",
    "LOGIN": "Login",
    "OK": "OK",
    "EMAIL_REQUIRED": "Email is required",
    "INVALID_EMAIL": "Invalid email address",
    "PASSWORD_REQUIRED": "Password is required",
    "INVALID_URL": "Invalid URL",
    "NETWORK_ERROR": "Network error",
    "NO_DATA_RECEIVED": "No data received",
    "INVALID_LOGIN_CREDENTIALS": "Invalid email or password",
    "FAILED_PARSE_RESPONSE": "Failed to parse response",
}

# Supported languages
SUPPORTED_LANGUAGES = ["ar", "de", "es", "fr", "hi", "ja", "pt", "ru", "sk", "zh"]

def connect_db():
    """Connect to the database"""
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders'
        )
        return db
    except pymysql.Error as e:
        print(f"❌ Database connection error: {e}")
        sys.exit(1)

def get_existing_keys(cursor):
    """Get all existing translation keys from database"""
    try:
        cursor.execute("SELECT DISTINCT translation_key FROM translations")
        results = cursor.fetchall()
        return {row[0] for row in results}
    except pymysql.Error as e:
        print(f"❌ Error fetching existing keys: {e}")
        return set()

def insert_missing_translations(cursor, db):
    """Insert missing fallback translations for all languages"""
    existing_keys = get_existing_keys(cursor)
    missing_keys = set(FALLBACK_TRANSLATIONS.keys()) - existing_keys
    
    if not missing_keys:
        print("✅ All fallback keys already exist in database")
        return 0
    
    print(f"\n📝 Found {len(missing_keys)} missing translation keys:")
    for key in sorted(missing_keys):
        print(f"  • {key}")
    
    print(f"\n🌍 Inserting for {len(SUPPORTED_LANGUAGES)} languages...")
    
    total_inserted = 0
    
    for lang in SUPPORTED_LANGUAGES:
        inserted_count = 0
        
        for key in missing_keys:
            english_value = FALLBACK_TRANSLATIONS[key]
            
            try:
                # For English, use the exact text
                if lang == 'en':
                    cursor.execute(
                        "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s",
                        (key, lang, english_value, english_value)
                    )
                else:
                    # For other languages, initially use English value (will be auto-translated later)
                    cursor.execute(
                        "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s",
                        (key, lang, english_value, english_value)
                    )
                
                inserted_count += 1
            except pymysql.Error as e:
                print(f"  ❌ Error inserting {key} for {lang}: {e}")
        
        if inserted_count > 0:
            print(f"  ✅ {lang.upper()}: {inserted_count} keys inserted")
            total_inserted += inserted_count
    
    try:
        db.commit()
        print(f"\n✅ Successfully committed {total_inserted} translations to database")
    except pymysql.Error as e:
        print(f"❌ Error committing to database: {e}")
        db.rollback()
        return 0
    
    return total_inserted

def main():
    print("=" * 60)
    print("Sync Fallback Translations to Database")
    print("=" * 60)
    print(f"\n📊 Fallback keys to sync: {len(FALLBACK_TRANSLATIONS)}")
    print(f"🌍 Languages: {', '.join(SUPPORTED_LANGUAGES)}")
    print("")
    
    db = connect_db()
    cursor = db.cursor()
    
    try:
        total = insert_missing_translations(cursor, db)
        
        if total > 0:
            print("\n" + "=" * 60)
            print(f"✅ Synchronization complete! ({total} total inserted)")
            print("=" * 60)
            print("\n💡 Next steps:")
            print("  1. Run auto_translate_all.sh to translate the new keys")
            print("  2. Or run: python auto_translate_missing.py <lang>")
        else:
            print("\n" + "=" * 60)
            print("ℹ️  No changes needed")
            print("=" * 60)
    
    finally:
        cursor.close()
        db.close()

if __name__ == '__main__':
    main()
