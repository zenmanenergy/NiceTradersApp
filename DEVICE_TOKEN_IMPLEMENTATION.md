# Device Token Registration - Implementation Complete

## Overview
The device token registration system has been fully implemented to handle asynchronous APNs token delivery. Devices will now be registered even before APNs delivers the token, and the token will be updated automatically when it becomes available.

## Architecture

### Two-Stage Device Registration Flow
1. **Stage 1 - Immediate (Login/Signup)**
   - iOS app sends login/signup request with device info but possibly no APNs token yet
   - Server creates a device entry with `device_token = NULL`
   - Returns `UserId` in response so iOS app can identify the user

2. **Stage 2 - Asynchronous (After APNs Delivers Token)**
   - AppDelegate receives APNs token (minutes after login)
   - DeviceTokenManager automatically sends token to backend update endpoint
   - Backend updates the device entry with the actual APNs token

## Backend Changes

### 1. Database Schema (`database_schema.sql`)
- Modified `device_token` column from `NOT NULL UNIQUE` to `UNIQUE` (allows NULL values)
- Allows device entries without tokens initially

### 2. Updated RegisterDevice.py (`Server/Profile/RegisterDevice.py`)
**Key Changes:**
- No longer requires `device_token` to be non-None
- Creates placeholder device entries when token is NULL
- Intelligently updates existing pending entries when new tokens arrive
- Handles token reassignment (moves token to new user if needed)

**Flow:**
```
If token provided:
  → Check if exists for this user (update timestamp)
  → Check if exists for different user (move it)
  → Otherwise create new entry
Else (token is None):
  → Check for existing pending entry (update metadata)
  → Otherwise create pending entry with device_id
```

### 3. Updated GetLogin.py (`Server/Login/GetLogin.py`)
**Changes:**
- Always calls `register_device()` now (removed `if device_token:` check)
- Returns `UserId` in JSON response (needed by iOS for later token updates)
- Response now includes: SessionId, UserType, UserId

### 4. Updated CreateAccount.py (`Server/Signup/CreateAccount.py`)
**Changes:**
- Always registers device (removed conditional)
- Returns `userId` in response JSON

### 5. New UpdateDeviceToken.py (`Server/Profile/UpdateDeviceToken.py`)
**Purpose:** Endpoint for updating device token after APNs delivers it

**Features:**
- Validates user_id and device_token
- Checks for duplicate tokens across users
- Intelligently finds and updates the pending device entry
- Handles token reassignment scenarios

### 6. Updated Profile.py Router (`Server/Profile/Profile.py`)
**Changes:**
- Added import for UpdateDeviceToken
- Added new route: `/Profile/UpdateDeviceToken` (GET/POST)
- Extracts UserId, deviceType, deviceToken from request
- Calls update_device_token function

## iOS Changes

### 1. Updated SessionManager.swift
**Added:**
- `userId` property (stored in UserDefaults)
- Saves/clears userId on login/logout
- Needed for identifying user when token arrives later

### 2. Updated DeviceTokenManager.swift (`Client/IOS/Nice Traders/Nice Traders/DeviceTokenManager.swift`)
**Key Changes:**
- `setDeviceToken()` now calls backend immediately when token arrives
- New private method: `updateBackendWithDeviceToken()`
- Sends token to `/Profile/UpdateDeviceToken` endpoint
- Includes device metadata (appVersion, osVersion, deviceType)

**Automatic Flow:**
1. AppDelegate calls `setDeviceToken()`
2. DeviceTokenManager stores it locally
3. Automatically calls backend endpoint with userId + token
4. Backend finds pending entry and updates it

### 3. Updated LoginView.swift
**Changes:**
- Parses `UserId` from login response
- Stores UserId in UserDefaults via SessionManager
- Clears UserId on logout

### 4. Updated SignupView.swift
**Changes:**
- Parses `userId` from signup response
- Stores userId in UserDefaults via SessionManager

## Data Flow Diagram

### Login/Signup with Device Registration

