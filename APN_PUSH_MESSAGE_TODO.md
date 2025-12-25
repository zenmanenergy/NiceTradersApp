# APN Push Message Implementation TODO

## Overview
This document tracks all places where APN push notifications should be sent in the Nice Traders app. These notifications are sent whenever:
1. An action happens on a listing a user is associated with
2. No action has been taken for 24 hours (daily reminder)
3. A user logs in (verify push notification settings)

---

## Phase 1: Login Verification ⭐ HIGH PRIORITY

### 1.1 Check Push Notifications Permission at Login
- **File**: `Server/Login/GetLogin.py`
- **Trigger**: User successfully logs in
- **Action Required**:
  - Check if user has enabled push notifications on their device
  - If push notifications are DISABLED, send an alert notification
  - Alert message: "Push notifications are necessary for the app to function correctly. Please enable them in Settings."
  - This should only be shown once per login session (not every request)

**Implementation Details**:
- When device logs in, check the `user_devices` table for the user's device
- Verify that device has a valid `device_token` stored
- If no token, display alert to user (in app and via in-app notification)
- Store a flag to prevent repeated alerts

---

## Phase 2: Negotiation & Meeting Actions (LISTING-RELATED)

### 2.1 ✅ EXISTING: Buyer Proposes Meeting Time
- **File**: `Server/Negotiations/ProposeNegotiation.py`
- **Status**: IMPLEMENTED
- **Recipient**: Seller
- **Trigger**: Buyer sends initial meeting time proposal
- **Message**: "{buyer_name} wants to meet on {time}"
- **Deep Link**: `negotiation:{negotiation_id}`

### 2.2 ✅ EXISTING: Seller Accepts Meeting Location Proposal
- **File**: `Server/Negotiations/AcceptProposal.py`
- **Status**: NEEDS VERIFICATION
- **Recipient**: Buyer (who proposed the location)
- **Trigger**: Seller accepts buyer's proposed meeting location
- **Message**: "Seller accepted your proposed meeting location"
- **Deep Link**: `listing:{listing_id}`

### 2.3 ❌ MISSING: Seller Rejects Meeting Location Proposal
- **File**: `Server/Negotiations/RejectMeetingLocation.py`
- **Status**: NOT IMPLEMENTED
- **Recipient**: Buyer (who proposed the location)
- **Trigger**: Seller rejects buyer's proposed meeting location
- **Message**: "Your proposed meeting location was rejected"
- **Deep Link**: `listing:{listing_id}`

### 2.4 ❌ MISSING: Buyer Proposes Alternative Meeting Location
- **File**: `Server/Meeting/ProposeMeetingLocation.py` (or similar)
- **Status**: NOT IMPLEMENTED
- **Recipient**: Seller
- **Trigger**: Buyer proposes alternative meeting location
- **Message**: "{buyer_name} proposed a different meeting location"
- **Deep Link**: `listing:{listing_id}`

### 2.5 ❌ MISSING: Buyer Rejects Meeting Location Proposal
- **File**: `Server/Meeting/RejectMeetingLocation.py`
- **Status**: NOT IMPLEMENTED
- **Recipient**: Seller
- **Trigger**: Buyer rejects seller's proposed meeting location
- **Message**: "Your proposed meeting location was rejected"
- **Deep Link**: `listing:{listing_id}`

### 2.6 ✅ EXISTING: Buyer Sends Interest Message
- **File**: `Server/Contact/SendInterestMessage.py`
- **Status**: PARTIALLY IMPLEMENTED (sends to DB, needs APN verification)
- **Recipient**: Listing owner
- **Trigger**: Buyer sends message with interest in listing
- **Message**: "{sender_name} has expressed interest in your {currency} {amount} listing"
- **Deep Link**: `message:{message_id}`

