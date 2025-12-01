# APN Messages Quick Reference - Where to Use Them

## When & Where to Send Notifications

### 1. **Payment Notifications**
**When to send:**
```python
# File: Server/Contact/PurchaseContactAccess.py
notification_service.send_payment_received_notification(
    seller_id=seller_user_id,
    buyer_name=buyer_name,
    amount=amount,
    currency=currency,
    listing_id=listing_id
)
```

**Triggered by:** 
- User purchases contact access from seller
- Payment is processed successfully

**What the seller sees:**
- 🔔 Notification title: "Payment received"
- 💬 Message: "{Buyer} purchased contact access for your listing ($50.00)"
- 👆 Opens: Seller's listing details

---

### 2. **Meeting Proposal Notifications**
**When to send:**
```python
# File: Server/Meeting/ProposeMeeting.py
notification_service.send_meeting_proposal_notification(
    recipient_id=recipient_user_id,
    proposer_name=proposer_name,
    proposed_time=formatted_meeting_time,
    listing_id=listing_id,
    proposal_id=proposal_id
)
```

**Triggered by:**
- User proposes a meeting time
- Buyer clicks "Propose Meeting"

**What the recipient sees:**
- 🔔 Notification title: "Meeting proposed"
- 💬 Message: "{Person} proposed a meeting time: Nov 29 at 2:00 PM"
- 👆 Opens: Meeting proposal details

---

### 3. **Message Notifications**
**When to send:**
```python
# File: Server/Contact/SendInterestMessage.py
notification_service.send_message_received_notification(
    recipient_id=recipient_user_id,
    sender_name=sender_name,
    message_preview=message_text[:50],
    listing_id=listing_id,
    message_id=message_id
)
```

**Triggered by:**
- User sends message to another user
- Message is stored in database

**What the recipient sees:**
- 🔔 Notification title: "New message"
- 💬 Message: "{Sender} sent you a message: Hey, are you still selling..."
- 👆 Opens: Message conversation

---

### 4. **Listing Status Notifications**
**When to send:**
```python
# File: Server/Admin/Admin.py or any listing management code
notification_service.send_listing_status_notification(
    seller_id=seller_user_id,
    listing_id=listing_id,
    status='flagged',  # or 'removed', 'expired', 'reactivated'
    reason="Duplicate listing detected"
)
```

**Triggered by:**
- Admin flags listing for review
- Admin removes listing
- Listing expires after 30 days
- Seller reactivates expired listing

**Supported statuses:**
- `'flagged'` → Shows: "Your listing has been flagged for review"
- `'removed'` → Shows: "Your listing has been removed"
- `'expired'` → Shows: "Your listing has expired"
- `'reactivated'` → Shows: "Your listing is active again"

**What the seller sees:**
- 🔔 Notification title: Status message (localized)
- 💬 Message: Optional reason provided, or default message
- 👆 Opens: Listing details

---

### 5. **Rating Notifications**
**When to send:**
```python
# File: Server/Contact/LeaveRating.py or similar
notification_service.send_rating_received_notification(
    user_id=rated_user_id,
    rater_name=rater_name,
    rating=5,  # 1-5 stars
    listing_id=listing_id
)
```

**Triggered by:**
- User completes transaction and leaves rating
- Rating is saved to database

**What the user sees:**
- 🔔 Notification title: "You received a rating"
- 💬 Message: "{Rater} gave you a 5-star rating ⭐⭐⭐⭐⭐"
- 👆 Opens: User's profile or listing details

---

### 6. **Negotiation Proposal Notifications**
**When to send:**
```python
# File: Server/Negotiations/ProposeNegotiation.py
notification_service.send_negotiation_proposal_notification(
    seller_id=seller_user_id,
    buyer_name=buyer_name,
    proposed_time=negotiation_datetime,
    listing_id=listing_id,
    negotiation_id=negotiation_id
)
```

**Triggered by:**
- Buyer proposes price negotiation
- Buyer suggests meeting time

**What the seller sees:**
- 🔔 Notification title: "New negotiation proposal"
- 💬 Message: "{Buyer} wants to meet on Nov 29 at 2:00 PM"
- 👆 Opens: Negotiation details

---

## Implementation Checklist

When adding APN messages to any feature:

- [ ] Import NotificationService
- [ ] Determine notification type (payment, message, meeting, etc.)
- [ ] Call appropriate `send_*_notification()` method
- [ ] Pass all required parameters (user_id, names, amounts, etc.)
- [ ] Don't pass `session_id` - it's fetched automatically
- [ ] Verify translations exist in database for the message type
- [ ] Test with different user language preferences
- [ ] Check notification appears on iOS with correct language

## Required Parameters by Type

| Notification Type | Required Parameters |
|------------------|-------------------|
| Payment | seller_id, buyer_name, amount, currency, listing_id |
| Meeting | recipient_id, proposer_name, proposed_time, listing_id, proposal_id |
| Message | recipient_id, sender_name, message_preview, listing_id, message_id |
| Listing Status | seller_id, listing_id, status, (optional reason) |
| Rating | user_id, rater_name, rating (1-5), listing_id |
| Negotiation | seller_id, buyer_name, proposed_time, listing_id, negotiation_id |

## Auto-Login & Deep Linking

Every notification automatically:
1. **Logs in** the user (session ID is included)
2. **Navigates** to the relevant screen:
   - `'listing'` → Listing detail view
   - `'message'` → Message thread
   - `'meeting'` → Meeting proposal details
   - `'negotiation'` → Negotiation details

No additional code needed in the backend - it's all automatic!

## Language Support

All notifications automatically display in the user's language:
- Fetches from `user_settings.SettingsJson`
- Falls back to English if language not configured
- Supports: English, Japanese, Spanish, French, German, Arabic, Hindi, Portuguese, Russian, Slovak, Chinese

## Example: Complete Flow

### 1. Buyer purchases contact access
```python
# In PurchaseContactAccess.py
notification_service.send_payment_received_notification(
    seller_id="seller_123",
    buyer_name="Ahmed",
    amount=45.50,
    currency="AED",
    listing_id="listing_789"
)
```

### 2. Seller receives notification
- iPhone shows: "Payment received"
- Message: "Ahmed purchased contact access for your listing (45.50 AED)"
- Language: Seller's preferred language (auto-detected)

### 3. Seller taps notification
- Session ID auto-logs user in
- App navigates to listing #789 details
- Seller can see full listing and contact Ahmed

**All automatic - no additional coding needed!**
