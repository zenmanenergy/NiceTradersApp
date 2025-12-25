"""
Integration tests for APN notifications
Tests against the real database with actual hardcoded user IDs
Sends real APN messages to devices registered in the database
"""

import sys
import os
# Add Server directory to path for imports
server_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'Server')
sys.path.insert(0, server_dir)

from Admin.NotificationService import NotificationService
import pymysql

def get_users_with_devices():
    """Get all users that have registered iOS devices"""
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
    return results

def test_send_message_notification():
    """Test: Send message received notification"""
    print("\n" + "="*70)
    print("TEST 1: Message Received Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"  # Buyer Jane
    SENDER_NAME = "John Smith"
    AMOUNT = "500.00"
    CURRENCY = "USD"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_message_received_notification(
            RECIPIENT_USER_ID, SENDER_NAME, AMOUNT, CURRENCY
        )
        print(f"✅ Message notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {SENDER_NAME}")
        print(f"   Amount: {CURRENCY} {AMOUNT}")
        return True
    except Exception as e:
        print(f"❌ Failed to send message notification: {str(e)}")
        return False

def test_send_payment_notification():
    """Test: Payment received notification"""
    print("\n" + "="*70)
    print("TEST 2: Payment Received Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR53a3c642-4914-4de8-8217-03ee3da42224"  # Seller John
    AMOUNT = "250.00"
    CURRENCY = "EUR"
    SELLER_NAME = "Charlie Davis"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_payment_received_notification(
            RECIPIENT_USER_ID, AMOUNT, CURRENCY, SELLER_NAME
        )
        print(f"✅ Payment notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   Amount: {CURRENCY} {AMOUNT}")
        print(f"   From: {SELLER_NAME}")
        return True
    except Exception as e:
        print(f"❌ Failed to send payment notification: {str(e)}")
        return False

def test_send_negotiation_notification():
    """Test: Negotiation proposal notification"""
    print("\n" + "="*70)
    print("TEST 3: Negotiation Proposal Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR5d1af449-0ca3-49b2-94d1-26d9103457b4"  # Steve Nelson
    PROPOSER_NAME = "Alice Johnson"
    PROPOSAL_TYPE = "time"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_negotiation_proposal_notification(
            RECIPIENT_USER_ID, PROPOSER_NAME, PROPOSAL_TYPE
        )
        print(f"✅ Negotiation notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {PROPOSER_NAME}")
        print(f"   Type: {PROPOSAL_TYPE} proposal")
        return True
    except Exception as e:
        print(f"❌ Failed to send negotiation notification: {str(e)}")
        return False

def test_send_rating_notification():
    """Test: Rating received notification"""
    print("\n" + "="*70)
    print("TEST 4: Rating Received Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"  # Buyer Jane
    RATER_NAME = "David Lee"
    RATING = 5
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_rating_received_notification(
            RECIPIENT_USER_ID, RATER_NAME, RATING
        )
        print(f"✅ Rating notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {RATER_NAME}")
        print(f"   Rating: {RATING} stars")
        return True
    except Exception as e:
        print(f"❌ Failed to send rating notification: {str(e)}")
        return False

def test_send_listing_status_notification():
    """Test: Listing status change notification"""
    print("\n" + "="*70)
    print("TEST 5: Listing Status Changed Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR53a3c642-4914-4de8-8217-03ee3da42224"  # Seller John
    STATUS = "sold"
    AMOUNT = "750.00"
    CURRENCY = "GBP"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_listing_status_notification(
            RECIPIENT_USER_ID, STATUS, AMOUNT, CURRENCY
        )
        print(f"✅ Listing status notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   Status: {STATUS}")
        print(f"   Listing: {CURRENCY} {AMOUNT}")
        return True
    except Exception as e:
        print(f"❌ Failed to send listing status notification: {str(e)}")
        return False

def test_send_exchange_completed_notification():
    """Test: Exchange completed notification"""
    print("\n" + "="*70)
    print("TEST 6: Exchange Completed Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR5d1af449-0ca3-49b2-94d1-26d9103457b4"  # Steve Nelson
    PARTNER_NAME = "Emma Wilson"
    AMOUNT = "1000.00"
    CURRENCY = "AUD"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_exchange_completed_notification(
            RECIPIENT_USER_ID, PARTNER_NAME, AMOUNT, CURRENCY
        )
        print(f"✅ Exchange completed notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   Partner: {PARTNER_NAME}")
        print(f"   Amount: {CURRENCY} {AMOUNT}")
        return True
    except Exception as e:
        print(f"❌ Failed to send exchange completed notification: {str(e)}")
        return False

def test_send_push_disabled_alert():
    """Test: Push notifications disabled alert"""
    print("\n" + "="*70)
    print("TEST 7: Push Notifications Disabled Alert")
    print("="*70)
    
    # Hardcoded user ID from database
    RECIPIENT_USER_ID = "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"  # Buyer Jane
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_push_disabled_alert(RECIPIENT_USER_ID)
        print(f"✅ Push disabled alert sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        return True
    except Exception as e:
        print(f"❌ Failed to send push disabled alert: {str(e)}")
        return False

def test_send_location_proposal_notification():
    """Test: Location proposal notification"""
    print("\n" + "="*70)
    print("TEST 8: Location Proposal Notification")
    print("="*70)
    
    # Hardcoded user IDs from database
    RECIPIENT_USER_ID = "USR53a3c642-4914-4de8-8217-03ee3da42224"  # Seller John
    PROPOSER_NAME = "Frank Brown"
    
    notification_service = NotificationService()
    
    try:
        notification_service.send_location_proposed_notification(
            RECIPIENT_USER_ID, PROPOSER_NAME
        )
        print(f"✅ Location proposal notification sent successfully")
        print(f"   To: {RECIPIENT_USER_ID}")
        print(f"   From: {PROPOSER_NAME}")
        return True
    except Exception as e:
        print(f"❌ Failed to send location proposal notification: {str(e)}")
        return False

def show_database_info():
    """Show what users and devices are in the database"""
    print("\n" + "="*70)
    print("DATABASE INFORMATION")
    print("="*70)
    
    users = get_users_with_devices()
    
    if users:
        print(f"\n✅ Found {len(users)} users with active iOS devices:\n")
        for user_id, fname, lname, lang, device_id, token in users:
            token_display = token[:20] + "..." if token else "NO TOKEN"
            print(f"  User ID: {user_id}")
            print(f"  Name: {fname} {lname}")
            print(f"  Language: {lang}")
            print(f"  Device ID: {device_id}")
            print(f"  Token: {token_display}")
            print()
    else:
        print("\n⚠️  No users with active iOS devices found in database")
        print("    Device tokens need to be added to user_devices table")
        
        # Show devices that exist but don't have tokens
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders'
        )
        cursor = db.cursor()
        
        cursor.execute("""
            SELECT u.user_id, u.FirstName, u.LastName, d.device_id, d.device_type
            FROM users u
            JOIN user_devices d ON u.user_id = d.user_id
            WHERE d.is_active = 1
            LIMIT 5
        """)
        
        results = cursor.fetchall()
        db.close()
        
        print("\n  Devices that exist but have no token (need to be populated):\n")
        for user_id, fname, lname, device_id, device_type in results:
            print(f"    {device_type.upper()}: {user_id} ({fname} {lname}) - {device_id}")

def main():
    """Run all integration tests"""
    print("\n" + "="*70)
    print("APN NOTIFICATION INTEGRATION TESTS")
    print("Real database with hardcoded user IDs")
    print("="*70)
    
    # Show database info
    show_database_info()
    
    # Run tests
    results = []
    results.append(("Message Notification", test_send_message_notification()))
    results.append(("Payment Notification", test_send_payment_notification()))
    results.append(("Negotiation Notification", test_send_negotiation_notification()))
    results.append(("Rating Notification", test_send_rating_notification()))
    results.append(("Listing Status Notification", test_send_listing_status_notification()))
    results.append(("Exchange Completed Notification", test_send_exchange_completed_notification()))
    results.append(("Push Disabled Alert", test_send_push_disabled_alert()))
    results.append(("Location Proposal Notification", test_send_location_proposal_notification()))
    
    # Summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {status}: {test_name}")
    
    print(f"\n  Total: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
    
    print("\n" + "="*70)

if __name__ == '__main__':
    main()
