# APN Messages - Quick Reference Card

## 🚀 How to Send a Notification

### Basic Pattern
```python
from Admin.NotificationService import notification_service

notification_service.send_NOTIFICATION_TYPE(
    recipient_id="user_id",
    # required params...
)
```

---

## 📋 All 6 Notification Types

### 1. Payment Received
```python
notification_service.send_payment_received_notification(
    seller_id="user_456",
    buyer_name="Ahmed",
    amount=50.00,
    currency="AED",
    listing_id="listing_789"
)
```

### 2. Meeting Proposed
```python
notification_service.send_meeting_proposal_notification(
    recipient_id="user_123",
    proposer_name="Sarah",
    proposed_time="Nov 29 at 2:00 PM",
    listing_id="listing_789",
    proposal_id="proposal_456"
)
```

### 3. Message Received
```python
notification_service.send_message_received_notification(
    recipient_id="user_123",
    sender_name="John",
    message_preview="Hey, are you still...",
    listing_id="listing_789",
    message_id="msg_123"
)
```

### 4. Listing Status Changed
```python
notification_service.send_listing_status_notification(
    seller_id="user_456",
    listing_id="listing_789",
    status='flagged',  # or 'removed', 'expired', 'reactivated'
    reason="Duplicate listing"  # optional
)
```

### 5. Rating Received
```python
notification_service.send_rating_received_notification(
    user_id="user_123",
    rater_name="Ahmed",
    rating=5,
    listing_id="listing_789"
)
```

### 6. Negotiation Proposed
```python
notification_service.send_negotiation_proposal_notification(
    seller_id="user_456",
    buyer_name="Ahmed",
    proposed_time="2024-12-01T14:00:00Z",
    listing_id="listing_789",
    negotiation_id="neg_123"
)
```

---

## ✨ What Happens Automatically

When you call any notification method:

1. ✓ **User language detected** from database
2. ✓ **Session ID fetched** for auto-login
3. ✓ **Title translated** to user's language
4. ✓ **Body translated** to user's language
5. ✓ **Deep link configured** (opens correct screen)
6. ✓ **Sent to Apple APNs**
7. ✓ **Delivered to device**
8. ✓ **User auto-logged in** when tapped
9. ✓ **Correct screen opened** based on link type

**You don't need to do anything else!**

---

## 🌐 Supported Languages

| Code | Language | ✓ |
|------|----------|---|
| en | English | ✓ |
| ja | 日本語 | ✓ |
| es | Español | ✓ |
| fr | Français | ✓ |
| de | Deutsch | ✓ |
| ar | العربية | ✓ |
| hi | हिन्दी | ✓ |
| pt | Português | ✓ |
| ru | Русский | ✓ |
| sk | Slovenčina | ✓ |
| zh | 中文 | ✓ |

---

## 🔍 What Gets Translated

### Payment Notification Example

**English (en):**
- Title: "Payment received"
- Body: "Ahmed purchased contact access for your listing (50.00 AED)"

**Arabic (ar):**
- Title: "تم استلام الدفع"
- Body: "قام أحمد بشراء الوصول لبيانات الاتصال الخاصة بك (50.00 AED)"

**Japanese (ja):**
- Title: "支払い受け取り"
- Body: "アーメドがあなたのリスティングの連絡先情報へのアクセスを購入しました (50.00 AED)"

---

## 📍 Deep Link Destinations

| Type | Opens | Example |
|------|-------|---------|
| `listing` | Listing detail view | listing_id = "list_789" |
| `message` | Message thread | message_id = "msg_123" |
| `meeting` | Meeting proposal details | proposal_id = "meet_456" |
| `negotiation` | Negotiation details | negotiation_id = "neg_789" |

---

## ✅ Checklist Before Sending

- [ ] Import: `from Admin.NotificationService import notification_service`
- [ ] Choose notification type (payment, message, meeting, etc.)
- [ ] Pass all required parameters
- [ ] **DON'T** pass `session_id` - it's auto-fetched
- [ ] Test with different user languages
- [ ] Verify notification appears on iOS device
- [ ] Check deep linking works (tapping notification opens correct screen)

---

## ❌ Common Mistakes to AVOID

### ❌ WRONG:
```python
from NotificationService import notification_service
# ❌ Missing Admin module
```

### ✅ CORRECT:
```python
from Admin.NotificationService import notification_service
# ✓ Full path with Admin module
```

---

### ❌ WRONG:
```python
notification_service.send_payment_received_notification(
    seller_id="user_456",
    buyer_name="Ahmed",
    amount=50.00,
    currency="AED",
    listing_id="listing_789",
    session_id="sess_xyz"  # ❌ Don't pass this
)
```

### ✅ CORRECT:
```python
notification_service.send_payment_received_notification(
    seller_id="user_456",
    buyer_name="Ahmed",
    amount=50.00,
    currency="AED",
    listing_id="listing_789"
    # ✓ Session ID is fetched automatically
)
```

---

## 🧪 Test Your Notification

1. **Make payment** → Payment notification sent
2. **Check device** → Notification appears in Arabic/English/etc based on user language
3. **Tap notification** → App opens listing with auto-login
4. **Verify** → User can see listing details without logging in again

---

## 📞 Troubleshooting

### Notification not received?
1. Check device token: `SELECT * FROM user_devices WHERE user_id = 'X'`
2. Verify `device_token` is NOT NULL
3. Check user granted notification permissions

### Wrong language?
1. Check user language: `SELECT SettingsJson FROM user_settings WHERE user_id = 'X'`
2. Verify translation exists: `SELECT * FROM translations WHERE translation_key = 'X'`

### Deep linking not working?
1. Check SessionManager has sessionId
2. Verify AppDelegate `handleNotificationTap()` is called
3. Check deep link type is correct (listing, message, meeting, negotiation)

---

## 📊 Database Schema

### translations table (required)
```sql
translation_key      VARCHAR(255)  -- e.g., "PAYMENT_RECEIVED"
language_code        VARCHAR(5)    -- e.g., "en", "ja", "ar"
translation_value    TEXT          -- e.g., "Payment received"
```

### user_devices table (required)
```sql
device_token         VARCHAR(255)  -- APNs device token
user_id             VARCHAR(255)  -- User ID
device_type         VARCHAR(50)   -- "ios", "android"
```

### user_settings table (required)
```sql
SettingsJson        JSON          -- {"language": "en"}
```

### usersessions table (required)
```sql
SessionId           VARCHAR(255)
UserId             VARCHAR(255)
DateAdded          DATETIME
```

---

## 🎯 Key Parameters by Type

| Type | seller_id | recipient_id | buyer_name | proposer_name | amount | currency | status | rating |
|------|-----------|--------------|------------|---------------|--------|----------|--------|--------|
| Payment | ✓ | - | ✓ | - | ✓ | ✓ | - | - |
| Meeting | - | ✓ | - | ✓ | - | - | - | - |
| Message | - | ✓ | ✓ | - | - | - | - | - |
| Listing | ✓ | - | - | - | - | - | ✓ | - |
| Rating | - | (use user_id) | ✓ | - | - | - | - | ✓ |
| Negotiation | ✓ | - | ✓ | - | - | - | - | - |

---

## 📖 Full Documentation

For detailed information, see:
- **APN_MESSAGES_IMPLEMENTATION.md** - Technical details
- **APN_MESSAGES_WHERE_TO_USE.md** - When to send each type
- **APN_MESSAGES_VISUAL_FLOW.md** - Architecture & flow diagrams

---

**Quick Reference Version 1.0**
**Date:** November 29, 2025
**Status:** ✅ Production Ready
