# Apple Push Notification (APN) Setup Guide

Your APN code is **complete** and ready to go. You just need to configure your Apple Developer account and add the certificates. Here's exactly what to do:

---

## ✅ What's Already Done

- ✅ iOS app has `AppDelegate.swift` with device token registration
- ✅ iOS app has `DeviceTokenManager.swift` for managing notifications
- ✅ iOS app has `Nice Traders.entitlements` with `aps-environment` = `development`
- ✅ Backend has `APNService.py` ready to send notifications
- ✅ Backend has `NotificationService.py` with multi-language support
- ✅ Database has `user_devices` table for storing device tokens
- ✅ Database has `apn_logs` table for tracking notifications

---

## 🔧 What You Need to Do

### Step 1: Apple Developer Portal - Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (Add new)
4. Select **App IDs** → **Continue**
5. Choose **App** → **Continue**
6. Fill in:
   - **Description**: Nice Traders
   - **Bundle ID**: `com.nicetraders.app` (or whatever you choose - must match Xcode)
   - **Capabilities**: Check **Push Notifications** ✓
7. Click **Continue** → **Register**

### Step 2: Generate APNs Authentication Key (.p8)

**Recommended Method** (Token-based authentication - easier, no expiration):

1. In Apple Developer Portal, go to **Keys** → **+** (Add new)
2. Fill in:
   - **Key Name**: Nice Traders APNs Key
   - **Services**: Check **Apple Push Notifications service (APNs)** ✓
