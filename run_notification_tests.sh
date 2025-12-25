#!/bin/bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
venv/bin/python3 << 'PYTHON_EOF'
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from Admin.NotificationService import NotificationService

def show_database_info():
    """Show what users and devices are in the database"""
    import pymysql
    
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    cursor.execute("""
        SELECT u.user_id, u.FirstName, u.LastName, u.PreferredLanguage, d.device_id, d.device_token
        FROM users u
        JOIN user_devices d ON u.user_id = d.user_id
        WHERE d.device_type = 'ios' AND d.is_active = 1 AND d.device_token IS NOT NULL
        ORDER BY u.user_id
    """)
    
    results = cursor.fetchall()
    db.close()
    
    print("\n" + "="*70)
    print("DATABASE INFORMATION - Users with Active Device Tokens")
    print("="*70)
    
    if results:
        print(f"\n✅ Found {len(results)} users with active iOS devices:\n")
        for user_id, fname, lname, lang, device_id, token in results:
            token_display = token[:20] + "..." if token else "NO TOKEN"
            print(f"  User ID: {user_id}")
            print(f"  Name: {fname} {lname}")
            print(f"  Language: {lang}")
            print(f"  Device ID: {device_id}")
            print(f"  Token: {token_display}")
            print()
    else:
        print("\n⚠️  No users with active iOS devices found in database")

def test_send_message_notification():
    """Test: Send message received notification"""
    print("\n" + "="*70)
    print("TEST 1: Message Received Notification")
    print("="*70)
    
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"
    SENDER_NAME = "John Smith"
    MESSAGE_PREVIEW = "Interested in your listing"
    LISTING_ID = "test-listing-001"
    MESSAGE_ID = "test-message-001"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_message_received_notification(
            RECIPIENT_USER_ID, SENDER_NAME, MESSAGE_PREVIEW, LISTING_ID, MESSAGE_ID
        )
        print(f"✅ Message notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {SENDER_NAME}")
        print(f"   Message: {MESSAGE_PREVIEW}")
        return True
    except Exception as e:
        print(f"❌ Failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_send_payment_notification():
    """Test: Payment received notification"""
    print("\n" + "="*70)
    print("TEST 2: Payment Received Notification")
    print("="*70)
    
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"
    BUYER_NAME = "Charlie Davis"
    AMOUNT = 250.00  # Use float not string
    CURRENCY = "EUR"
    LISTING_ID = "test-listing-002"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_payment_received_notification(
            RECIPIENT_USER_ID, BUYER_NAME, AMOUNT, CURRENCY, LISTING_ID
        )
        print(f"✅ Payment notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {BUYER_NAME}")
        print(f"   Amount: {CURRENCY} {AMOUNT}")
        return True
    except Exception as e:
        print(f"❌ Failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_send_rating_notification():
    """Test: Rating received notification"""
    print("\n" + "="*70)
    print("TEST 3: Rating Received Notification")
    print("="*70)
    
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"
    RATER_NAME = "David Lee"
    RATING = 5
    LISTING_ID = "test-listing-003"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_rating_received_notification(
            RECIPIENT_USER_ID, RATER_NAME, RATING, LISTING_ID
        )
        print(f"✅ Rating notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {RATER_NAME}")
        print(f"   Rating: {RATING} stars")
        return True
    except Exception as e:
        print(f"❌ Failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_send_push_disabled_alert():
    """Test: Push notifications disabled alert"""
    print("\n" + "="*70)
    print("TEST 4: Push Notifications Disabled Alert")
    print("="*70)
    
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_push_disabled_alert(RECIPIENT_USER_ID)
        print(f"✅ Push disabled alert sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        return True
    except Exception as e:
        print(f"❌ Failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("\n" + "="*70)
    print("APN NOTIFICATION REAL DEVICE TESTS")
    print("="*70)
    
    show_database_info()
    
    results = []
    results.append(("Message Notification", test_send_message_notification()))
    results.append(("Payment Notification", test_send_payment_notification()))
    results.append(("Rating Notification", test_send_rating_notification()))
    results.append(("Push Disabled Alert", test_send_push_disabled_alert()))
    
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {status}: {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed\n")

if __name__ == '__main__':
    main()

PYTHON_EOF
