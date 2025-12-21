#!/usr/bin/env python3
"""
Diagnostic script to check push notification setup
"""
import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
import os

print("\n" + "="*70)
print("🔍 PUSH NOTIFICATION DIAGNOSTIC TOOL")
print("="*70)

# Check APN credentials
print("\n📋 1. Checking APN Credentials...")
print("-"*70)

cert_path = '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/AuthKey_LST3TZH33S.p8'
if os.path.exists(cert_path):
    print(f"✅ Certificate file exists: {cert_path}")
    with open(cert_path, 'r') as f:
        content = f.read()
        if '-----BEGIN PRIVATE KEY-----' in content:
            print("✅ Certificate file format is valid")
        else:
            print("❌ Certificate file format is invalid")
else:
    print(f"❌ Certificate file NOT found: {cert_path}")

# Check database for device tokens
print("\n📋 2. Checking Database for Device Tokens...")
print("-"*70)

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

# Get all device tokens
cursor.execute("""
    SELECT 
        user_id,
        device_id,
        device_token,
        device_type,
        device_name,
        os_version,
        app_version,
        registered_at,
        updated_at
    FROM user_devices
    WHERE device_type = 'ios'
    ORDER BY updated_at DESC
""")
devices = cursor.fetchall()

if devices:
    print(f"✅ Found {len(devices)} iOS device(s) registered:")
    for i, device in enumerate(devices, 1):
        print(f"\n  Device #{i}:")
        print(f"    User ID: {device['user_id']}")
        print(f"    Device ID: {device['device_id']}")
        print(f"    Has Token: {'✅ YES' if device['device_token'] else '❌ NO'}")
        if device['device_token']:
            print(f"    Token Preview: {device['device_token'][:20]}...")
        print(f"    Device Name: {device['device_name']}")
        print(f"    OS Version: {device['os_version']}")
        print(f"    App Version: {device['app_version']}")
        print(f"    Last Updated: {device['updated_at']}")
else:
    print("❌ No iOS devices found in database")

# Check recent APN logs
print("\n📋 3. Checking Recent APN Logs...")
print("-"*70)

cursor.execute("""
    SELECT 
        user_id,
        Data,
        DateSent
    FROM apn_logs
    ORDER BY DateSent DESC
    LIMIT 5
""")
logs = cursor.fetchall()

if logs:
    print(f"✅ Found {len(logs)} recent APN log(s):")
    for i, log in enumerate(logs, 1):
        print(f"\n  Log #{i}:")
        print(f"    User ID: {log['user_id']}")
        print(f"    Date: {log['DateSent']}")
        print(f"    Data: {log['Data'][:100]}..." if len(str(log['Data'])) > 100 else f"    Data: {log['Data']}")
else:
    print("⚠️  No APN logs found (no notifications have been sent yet)")

# Check aioapns library
print("\n📋 4. Checking Python Dependencies...")
print("-"*70)

try:
    from aioapns import APNs, NotificationRequest, PushType
    print("✅ aioapns library is installed and importable")
except ImportError as e:
    print(f"❌ aioapns library NOT found: {e}")
    print("   Run: cd Server && venv/bin/pip install aioapns")

cursor.close()
db.close()

# Test user selection
print("\n📋 5. Select a user to test...")
print("-"*70)

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

cursor.execute("""
    SELECT DISTINCT u.user_id, u.email, u.username, 
           COUNT(ud.device_token) as token_count
    FROM users u
    LEFT JOIN user_devices ud ON u.user_id = ud.user_id 
        AND ud.device_type = 'ios' 
        AND ud.device_token IS NOT NULL
    GROUP BY u.user_id, u.email, u.username
    HAVING token_count > 0
    ORDER BY u.user_id
""")
users = cursor.fetchall()

if users:
    print(f"Found {len(users)} user(s) with device tokens:\n")
    for i, user in enumerate(users, 1):
        print(f"  {i}. User ID: {user['user_id']} | Email: {user['email']} | Tokens: {user['token_count']}")
    
    print("\n" + "="*70)
    print("To send a test notification, run:")
    print(f"  cd Server && venv/bin/python3 ../test_push_notification.py {users[0]['user_id']}")
else:
    print("❌ No users found with device tokens")
    print("   Users need to:")
    print("   1. Open the app on a physical iOS device")
    print("   2. Accept notification permissions")
    print("   3. Log in to their account")

cursor.close()
db.close()

print("="*70 + "\n")
