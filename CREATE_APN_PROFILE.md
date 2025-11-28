# How to Create APN-Enabled Provisioning Profile

Since the downloaded profile doesn't have push notifications, follow these steps:

## Step 1: Enable Push Notifications on Your App ID

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Find your App ID: **NiceTraders.Nice-Traders**
3. Click on it to edit
4. Scroll to **Capabilities**
5. Find "Push Notifications" and **check the box** ✓
6. Click **Save** (top right)

## Step 2: Delete the Old Provisioning Profile

1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Find "iOS Team Provisioning Profile: NiceTraders.Nice-Traders"
3. Click on it
4. Click **Delete** (if it lets you - some profiles auto-regenerate)

## Step 3: Let Xcode Create New Profile

Back in Xcode:

1. **Signing & Capabilities** tab
2. **Uncheck** "Automatically manage signing"
3. You'll see errors - that's okay
4. **Re-check** "Automatically manage signing"
5. Click **"+ Capability"** button (top left of capabilities area)
6. Search for **"Push Notifications"**
7. Double-click to add it
8. Xcode will now create a NEW provisioning profile with push enabled

## Step 4: Verify

Click on the (i) info icon next to "Provisioning Profile" - it should now show:
- **Capabilities: 1 Included** (or more)
- Should list "Push Notifications"

## If That Still Doesn't Work

Then you need to manually create a provisioning profile:

1. Go to: https://developer.apple.com/account/resources/profiles/add
2. Select **"iOS App Development"** → Continue
3. App ID: Select **NiceTraders.Nice-Traders**
4. Certificates: Select your development certificate
5. Devices: Select your test device(s)
6. Name it: "Nice Traders Development Push"
7. **Generate** and **Download**
8. Double-click the downloaded .mobileprovision file
9. In Xcode, **uncheck** "Automatically manage signing"
10. Under "Provisioning Profile" dropdown, select your newly created profile

Let me know which step you're stuck on!