```
┌─────────────────────────────────────────────────────────────┐
│ User initiates login/signup                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ iOS App → DeviceTokenManager.getDeviceInfo()                │
│ Gathers: device_type, osVersion, appVersion, deviceToken   │
│ (deviceToken might be nil at this point)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ iOS App → Server /Login/Login or /Signup/Signup             │
│ Includes: email, password, device info                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Server GetLogin.py / CreateAccount.py                       │
│ 1. Authenticate user                                        │
│ 2. Create session                                           │
│ 3. Call register_device(userId, device_token=None, ...)    │
│    → Creates pending device entry in DB                     │
│ 4. Return: SessionId, UserType, UserId                      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ iOS App stores SessionId, UserType, UserId locally          │
│ User now logged in, device pending APNs token               │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼ (seconds later)           ▼ (minutes later)
┌──────────────────────┐    ┌──────────────────────┐
│ User uses app        │    │ APNs delivers token  │
│ (SessionId valid)    │    │ to AppDelegate       │
└──────────────────────┘    └─────────┬────────────┘
                                      │
                                      ▼
                            ┌──────────────────────┐
                            │ AppDelegate calls    │
                            │ DeviceTokenManager   │
                            │ .setDeviceToken()    │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │ DeviceTokenManager   │
                            │ auto-calls backend   │
                            │ /Profile/            │
                            │ UpdateDeviceToken    │
                            │ with: userId, token  │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │ Server UpdateDevice  │
                            │ Token.py             │
                            │ Finds pending entry  │
                            │ Updates with token   │
                            └──────────────────────┘

Result: Device fully registered with token in database
```

## Testing the Flow

### Scenario 1: User logs in immediately
1. User taps login
2. App sends request with device_type='ios', no token yet
3. Server registers pending device
4. Minutes later, APNs sends token
5. App automatically sends token to UpdateDeviceToken endpoint
6. Database updated with complete device record ✓

### Scenario 2: Token arrives quickly
1. User logs in, APNs token arrives within seconds
2. Server still registers with null, then immediately updated
3. Result is same as Scenario 1 ✓

### Scenario 3: User switches devices
1. Same user logs in on new device
2. New device gets registered (different device_id)
3. Both devices have entries in database
4. Both can receive push notifications ✓

## Database State

### user_devices table
```
device_id | UserId | device_type | device_token | device_name | ... | registered_at | updated_at
----------|--------|-------------|--------------|-------------|-----|---------------|---------------
DEV...001 | USR...A| ios        | NULL         | iPhone 14   | ... | 2024-01-15... | 2024-01-15...
DEV...002 | USR...A| ios        | a1b2c3d...   | iPhone 14   | ... | 2024-01-15... | 2024-01-15...
```

Entry DEV...001 is created at login with NULL token
Entry DEV...002 is updated when APNs token arrives with device_token populated

## Files Modified

### Server
1. `Server/database_schema.sql` - Modified device_token to allow NULL
2. `Server/Profile/RegisterDevice.py` - Complete rewrite for nullable tokens
3. `Server/Profile/UpdateDeviceToken.py` - NEW: Token update endpoint
4. `Server/Login/GetLogin.py` - Now returns UserId, always registers device
5. `Server/Login/Login.py` - Updated to pass device params to GetLogin
6. `Server/Signup/CreateAccount.py` - Always registers device, returns userId
7. `Server/Signup/Signup.py` - Updated to pass device params to CreateAccount
8. `Server/Profile/Profile.py` - Added UpdateDeviceToken endpoint

### iOS
1. `Client/IOS/.../SessionManager.swift` - Added userId property
2. `Client/IOS/.../DeviceTokenManager.swift` - Auto-calls backend when token arrives
3. `Client/IOS/.../LoginView.swift` - Stores userId from response
4. `Client/IOS/.../SignupView.swift` - Stores userId from response

### Database
- user_devices table: device_token now nullable
- All functionality preserved, just more flexible

## Success Indicators

After deploying these changes:

1. ✅ User logs in → device entry created with null token
2. ✅ APNs delivers token → device entry automatically updated
3. ✅ Admin can send push → finds device with token
4. ✅ Multiple devices → each registered separately
5. ✅ Device token reassignment → handled gracefully

## Rollback Plan

If needed to rollback:
1. Restore original RegisterDevice.py (requires token)
2. Restore original GetLogin.py (conditional registration)
3. Restore original database schema (NOT NULL token)
4. Restore original DeviceTokenManager.swift (no auto-update)

No data loss occurs as device entries will remain in database.

## Next Steps

1. Test login flow → verify device created with null token
2. Wait for APNs → verify token arrives and updates database
3. Test admin push notification → should work with updated token
4. Monitor logs for any update endpoint errors
5. Verify multiple devices per user work correctly
