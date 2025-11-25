"""
Test script for Translations API endpoints
"""

import requests
import json

BASE_URL = "http://localhost:5000"

def test_get_translations():
    """Test GetTranslations endpoint"""
    print("\n📝 Testing /Translations/GetTranslations")
    try:
        response = requests.get(f"{BASE_URL}/Translations/GetTranslations?language=en")
        data = response.json()
        if data.get('success'):
            print(f"✅ Success! Retrieved {data.get('count')} translations for English")
            print(f"   Last updated: {data.get('last_updated')}")
            # Show first 3 translations as sample
            translations = data.get('translations', {})
            sample_keys = list(translations.keys())[:3]
            for key in sample_keys:
                print(f"   - {key}: {translations[key]}")
        else:
            print(f"❌ Error: {data.get('message')}")
    except Exception as e:
        print(f"❌ Connection error: {e}")

def test_get_last_updated():
    """Test GetLastUpdated endpoint"""
    print("\n📝 Testing /Translations/GetLastUpdated")
    try:
        response = requests.get(f"{BASE_URL}/Translations/GetLastUpdated")
        data = response.json()
        if data.get('success'):
            print(f"✅ Success! Retrieved last updated timestamps")
            for lang, timestamp in data.get('last_updated', {}).items():
                print(f"   - {lang}: {timestamp}")
        else:
            print(f"❌ Error: {data.get('message')}")
    except Exception as e:
        print(f"❌ Connection error: {e}")

def test_get_languages():
    """Test GetLanguages endpoint"""
    print("\n📝 Testing /Admin/Translations/GetLanguages")
    try:
        response = requests.get(f"{BASE_URL}/Admin/Translations/GetLanguages")
        data = response.json()
        if data.get('success'):
            print(f"✅ Success! Retrieved {data.get('count')} languages")
            languages = data.get('languages', [])
            print(f"   Languages: {', '.join(languages)}")
        else:
            print(f"❌ Error: {data.get('message')}")
    except Exception as e:
        print(f"❌ Connection error: {e}")

def test_get_translation_keys():
    """Test GetTranslationKeys endpoint"""
    print("\n📝 Testing /Admin/Translations/GetTranslationKeys")
    try:
        response = requests.get(f"{BASE_URL}/Admin/Translations/GetTranslationKeys")
        data = response.json()
        if data.get('success'):
            print(f"✅ Success! Retrieved {data.get('count')} translation keys")
            keys = data.get('keys', [])
            # Show first 5 keys
            sample_keys = keys[:5]
            for key in sample_keys:
                print(f"   - {key}")
            if len(keys) > 5:
                print(f"   ... and {len(keys) - 5} more")
        else:
            print(f"❌ Error: {data.get('message')}")
    except Exception as e:
        print(f"❌ Connection error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Translation API Tests")
    print("=" * 60)
    
    test_get_translations()
    test_get_last_updated()
    test_get_languages()
    test_get_translation_keys()
    
    print("\n" + "=" * 60)
    print("✅ Test suite completed!")
