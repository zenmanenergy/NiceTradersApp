#!/bin/bash

echo "🔄 Syncing English translations to server database..."

python3 << 'EOF'
import pymysql
import sys

translations = [
    ('TIME', 'en', 'Time *'),
    ('TIME_UNTIL_MEETING', 'en', 'Time Until Meeting'),
    ('TO', 'en', 'To'),
    ('TO_CURRENCY', 'en', 'To Currency'),
    ('TOTAL_DUE', 'en', 'Total Due'),
    ('TOTAL_EXCHANGES', 'en', 'Total Exchanges'),
    ('TRADER_INFORMATION', 'en', 'Trader Information'),
    ('TRADES', 'en', 'trades'),
    ('TRUSTED_TRADER', 'en', 'Trusted Trader'),
    ('TRUSTED_TRADER_DESC', 'en', 'This user has excellent ratings and is highly trusted'),
    ('TRY_ADJUSTING_SEARCH', 'en', 'Try adjusting your search or check back later for new listings.'),
    ('TRY_AGAIN', 'en', 'Try Again'),
    ('TWENTY_FIVE_MILES', 'en', '25 miles'),
    ('TYPE_MESSAGE', 'en', 'Type your message...'),
    ('UNKNOWN_ERROR', 'en', 'Unknown error occurred'),
    ('UNLOCK_FULL_CONTACT', 'en', 'Unlock Full Contact'),
    ('UPDATE', 'en', 'Update'),
    ('UPDATE_LISTING', 'en', 'Update Listing'),
    ('UPDATE_MEETING_PREFERENCES', 'en', 'Update your meeting preferences'),
    ('UPDATING', 'en', 'Updating...'),
    ('USE_YOUR_CURRENT_LOCATION', 'en', 'Use your current location'),
    ('USUALLY_RESPONDS_WITHIN_1_HOUR', 'en', 'Usually responds within 1 hour'),
    ('VERIFIED_TRADER', 'en', 'Verified Trader'),
    ('VERIFIED_TRADER_DESC', 'en', 'This user has been verified and is trusted'),
    ('VERIFY_CURRENCY', 'en', 'Verify the authenticity of currency before completing the exchange'),
    ('VIEW_ACTIVE_EXCHANGE', 'en', 'View Active Exchange'),
    ('VIEW_ALL', 'en', 'View All'),
    ('WAITING_FOR_LOCATION_ACCEPTANCE', 'en', 'Waiting for location acceptance'),
    ('WAITING_FOR_OTHER_RESPONSE', 'en', 'Waiting for their response'),
    ('WAITING_FOR_YOUR_RESPONSE', 'en', 'Waiting for your response'),
    ('WAITING_OTHER_PAYMENT', 'en', 'Waiting for the other party to pay.'),
    ('WANTS', 'en', 'Wants'),
    ('WELCOME', 'en', 'Welcome'),
    ('WELCOME_BACK', 'en', 'Welcome Back'),
    ('WELL_DETECT_YOUR_LOCATION', 'en', "We'll detect your location to help others find you nearby"),
    ('WHAT_CURRENCY_DO_YOU_HAVE', 'en', 'What currency do you have?'),
    ('WHAT_CURRENCY_DO_YOU_WANT', 'en', 'What currency do you want?'),
    ('WHAT_CURRENCY_HAVE', 'en', 'What currency do you have?'),
    ('WHAT_CURRENCY_WANT', 'en', 'What currency do you want?'),
    ('WHAT_CURRENCY_WILL_YOU_ACCEPT', 'en', 'What currency will you accept?'),
    ('WHAT_IS_NICE_TRADERS', 'en', 'What is Nice Traders?'),
    ('WHEN_SHOULD_LISTING_EXPIRE', 'en', 'When should this listing expire?'),
    ('WHERE_CAN_YOU_MEET', 'en', 'Where can you meet?'),
    ('WHICH_CURRENCY_WILL_YOU_ACCEPT', 'en', 'Which currency will you accept?'),
    ('WHY_CHOOSE_NICE_TRADERS', 'en', 'Why Choose Nice Traders?'),
    ('WILLING_TO_ROUND_TO_NEAREST_DOLLAR', 'en', "I'm willing to round to the nearest whole dollar"),
    ('WITHIN_1_MILE', 'en', 'Within 1 mile'),
    ('WITHIN_10_MILES', 'en', 'Within 10 miles'),
    ('WITHIN_25_MILES', 'en', 'Within 25 miles'),
    ('WITHIN_3_MILES', 'en', 'Within 3 miles'),
    ('WITHIN_5_MILES', 'en', 'Within 5 miles'),
    ('WITHIN_MILES', 'en', 'Within'),
    ('WITHIN_N_MILES_RANGE', 'en', 'Within 5 miles'),
    ('WITHIN_RADIUS_KM', 'en', 'Within %d km radius'),
    ('YOU', 'en', 'You'),
    ('YOU_LABEL', 'en', 'You'),
    ('YOUR_EXACT_LOCATION_STAYS_PRIVATE', 'en', 'Your exact location stays private - others see general area only'),
    ('YOUR_LOCATION', 'en', 'Your Location'),
]

try:
    # Connect to database
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    print(f"Inserting {len(translations)} English translations...")
    
    count = 0
    for key, lang, value in translations:
        try:
            sql = """
                INSERT INTO translations (translation_key, language_code, translation_value)
                VALUES (%s, %s, %s)
                ON DUPLICATE KEY UPDATE
                translation_value = VALUES(translation_value)
            """
            cursor.execute(sql, (key, lang, value))
            count += 1
            if count % 20 == 0:
                print(f"  Inserted {count} translations...")
        except Exception as e:
            print(f"Error inserting {key}: {e}")
            continue
    
    # Commit all changes
    db.commit()
    print(f"✓ Successfully inserted {count} English translations!")
    
    cursor.close()
    db.close()
    
except Exception as e:
    print(f"✗ Error: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo "✓ Translation sync complete!"
else
    echo "✗ Translation sync failed!"
    exit 1
fi