### 2.7 ❌ MISSING: Buyer Sends Counter-Proposal
- **File**: `Server/Negotiations/CounterProposal.py`
- **Status**: NOT IMPLEMENTED
- **Recipient**: Seller
- **Trigger**: Buyer sends counter-proposal (different time than seller's suggestion)
- **Message**: "{buyer_name} sent a counter-proposal for meeting time"
- **Deep Link**: `negotiation:{negotiation_id}`

### 2.8 ❌ MISSING: Seller Sends Counter-Proposal
- **File**: `Server/Negotiations/CounterProposal.py` (seller version)
- **Status**: NOT IMPLEMENTED
- **Recipient**: Buyer
- **Trigger**: Seller sends counter-proposal (different time than buyer's suggestion)
- **Message**: "Seller sent a counter-proposal for meeting time"
- **Deep Link**: `negotiation:{negotiation_id}`

---

## Phase 3: Exchange & Completion Actions

### 3.1 ✅ EXISTING: Payment Received for Contact Access
- **File**: `Server/Payments/PaymentHandler.py` or PayPal integration
- **Status**: IMPLEMENTED
- **Recipient**: Seller
- **Trigger**: Buyer has paid the negotiation fee for contact access
- **Message**: "{buyer_name} has paid the negotiation fee ({amount} {currency})"
- **Deep Link**: `listing:{listing_id}`

### 3.2 ❌ MISSING: Buyer Marks Exchange Complete
- **File**: `Server/Negotiations/CompleteExchange.py`
- **Status**: NEEDS VERIFICATION
- **Recipient**: Seller
- **Trigger**: Buyer marks their side of the exchange as complete
- **Message**: "{buyer_name} has marked their exchange as complete"
- **Deep Link**: `listing:{listing_id}`

### 3.3 ❌ MISSING: Seller Marks Exchange Complete
- **File**: `Server/Negotiations/CompleteExchange.py` (seller side)
- **Status**: NEEDS VERIFICATION
- **Recipient**: Buyer
- **Trigger**: Seller marks their side of the exchange as complete
- **Message**: "Exchange marked as complete by seller"
- **Deep Link**: `listing:{listing_id}`

### 3.4 ✅ EXISTING: Exchange Completed Notification
- **File**: `Server/Negotiations/CompleteExchange.py`
- **Status**: IMPLEMENTED
- **Recipient**: Both parties
- **Trigger**: Both buyer and seller have marked exchange complete
- **Message**: "Exchange with {partner_name} is now complete!"
- **Deep Link**: `listing:{listing_id}`

### 3.5 ❌ MISSING: Seller Cancels Listing (Buyer Impact)
- **File**: `Server/Listings/DeleteListing.py`
- **Status**: NOT IMPLEMENTED
- **Recipient**: All buyers with active negotiations on this listing
- **Trigger**: Seller deletes/cancels their listing
- **Message**: "Seller cancelled their '{listing_title}' listing"
- **Deep Link**: `dashboard:none`

### 3.6 ✅ EXISTING: Listing Status Changes (Flagged/Removed)
- **File**: `Server/Admin/NotificationService.py` (send_listing_status_notification)
- **Status**: IMPLEMENTED
- **Recipient**: Seller
- **Trigger**: Listing is flagged, removed, expired, or reactivated by admin/system
- **Message**: "Your listing was {status}"
- **Deep Link**: `listing:{listing_id}`

---

## Phase 4: User Interaction Actions

### 4.1 ✅ EXISTING: Rating Received
- **File**: `Server/Ratings/SubmitRating.py`
- **Status**: IMPLEMENTED
- **Recipient**: Rated user
- **Trigger**: User receives a rating for a completed exchange
- **Message**: "{rater_name} gave you a {rating}-star rating ⭐"
- **Deep Link**: `listing:{listing_id}`

### 4.2 ❌ MISSING: Dispute/Report Filed on Listing
- **File**: `Server/Contact/ReportListing.py`
- **Status**: ADMIN NOTIFICATION ONLY (needs user notification)
- **Recipient**: Seller (listing owner)
- **Trigger**: Someone reports the listing
- **Message**: "Your listing has been reported by another user"
- **Deep Link**: `listing:{listing_id}`

### 4.3 ❌ MISSING: User Profile Review/Comment
- **File**: `Server/Profile/SubmitUserReview.py` (if exists)
- **Status**: NOT IMPLEMENTED
- **Recipient**: Reviewed user
- **Trigger**: User leaves a review/comment on another user's profile
- **Message**: "{reviewer_name} left a comment on your profile"
- **Deep Link**: `profile:{user_id}`

---

## Phase 5: Daily Reminder Notifications (24-Hour Rule)

### 5.1 ❌ MISSING: Daily Reminder - Pending Negotiations
- **File**: `Server/Admin/DailyNotificationService.py` (NEW)
- **Status**: NOT IMPLEMENTED
- **Trigger**: Once per day, if user has pending negotiation proposals with no action
- **Recipients**: 
  - Seller with unanswered meeting time proposals
  - Buyer with unanswered counter-proposals or rejected locations
- **Message**: "You have pending negotiations waiting for your response"
- **Deep Link**: `dashboard:negotiations`
- **Implementation**: 
  - Create a scheduled task (using APScheduler or Celery)
  - Run daily at 9 AM user's local timezone (or fixed UTC)
  - Check `listing_meeting_time` table for unresolved negotiations
  - Only send if no action in last 24 hours

### 5.2 ❌ MISSING: Daily Reminder - Unread Messages
- **File**: `Server/Admin/DailyNotificationService.py` (NEW)
- **Status**: NOT IMPLEMENTED
- **Trigger**: Once per day, if user has unread messages with no action
- **Recipients**: Users with unread messages
- **Message**: "You have {count} unread message(s) waiting"
- **Deep Link**: `messages:unread`
- **Implementation**: 
  - Check `messages` table for unread entries
  - Only send if no action in last 24 hours

### 5.3 ❌ MISSING: Daily Reminder - Pending Approvals
- **File**: `Server/Admin/DailyNotificationService.py` (NEW)
- **Status**: NOT IMPLEMENTED
- **Trigger**: Once per day, if seller has unapproved meeting location proposals
- **Recipients**: Sellers
- **Message**: "You have pending location approvals on your listings"
- **Deep Link**: `dashboard:approvals`

---

## Phase 6: Support & System Notifications

### 6.1 ❌ MISSING: Account/Payment Issues
- **File**: `Server/Account/AccountMonitoring.py` (NEW)
- **Status**: NOT IMPLEMENTED
- **Trigger**: Payment failure, account suspended, etc.
- **Recipients**: Affected user
- **Message**: "Account Alert: {issue_description}"
- **Deep Link**: `settings:account`

### 6.2 ❌ MISSING: Listing Expiration Warning
- **File**: `Server/Admin/ListingMonitoring.py` (NEW)
- **Status**: NOT IMPLEMENTED
- **Trigger**: 7 days before listing expires
- **Recipients**: Seller
- **Message**: "Your listing expires in 7 days"
- **Deep Link**: `listing:{listing_id}`

---

## Implementation Checklist

### Critical (Must Have)
- [ ] Login: Check push notification permission status
- [ ] Login: Alert if push notifications disabled
- [ ] Verify missing APN calls in existing endpoints:
  - [ ] AcceptProposal notification to buyer
  - [ ] CompleteExchange notification to both parties
  - [ ] Listing cancellation notification to affected buyers

### High Priority (Next Phase)
- [ ] RejectMeetingLocation notification
- [ ] ProposeMeetingLocation notification  
- [ ] CounterProposal notifications (both directions)
- [ ] Listing cancellation on delete
- [ ] Report/dispute notification to seller

### Medium Priority (Can Wait)
- [ ] Daily reminder service setup
- [ ] Pending negotiations reminder
- [ ] Unread messages reminder
- [ ] Pending approvals reminder

### Low Priority (Nice to Have)
- [ ] Account/payment issue alerts
- [ ] Listing expiration warnings
- [ ] Profile review notifications

---

## Database Tables Reference

### User Devices
```sql
-- Stores device tokens for push notifications
user_devices (
  device_id,
  user_id,
  device_token,
  device_type, -- 'ios', 'android'
  device_name,
  is_active,
  created_at,
  last_used_at
)
```

### Negotiations & Meetings
```sql
listing_meeting_time (
  time_negotiation_id,
  listing_id,
  buyer_id,
  proposed_by,
  meeting_time,
  accepted_at,
  rejected_at
)

listing_meeting_location (
  location_negotiation_id,
  listing_id,
  buyer_id,
  proposed_by,
  meeting_location_lat,
  meeting_location_lng,
  meeting_location_name,
  accepted_at,
  rejected_at
)
```

### Messages & Notifications
```sql
messages (
  message_id,
  listing_id,
  sender_id,
  recipient_id,
  message_type,
  message_content,
  status
)

apn_logs (
  log_id,
  user_id,
  notification_title,
  notification_body,
  device_count,
  failed_count,
  sent_at
)
```

---

## Translation Keys Needed

All notification messages must use translation keys for i18n support. Add these to database:

```
NEGOTIATION_REJECTED_LOCATION
BUYER_PROPOSED_LOCATION
COUNTER_PROPOSAL_SENT
EXCHANGE_MARKED_COMPLETE
LISTING_CANCELLED_BY_SELLER
LISTING_REPORTED
PENDING_NEGOTIATIONS_REMINDER
UNREAD_MESSAGES_REMINDER
PUSH_NOTIFICATIONS_DISABLED_ALERT
```

---

## Notes

- All notifications should be sent asynchronously to avoid blocking API responses
- Log all APN sends to `apn_logs` table for audit trail
- Include deep link data for proper in-app navigation on notification tap
- Support multi-language notifications based on user's language preference
- Test thoroughly on physical iOS device (not simulator)
- Monitor APNs certificate expiration (renew annually)
