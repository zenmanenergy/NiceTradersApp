#!/usr/bin/env python3
import pymysql
import sys

# Database connection details
db_config = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders'
}

# New translations to add
new_translations = [
    # MEETING_NOT_AGREED translations
    ("MEETING_NOT_AGREED", "en", "Meeting not agreed"),
    ("MEETING_NOT_AGREED", "ja", "会議未決定"),
    ("MEETING_NOT_AGREED", "es", "Reunión no acordada"),
    ("MEETING_NOT_AGREED", "fr", "Réunion non convenue"),
    ("MEETING_NOT_AGREED", "de", "Treffen nicht vereinbart"),
    ("MEETING_NOT_AGREED", "ar", "لم يتم الاتفاق على الاجتماع"),
    ("MEETING_NOT_AGREED", "hi", "बैठक सहमत नहीं"),
    ("MEETING_NOT_AGREED", "pt", "Reunião não acordada"),
    ("MEETING_NOT_AGREED", "ru", "Встреча не согласована"),
    ("MEETING_NOT_AGREED", "sk", "Stretnutie nie je dohodnuté"),
    ("MEETING_NOT_AGREED", "zh", "未达成会议"),
    
    # LISTING_LOCATION translations
    ("LISTING_LOCATION", "en", "Listing location"),
    ("LISTING_LOCATION", "ja", "リスティング場所"),
    ("LISTING_LOCATION", "es", "Ubicación del anuncio"),
    ("LISTING_LOCATION", "fr", "Lieu de l'annonce"),
    ("LISTING_LOCATION", "de", "Angebotslocation"),
    ("LISTING_LOCATION", "ar", "موقع الحائط"),
    ("LISTING_LOCATION", "hi", "सूची स्थान"),
    ("LISTING_LOCATION", "pt", "Localização do anúncio"),
    ("LISTING_LOCATION", "ru", "Местоположение объявления"),
    ("LISTING_LOCATION", "sk", "Umiestnenie zoznamu"),
    ("LISTING_LOCATION", "zh", "列表位置"),
    
    # MEETING_AREA translations
    ("MEETING_AREA", "en", "Meeting area"),
    ("MEETING_AREA", "ja", "会議エリア"),
    ("MEETING_AREA", "es", "Área de reunión"),
    ("MEETING_AREA", "fr", "Zone de réunion"),
    ("MEETING_AREA", "de", "Treffbereich"),
    ("MEETING_AREA", "ar", "منطقة الاجتماع"),
    ("MEETING_AREA", "hi", "बैठक क्षेत्र"),
    ("MEETING_AREA", "pt", "Área de reunião"),
    ("MEETING_AREA", "ru", "Область встречи"),
    ("MEETING_AREA", "sk", "Oblasť stretnutia"),
    ("MEETING_AREA", "zh", "会议区域"),
    
    # WITHIN_RADIUS_KM translations
    ("WITHIN_RADIUS_KM", "en", "Within %d km radius"),
    ("WITHIN_RADIUS_KM", "ja", "%d km圏内"),
    ("WITHIN_RADIUS_KM", "es", "Dentro de %d km de radio"),
    ("WITHIN_RADIUS_KM", "fr", "À proximité de %d km"),
    ("WITHIN_RADIUS_KM", "de", "Innerhalb von %d km Radius"),
    ("WITHIN_RADIUS_KM", "ar", "في نطاق %d كم"),
    ("WITHIN_RADIUS_KM", "hi", "%d किमी की परिधि में"),
    ("WITHIN_RADIUS_KM", "pt", "Dentro de %d km de raio"),
    ("WITHIN_RADIUS_KM", "ru", "В пределах %d км"),
    ("WITHIN_RADIUS_KM", "sk", "Do %d km polomeru"),
    ("WITHIN_RADIUS_KM", "zh", "在%d公里范围内"),
]

try:
    # Connect to database
    db = pymysql.connect(**db_config)
    cursor = db.cursor()
    
    print("Adding translations to database...")
    
    added_count = 0
    for key, lang, value in new_translations:
        try:
            # Use INSERT ... ON DUPLICATE KEY UPDATE to handle existing entries
            cursor.execute(
                "INSERT INTO translations (translation_key, language_code, translation_value) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE translation_value = %s",
                (key, lang, value, value)
            )
            added_count += 1
            print(f"✓ Added/Updated: {key} ({lang})")
        except Exception as e:
            print(f"✗ Error adding {key} ({lang}): {e}")
    
    db.commit()
    cursor.close()
    db.close()
    
    print(f"\n✅ Successfully added/updated {added_count} translations")
    
except pymysql.Error as e:
    print(f"Database error: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