3. Click **Continue** → **Register**
4. **IMPORTANT**: Download the `.p8` file immediately (you can only download once!)
5. Save these values (you'll need them):
   - **Key ID**: (e.g., `AB12CD34EF`)
   - **Team ID**: (find in top-right of developer portal)
   - **File**: `AuthKey_AB12CD34EF.p8`

### Step 3: Configure Your Server

1. Upload the `.p8` file to your server:
   ```bash
   # Create a secure directory
   mkdir -p /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/certificates
   chmod 700 /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/certificates
   
   # Move your .p8 file there
   mv ~/Downloads/AuthKey_*.p8 /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/certificates/
   ```

2. Install the required Python library:
   ```bash
   cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
   source venv/bin/activate
   pip install apns2
   ```

3. Set environment variables (add to your `.env` file or export):
   ```bash
   export APNS_CERTIFICATE_PATH="/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/certificates/AuthKey_AB12CD34EF.p8"
   export APNS_KEY_ID="AB12CD34EF"
   export APNS_TEAM_ID="YOUR_TEAM_ID"
   export APNS_BUNDLE_ID="com.nicetraders.app"
   ```

4. Update `Server/flask_app.py` to initialize APNService with certificate:
   ```python
   import os
   from APNService.APNService import APNService
   
   # Initialize APN Service
   apn_service = APNService(
       certificate_path=os.getenv('APNS_CERTIFICATE_PATH'),
       team_id=os.getenv('APNS_TEAM_ID'),
       key_id=os.getenv('APNS_KEY_ID')
   )
   ```

### Step 4: Configure Xcode Project

1. Open Xcode: `Nice Traders.xcodeproj`
2. Select the project in the navigator → **Nice Traders** target
3. Go to **Signing & Capabilities** tab
4. **Signing**:
   - Select your **Team** (your Apple Developer account)
   - **Bundle Identifier**: Must match what you created in Step 1 (e.g., `com.nicetraders.app`)
   - Ensure **Automatically manage signing** is checked
5. **Capabilities**:
   - Click **+ Capability**
   - Add **Push Notifications**
   - You should see it listed with no errors
6. **Background Modes** (if not already added):
   - Click **+ Capability**
   - Add **Background Modes**
   - Check **Remote notifications** ✓

### Step 5: Update Code for Your Bundle ID

The `APNService.py` currently doesn't specify a bundle ID. Update it:

```python
# In APNService.py, update the send_notification method:
self.client.send_notification(
    token, 
    payload,
    topic=os.getenv('APNS_BUNDLE_ID', 'com.nicetraders.app')  # Add this
)
```

### Step 6: Test on a Physical Device

**Push notifications DO NOT work in the iOS Simulator!**

1. Connect your iPhone via USB
2. In Xcode, select your device from the device dropdown
3. Click **Run** (▶️)
4. The app will:
   - Request notification permissions
   - Register for push notifications
   - Send the device token to your backend (via `DeviceTokenManager`)
5. Check your backend logs to verify the device token was saved:
   ```bash
   cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
   source venv/bin/activate
   python3 -c "
   import pymysql
   db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
   cursor = db.cursor()
   cursor.execute('SELECT UserId, device_token, created_at FROM user_devices ORDER BY created_at DESC LIMIT 5')
   for row in cursor.fetchall():
       print(row)
   cursor.close()
   db.close()
   "
   ```

### Step 7: Send a Test Notification

You can test from your admin dashboard or run this Python script:

```python
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
source venv/bin/activate
python3 << 'EOF'
import os
os.environ['APNS_CERTIFICATE_PATH'] = '/path/to/your/AuthKey_*.p8'
os.environ['APNS_KEY_ID'] = 'YOUR_KEY_ID'
os.environ['APNS_TEAM_ID'] = 'YOUR_TEAM_ID'
os.environ['APNS_BUNDLE_ID'] = 'com.nicetraders.app'

from APNService.APNService import APNService

apn = APNService(certificate_path=os.environ['APNS_CERTIFICATE_PATH'])
result = apn.send_notification(
    user_id='YOUR_USER_ID',  # Get from database
    title='Test Notification',
    body='Hello from Nice Traders!',
    badge=1
)
print(result)
EOF
```

---

## 🐛 Troubleshooting

### "No device token found"
- Make sure you ran the app on a **physical device** (not simulator)
- Check that the user granted notification permissions
- Verify the device token was saved: `SELECT * FROM user_devices WHERE device_type='ios'`

### "APNs client initialization failed"
- Verify the `.p8` file path is correct
- Check file permissions: `ls -la /path/to/AuthKey_*.p8`
- Ensure the Key ID and Team ID are correct

### "Invalid token"
- Your device token might be in the wrong format
- Check `AppDelegate.swift` - it converts the token to hex string
- Verify it's stored correctly in the database

### "BadDeviceToken" error
- Bundle ID mismatch - ensure Xcode bundle ID matches the one registered
- Using development certificate with production device (or vice versa)
- Token might be from a different app

### Notifications not appearing
- Check device **Settings** → **Nice Traders** → **Notifications** are enabled
- Ensure device is not in Do Not Disturb mode
- Check the `apn_logs` table for errors

---

## 📝 Production vs Development

Currently set to **Development** mode (`aps-environment: development`).

### For Development (Testing):
- Use `.p8` key (works for both)
- Devices must be registered in your developer account
- Use `development` environment in entitlements
- APNs server: `api.sandbox.push.apple.com`

### For Production (App Store):
- Same `.p8` key works!
- Change entitlements to `production`:
  ```xml
  <key>aps-environment</key>
  <string>production</string>
  ```
- APNs server: `api.push.apple.com`
- Update `APNService.py` to use production environment

---

## 🎯 Quick Checklist

- [ ] Create App ID with Push Notifications capability
- [ ] Generate and download .p8 APNs key
- [ ] Save Key ID and Team ID
- [ ] Install apns2: `pip install apns2`
- [ ] Configure environment variables (APNS_CERTIFICATE_PATH, etc.)
- [ ] Update Xcode signing with your Team and Bundle ID
- [ ] Add Push Notifications capability in Xcode
- [ ] Test on physical iPhone (not simulator)
- [ ] Verify device token saved in database
- [ ] Send test notification
- [ ] Update todo list when working ✓

---

## 📚 Additional Resources

- [Apple Push Notification Documentation](https://developer.apple.com/documentation/usernotifications)
- [apns2 Python Library](https://github.com/Pr0Ger/PyAPNs2)
- [Token-based APNs Guide](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)

---

**Last Updated:** November 26, 2025
