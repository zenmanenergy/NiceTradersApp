# Dashboard View - State Matrix

## View: DashboardView
Displays all active negotiations/exchanges for the current user.

---

## Situation 1: Buyer Proposes Time - Seller Not Yet Responded

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: NULL
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - (none)

listing_payments:
  - (none)
```

### Dashboard - Buyer View
```
Status: "⏳ Waiting for Acceptance"
Subtitle: "Waiting for seller to accept meeting time"
Action Badge: None
Icon: Hourglass
Color: Orange/Yellow
Tap Action: Open MeetingDetailView with Time section showing "Cancel Proposal" button
```

### Dashboard - Seller View
```
Status: "🎯 Action Required"
Subtitle: "Accept or counter meeting time"
Action Badge: "1 action needed"
Icon: Alert/Bell
Color: Red/Urgent
Tap Action: Open MeetingDetailView with Time section showing "Accept/Counter/Reject" buttons
```

---

## Situation 2: Seller Accepted Time - No Payments Yet

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: 2025-12-14 04:23:44  ← ACCEPTED
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - (none)

listing_payments:
  - (none)
```

### Dashboard - Buyer View
```
Status: "✅ Payment Required"
Subtitle: "Please pay $2.00 to proceed"
Action Badge: "Payment needed"
Icon: CreditCard
Color: Blue
Tap Action: Open MeetingDetailView with Payment section showing "Confirm Payment" button
```

### Dashboard - Seller View
```
Status: "✅ Payment Required"
Subtitle: "Please pay $2.00 to proceed"
Action Badge: "Payment needed"
Icon: CreditCard
Color: Blue
Tap Action: Open MeetingDetailView with Payment section showing "Confirm Payment" button
```

---

## Situation 3: Both Paid - Before Location Proposed

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: 2025-12-14 04:23:44
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - (none)

listing_payments:
  - buyer_paid_at: 2025-12-13 20:05:39
  - seller_paid_at: 2025-12-13 19:50:01
```

### Dashboard - Buyer View
```
Status: "✅ Ready to Meet"
Subtitle: "Propose a meeting location"
Action Badge: None
Icon: MapPin
Color: Green
Tap Action: Open MeetingDetailView with Location section showing "Propose Location" button
```

### Dashboard - Seller View
```
Status: "✅ Ready to Meet"
Subtitle: "Waiting for location proposal"
Action Badge: None
Icon: MapPin
Color: Green
Tap Action: Open MeetingDetailView with Location section showing "Propose Location" button
```

---

## Situation 4: Buyer Proposed Location - Seller Not Yet Responded

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: 2025-12-14 04:23:44
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - meeting_location_name: IKEA
  - meeting_location_lat: 37.7827819
  - meeting_location_lng: -122.4086487
  - accepted_at: NULL
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_payments:
  - buyer_paid_at: 2025-12-13 20:05:39
  - seller_paid_at: 2025-12-13 19:50:01
```

### Dashboard - Buyer View
```
Status: "⏳ Waiting for Location Approval"
Subtitle: "Waiting for seller to accept IKEA"
Action Badge: None
Icon: Hourglass
Color: Orange/Yellow
Tap Action: Open MeetingDetailView with Location section showing "View Details/Counter" buttons
```

### Dashboard - Seller View
```
Status: "🎯 Action Required"
Subtitle: "Accept or counter location: IKEA"
Action Badge: "1 action needed"
Icon: Alert/Bell
Color: Red/Urgent
Tap Action: Open MeetingDetailView with Location section showing "Accept/Counter" buttons
```

---

## Situation 5: Seller Proposed Location - Buyer Not Yet Responded

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: 2025-12-14 04:23:44
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - meeting_location_name: Ferry Building
  - meeting_location_lat: 37.7854
  - meeting_location_lng: -122.4762
  - accepted_at: NULL
  - rejected_at: NULL
  - proposed_by: SELLER_ID  ← SELLER PROPOSED

listing_payments:
  - buyer_paid_at: 2025-12-13 20:05:39
  - seller_paid_at: 2025-12-13 19:50:01
```

### Dashboard - Buyer View
```
Status: "🎯 Action Required"
Subtitle: "Accept or counter location: Ferry Building"
Action Badge: "1 action needed"
Icon: Alert/Bell
Color: Red/Urgent
Tap Action: Open MeetingDetailView with Location section showing "Accept/Counter" buttons
```

### Dashboard - Seller View
```
Status: "⏳ Waiting for Location Approval"
Subtitle: "Waiting for buyer to accept Ferry Building"
Action Badge: None
Icon: Hourglass
Color: Orange/Yellow
Tap Action: Open MeetingDetailView with Location section showing "View Details/Counter" buttons
```

---

## Situation 6: Both Time and Location Accepted - Ready to Meet

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: 2025-12-14 04:23:44
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - meeting_location_name: IKEA
  - meeting_location_lat: 37.7827819
  - meeting_location_lng: -122.4086487
  - accepted_at: 2025-12-14 05:30:00  ← ACCEPTED
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_payments:
  - buyer_paid_at: 2025-12-13 20:05:39
  - seller_paid_at: 2025-12-13 19:50:01
```

