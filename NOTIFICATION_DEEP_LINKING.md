# Notification Deep Linking with Auto-Login Implementation

## Overview
Push notifications now include session IDs for automatic login and deep linking to specific screens in the app.

## Changes Made

### Backend (Python/Flask)

#### 1. Admin.py - `/Admin/SendApnMessage` Endpoint
- **Added**: Automatic session ID fetching from the latest user session
- **Feature**: Retrieves the user's current session ID and includes it in the notification payload
- **Debug Info**: Shows `session_id_sent` in the response for verification

```python
# Get the user's latest session ID for auto-login
cursor.execute(
    "SELECT SessionId FROM usersessions WHERE UserId = %s ORDER BY DateAdded DESC LIMIT 1",
    (user_id,)
)
session_id = session_result['SessionId'] if session_result else None

result = apn_service.send_notification(
    ...
    session_id=session_id  # Auto-include session ID for auto-login
)
```

#### 2. NotificationService.py - All Notification Methods
Made all `session_id` parameters optional and auto-fetch if not provided:

- `send_payment_received_notification()`
- `send_meeting_proposal_notification()`
- `send_message_received_notification()`
- `send_listing_status_notification()`
- `send_rating_received_notification()`
- `send_negotiation_proposal_notification()`

**Pattern**:
```python
def send_*_notification(self, ..., session_id=None):
    if not session_id:
        session_id = self.get_user_session(user_id)
    
    return self.apn_service.send_notification(
        ...
        session_id=session_id,
        deep_link_type='listing',  # or message, meeting, negotiation
        deep_link_id=id
    )
```

#### 3. APNService.py - Notification Payload
The notification payload includes:

```json
{
  "aps": {
    "alert": {
      "title": "...",
      "body": "..."
    },
    "badge": 1,
    "sound": "default"
  },
  "sessionId": "USER_SESSION_ID",
  "deepLinkType": "listing|message|meeting|negotiation",
  "deepLinkId": "RESOURCE_ID",
  "timestamp": "ISO_TIMESTAMP"
}
```

### iOS App (Swift/SwiftUI)

#### 1. AppDelegate.swift - Notification Handlers
Added two new functions:

**`didReceiveRemoteNotification(_:fetchCompletionHandler:)`**
- Processes incoming notifications
- Calls `handleNotificationTap()` to extract session ID and deep link

**`handleNotificationTap(userInfo:)`**
- Extracts `sessionId` from payload and stores in `SessionManager`
- Extracts `deepLinkType` and `deepLinkId`
- Posts `DeepLinkNotification` to trigger app navigation
- **Auto-login**: Session ID is set before navigation happens

```swift
if let sessionId = userInfo["sessionId"] as? String {
    SessionManager.shared.sessionId = sessionId  // Auto-login
}

NotificationCenter.default.post(
    name: NSNotification.Name("DeepLinkNotification"),
    object: nil,
    userInfo: [
        "deepLinkType": deepLinkType,
        "deepLinkId": deepLinkId,
        "sessionId": sessionId ?? ""
    ]
)
```

#### 2. ContentView.swift - Deep Link Navigation
Added notification observer for deep link handling:

**State Variables**:
- `@State private var deepLinkPath: String?` - Tracks current deep link

**Observer**:
```swift
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeepLinkNotification"))) { notification in
    // User is already logged in via sessionId
    // Navigate to the appropriate screen
    navigateToDeepLink(type: deepLinkType, id: deepLinkId)
}
```

**Navigation Function**:
```swift
func navigateToDeepLink(type: String, id: String) {
    switch type {
    case "listing":
        deepLinkPath = "/listing/\(id)"
    case "message":
        deepLinkPath = "/message/\(id)"
    case "meeting":
        deepLinkPath = "/meeting/\(id)"
    case "negotiation":
        deepLinkPath = "/negotiation/\(id)"
    default:
        break
    }
    navigateToDashboard = true
}
```

## User Flow

1. **Server sends notification**: Backend includes session ID + deep link data
2. **User taps notification**: iOS handles it in AppDelegate
3. **Session auto-login**: `SessionManager.shared.sessionId` is set from notification payload
4. **Deep link navigation**: App navigates to the specific screen
5. **User is logged in and viewing relevant content**

## Example Notification Payload

```json
{
  "aps": {
    "alert": {
      "title": "New Message",
      "body": "John sent you a message"
    },
    "badge": 1,
    "sound": "default"
  },
  "sessionId": "session_abc123xyz",
  "deepLinkType": "message",
  "deepLinkId": "msg_def456",
  "timestamp": "2025-11-28T12:34:56.789Z"
}
```

## Usage Examples

### Sending notification with auto-login and deep link:
```python
notification_service.send_message_received_notification(
    recipient_id="USR123",
    sender_name="John",
    message_preview="Hello there!",
    listing_id="LIST456",
    message_id="MSG789"
    # session_id not needed - auto-fetched!
)
```

### Via Admin endpoint:
```
GET /Admin/SendApnMessage?user_id=USR123&title=Hello&body=Message&device_id=DEV456
```

The endpoint will:
1. Fetch the user's latest session ID
2. Include it in the notification
3. Return debug info showing `session_id_sent`

## Benefits

- **Seamless UX**: Users don't need to log in again when tapping notification
- **Direct Navigation**: Users go straight to the relevant content
- **Automatic**: Session IDs are fetched automatically (backward compatible)
- **Secure**: Session IDs are user-specific and time-based
- **Flexible**: Can still send notifications without deep links
