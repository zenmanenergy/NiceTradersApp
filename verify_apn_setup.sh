#!/bin/zsh

echo "🔍 Verifying APN Setup for Nice Traders\n"

# Check provisioning profiles
echo "1️⃣ Checking Provisioning Profiles..."
PROFILE_DIR=~/Library/Developer/Xcode/UserData/Provisioning\ Profiles
if [ -d "$PROFILE_DIR" ]; then
    PUSH_PROFILES=$(find "$PROFILE_DIR" -name "*.mobileprovision" -exec sh -c '
        openssl smime -inform der -verify -noverify -in "$1" 2>/dev/null | plutil -p - | grep -q "aps-environment" && echo "$1"
    ' _ {} \;)
    
    if [ -n "$PUSH_PROFILES" ]; then
        echo "✅ Found provisioning profile(s) with push notification capability:"
        echo "$PUSH_PROFILES" | while read profile; do
            NAME=$(openssl smime -inform der -verify -noverify -in "$profile" 2>/dev/null | plutil -p - | grep '"Name"' | cut -d'"' -f4)
            ENV=$(openssl smime -inform der -verify -noverify -in "$profile" 2>/dev/null | plutil -p - | grep 'aps-environment' | cut -d'"' -f4)
            echo "   📱 $NAME (Environment: $ENV)"
        done
    else
        echo "❌ No provisioning profiles with push notification capability found"
    fi
else
    echo "❌ Provisioning profiles directory not found"
fi

# Check entitlements file
echo "\n2️⃣ Checking Entitlements File..."
ENTITLEMENTS_FILE="/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice Traders/Nice Traders.entitlements"
if [ -f "$ENTITLEMENTS_FILE" ]; then
    if grep -q "aps-environment" "$ENTITLEMENTS_FILE"; then
        ENV=$(plutil -p "$ENTITLEMENTS_FILE" | grep "aps-environment" | cut -d'"' -f4)
        echo "✅ Entitlements file configured with aps-environment: $ENV"
    else
        echo "❌ aps-environment not found in entitlements file"
    fi
else
    echo "❌ Entitlements file not found"
fi

# Check Info.plist for background modes
echo "\n3️⃣ Checking Info.plist for Background Modes..."
INFO_PLIST="/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders/Nice-Traders-Info.plist"
if [ -f "$INFO_PLIST" ]; then
    if grep -q "remote-notification" "$INFO_PLIST"; then
        echo "✅ remote-notification background mode is configured"
    else
        echo "⚠️  remote-notification background mode not found"
    fi
else
    echo "❌ Info.plist not found"
fi

# Check for AppDelegate
echo "\n4️⃣ Checking AppDelegate.swift..."
APP_DELEGATE=$(find "/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS" -name "AppDelegate.swift" 2>/dev/null | head -1)
if [ -f "$APP_DELEGATE" ]; then
    if grep -q "didRegisterForRemoteNotificationsWithDeviceToken" "$APP_DELEGATE"; then
        echo "✅ AppDelegate has device token registration"
    else
        echo "⚠️  Device token registration not found in AppDelegate"
    fi
else
    echo "❌ AppDelegate.swift not found"
fi

# Check database for user_devices table
echo "\n5️⃣ Checking Database..."
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp
if [ -d ".venv" ]; then
    .venv/bin/python3 -c "
import pymysql
try:
    db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
    cursor = db.cursor()
    
    # Check if user_devices table exists
    cursor.execute('SHOW TABLES LIKE \"user_devices\"')
    if cursor.fetchone():
        print('✅ user_devices table exists')
        
        # Check for recent device tokens
        cursor.execute('SELECT COUNT(*) FROM user_devices WHERE device_type=\"ios\"')
        count = cursor.fetchone()[0]
        print(f'   📱 iOS devices registered: {count}')
    else:
        print('❌ user_devices table not found')
    
    cursor.close()
    db.close()
except Exception as e:
    print(f'❌ Database error: {e}')
" 2>&1
else
    echo "⚠️  Virtual environment not found - skipping database check"
fi

echo "\n" 
echo "════════════════════════════════════════════════════════════"
echo "📋 SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "To complete APN setup:"
echo "1. Open Xcode: Nice Traders.xcodeproj"
echo "2. Go to Signing & Capabilities tab"
echo "3. Verify 'Push Notifications' capability is listed"
echo "4. Connect a physical iPhone (push doesn't work in simulator)"
echo "5. Build and run the app on your device"
echo "6. Grant notification permissions when prompted"
echo "7. Check logs to verify device token was sent to server"
echo ""
echo "To test push notifications, run:"
echo "   cd Server && .venv/bin/python3 test_send_push.py"
echo ""