### Dashboard - Buyer View
```
Status: "✅ Ready to Meet"
Subtitle: "Time: 2025-12-14 03:23:44 | Location: IKEA"
Action Badge: None
Icon: CheckCircle
Color: Green
Tap Action: Open MeetingDetailView with Rating section for final confirmation
```

### Dashboard - Seller View
```
Status: "✅ Ready to Meet"
Subtitle: "Time: 2025-12-14 03:23:44 | Location: IKEA"
Action Badge: None
Icon: CheckCircle
Color: Green
Tap Action: Open MeetingDetailView with Rating section for final confirmation
```

---

## Situation 7: Exchange Completed - Both Rated

### Database State
```
listing_meeting_time:
  - meeting_time: 2025-12-14 03:23:44
  - accepted_at: 2025-12-14 04:23:44
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_meeting_location:
  - meeting_location_name: IKEA
  - meeting_location_lat: 37.7827819
  - meeting_location_lng: -122.4086487
  - accepted_at: 2025-12-14 05:30:00
  - rejected_at: NULL
  - proposed_by: BUYER_ID

listing_payments:
  - buyer_paid_at: 2025-12-13 20:05:39
  - seller_paid_at: 2025-12-13 19:50:01

ratings:
  - from_user_id: BUYER_ID
  - to_user_id: SELLER_ID
  - rating: 5
  - comment: "Great exchange!"

listings:
  - status: completed
```

### Dashboard - Buyer View
```
Status: "✅ Completed"
Subtitle: "Rated 5★ - Great exchange!"
Action Badge: None
Icon: CheckCircle
Color: Gray (archived)
Section: "Completed Exchanges"
Tap Action: Open MeetingDetailView (read-only, for review)
```

### Dashboard - Seller View
```
Status: "✅ Completed"
Subtitle: "Rated 5★ by buyer"
Action Badge: None
Icon: CheckCircle
Color: Gray (archived)
Section: "Completed Exchanges"
Tap Action: Open MeetingDetailView (read-only, for review)
```

---

## Dashboard Status Legend

| Status | Color | Meaning | User Action |
|--------|-------|---------|-------------|
| "🎯 Action Required" | Red | User must respond to a proposal | Accept/Counter/Reject |
| "⏳ Waiting for..." | Orange | Waiting for other user to respond | Wait or Counter |
| "✅ Ready to Meet" | Green | All terms agreed, ready to meet | Proceed |
| "✅ Payment Required" | Blue | Time accepted, need to pay fee | Make Payment |
| "✅ Completed" | Gray | Exchange finished and rated | Archive/Review |

---

## Database Query to Determine Dashboard Status

```python
def get_dashboard_status(listing_id, current_user_id):
    # Determine user role
    is_buyer = listing.buyer_id == current_user_id
    is_seller = listing.user_id == current_user_id
    
    # Check time status
    time_proposal = get_latest_time_proposal(listing_id)
    time_accepted = time_proposal.accepted_at is not None
    time_rejected = time_proposal.rejected_at is not None
    time_proposed_by_me = time_proposal.proposed_by == current_user_id
    
    # Check location status
    location_proposal = get_latest_location_proposal(listing_id)
    location_accepted = location_proposal.accepted_at is not None if location_proposal else False
    location_pending = location_proposal and location_proposal.accepted_at is None
    location_proposed_by_me = location_proposal.proposed_by == current_user_id if location_proposal else False
    
    # Check payment status
    payment = get_payment(listing_id)
    user_paid = (payment.buyer_paid_at if is_buyer else payment.seller_paid_at) is not None
    other_user_paid = (payment.seller_paid_at if is_buyer else payment.buyer_paid_at) is not None
    both_paid = user_paid and other_user_paid
    
    # Determine status
    if not time_accepted:
        if time_proposed_by_me:
            return "⏳ Waiting for Acceptance"
        else:
            return "🎯 Action Required"  # Accept/Counter/Reject time
    
    elif time_accepted and not both_paid:
        return "✅ Payment Required"
    
    elif time_accepted and both_paid:
        if not location_proposal:
            return "✅ Ready to Meet"  # Need to propose location
        
        elif location_pending:
            if location_proposed_by_me:
                return "⏳ Waiting for Location Approval"
            else:
                return "🎯 Action Required"  # Accept/Counter location
        
        elif location_accepted:
            return "✅ Ready to Meet"
    
    return "⏳ In Progress"
```

