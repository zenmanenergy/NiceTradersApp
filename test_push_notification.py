#!/usr/bin/env python3
"""
Test script to send a push notification to verify banner display and tap handling
"""
import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from APNService.APNService import APNService
import os

# Initialize APN Service with credentials
apn_service = APNService(
    certificate_path='/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/AuthKey_LST3TZH33S.p8',
    key_id='LST3TZH33S',
    team_id='RXD2VW4MNP',
    topic='NiceTraders.Nice-Traders'
)

# Get user ID from command line or use a test user
user_id = sys.argv[1] if len(sys.argv) > 1 else input("Enter user_id to send test notification: ")

print(f"\n🔔 Sending test push notification to user {user_id}...")
print("=" * 60)

# Send test notification
result = apn_service.send_notification(
    user_id=user_id,
    title="Test Notification",
    body="This is a test notification. Tap to open the app!",
    badge=1,
    sound='default',
    deep_link_type='test',
    deep_link_id='123'
)

print("\n📱 Result:")
print("-" * 60)
if result['success']:
    print(f"✅ SUCCESS: {result['message']}")
    if 'tokens_sent' in result:
        print(f"📤 Sent to {result['tokens_sent']} device(s)")
    if 'failed' in result and result['failed']:
        print(f"⚠️  Failed tokens: {len(result['failed'])}")
        for failure in result['failed']:
            print(f"   - Token: {failure['token'][:20]}... Error: {failure['error']}")
else:
    print(f"❌ FAILED: {result.get('error', 'Unknown error')}")
    if 'debug' in result:
        print(f"\n🔍 Debug Info:")
        for key, value in result['debug'].items():
            print(f"   {key}: {value}")

print("=" * 60)
print("\n📋 Instructions:")
print("1. Close the Nice Traders app completely (swipe up from app switcher)")
print("2. Wait 5-10 seconds for the notification to arrive")
print("3. You should see an iOS system banner pop up")
print("4. Tap the banner to open the app")
print("5. The app should open and handle the deep link data")
