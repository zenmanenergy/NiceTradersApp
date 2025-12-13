# Nice Traders Negotiation Workflow

## Overview
This document outlines the complete end-to-end workflow for a negotiation between two users, from listing creation through meeting preparation.

---

## Phase 1: Listing Creation

### User A - Creates Listing
- [x] AI verified | [ ] Human verified
- User A creates a listing with currency pair (e.g., 100 USD → 86 EUR)
- Listing is created in the `listings` table

### User A - Dashboard: Active Listings
- [x] AI verified | [ ] Human verified
- User A can see their listing in the **Active Listings** section on the Dashboard
- Listing is visible because User A is the seller/creator

### User A - Search: Cannot See Own Listing
- [x] AI verified | [ ] Human verified
- When User A searches for listings, their own listing is **NOT** shown in results
- Filter applied: exclude current user's listings from search results

---

## Phase 2: Search & Proposal

### User B - Searches for Listing
- [ ] AI verified | [ ] Human verified
- User B performs a search and finds User A's listing
- Listing details are displayed with exchange rate, amount, and location

### User B - Proposes Date/Time
- [ ] AI verified | [ ] Human verified
- User B clicks "Propose time & location" on the listing
- User B is redirected to **ProposeTimeView**
- User B selects a date and time for the meeting
- User B submits the proposal
- `listing_meeting_time` table is updated with:
  - `proposed_by`: User B's ID
  - `proposed_at`: Current timestamp
  - `accepted_at`: NULL (not yet accepted)

### User B - Dashboard: Active Exchanges
- [ ] AI verified | [ ] Human verified
- User B sees the listing in **Active Exchanges** section
- **Status**: "⏳ Waiting for Acceptance"
- The proposed meeting time is displayed

### User B - Meeting Detail View
- [ ] AI verified | [ ] Human verified
- User B can click on the listing to view details
- Button available: **"Cancel Proposal"**
- User B can cancel their time proposal at this stage

---

## Phase 3: Seller Acceptance/Counter

### User A - Dashboard: Active Exchanges
- [ ] AI verified | [ ] Human verified
- User A sees the listing in **Active Exchanges** section
- **Status**: "🎯 Action: Acceptance"
- The proposed meeting time is displayed

### User A - Actions Available
- [ ] AI verified | [ ] Human verified
User A has three options:

#### Option 1: Accept the Proposal
- [ ] AI verified | [ ] Human verified
- User A clicks **"Accept"** button
- `listing_meeting_time.accepted_at` is updated with current timestamp
- Workflow moves to **Phase 4: Payment**

#### Option 2: Counter the Proposal
- [ ] AI verified | [ ] Human verified
- User A clicks **"Counter Proposal"** button
- User A is redirected to **ProposeTimeView**
- User A selects a different date/time
- `listing_meeting_time` is updated with:
  - `proposed_by`: User A's ID
  - `proposed_at`: Current timestamp
  - `accepted_at`: NULL (reset, awaiting User B's response)
- Dashboard status for **User A**: "⏳ Waiting for Acceptance"
- Dashboard status for **User B**: "🎯 Action: Acceptance"
- Time proposals continue to go back and forth until one party accepts

#### Option 3: Cancel the Listing
- [ ] AI verified | [ ] Human verified
- User A can **cancel the listing** at any time **UNLESS someone has already paid**
- When cancelled:
  - `listings` row is **deleted** or marked as inactive
  - `listing_meeting_time` row is **deleted**
  - Negotiation ends

### User A - Meeting Detail View
- [ ] AI verified | [ ] Human verified
- While time is not yet accepted:
  - Button available: **"Cancel Proposal"**
  - This allows User A to remove the counter-proposal

---

## Phase 4: Payment

### Both Users - Dashboard Status Update
- [ ] AI verified | [ ] Human verified
- Once **both** time proposals are settled and User A has accepted:
- Dashboard status for **both User A and User B**: "🎯 Action: Payment"

### User B - Payment View
- [ ] AI verified | [ ] Human verified
- User B sees **"Payment Required"** or similar message
- Fee amount: **$2.00**
- User B clicks **"Confirm Payment"**
- Payment is processed
- `listing_payments` table is updated/inserted with:
  - `listing_id`: The negotiation listing ID
  - `buyer_paid_at`: Current timestamp
  - `seller_paid_at`: NULL (User A hasn't paid yet)

### User A - Payment View
- [ ] AI verified | [ ] Human verified
- User A sees **"Payment Required"** message
- Fee amount: **$2.00**
- User A clicks **"Confirm Payment"**
- Payment is processed
- `listing_payments` table is updated with:
  - `seller_paid_at`: Current timestamp

### Both Users - Payment Complete
- [ ] AI verified | [ ] Human verified
- Once **both** have paid the $2 fee:
- `listing_payments.buyer_paid_at` AND `listing_payments.seller_paid_at` are both set
- Dashboard status for **both User A and User B**: "🎯 Action: Propose Location"

---

## Phase 5: Location Negotiation

### Either User - Propose Location
- [ ] AI verified | [ ] Human verified
- User A or User B can initiate location proposal
- User is redirected to **MeetingLocationView**
- User searches for a location on the map
- User clicks on a location to propose it
- `listing_meeting_location` table is updated with:
  - `proposed_by`: Current user's ID
  - `proposed_location`: Latitude, Longitude, or location string
  - `proposed_at`: Current timestamp
  - `accepted_at`: NULL (awaiting approval)

### User A - Dashboard Status
- [ ] AI verified | [ ] Human verified
- If **User B proposed location**: "⏳ Accept proposed location"
- If **User A proposed location**: "⏳ Waiting for Acceptance"

### User B - Dashboard Status
- [ ] AI verified | [ ] Human verified
- If **User A proposed location**: "⏳ Accept proposed location"
- If **User B proposed location**: "⏳ Waiting for Acceptance"

### Location Counter-Proposals
- [ ] AI verified | [ ] Human verified
- Either user can counter the location proposal
- User is redirected back to **MeetingLocationView**
- User proposes a different location
- `listing_meeting_location` is updated with:
  - `proposed_by`: Current user's ID
  - `proposed_location`: New location
  - `proposed_at`: Current timestamp
  - `accepted_at`: NULL
- Location proposals continue back and forth until one party accepts

### User Accepts Location
- [ ] AI verified | [ ] Human verified
- User clicks **"Accept Location"** button
- `listing_meeting_location.accepted_at` is updated with current timestamp

### Both Locations Accepted
- [ ] AI verified | [ ] Human verified
- Once **both** time AND location are accepted:
- Dashboard status for **both User A and User B**: "⏳ Waiting for [DATE/TIME]"
  - Example: "⏳ Waiting for 12/26 at 2:30 PM"
- Meeting is confirmed and ready

---

## Phase 6: Meeting Confirmed

### Final Status
- [ ] AI verified | [ ] Human verified
- **Dashboard Status**: "⏳ Waiting for 12/26 at 2:30 PM" (or applicable date/time)
- Both users can now see:
  - Confirmed meeting date and time
  - Confirmed meeting location
  - Payment completed (✅ marks)
- Users can proceed to meet in person

---

## Database Schema Reference

### Key Tables

#### `listings`
- `listing_id`: Primary key
- `user_id`: Creator of listing
- `currency_from`: Source currency
- `currency_to`: Target currency
- `amount`: Amount being offered

#### `listing_meeting_time`
- `listing_id`: Foreign key to listings
- `proposed_by`: User ID of who proposed
- `proposed_at`: When proposal was made
- `accepted_at`: When accepted (NULL = not accepted)

#### `listing_meeting_location`
- `listing_id`: Foreign key to listings
- `proposed_by`: User ID of who proposed
- `proposed_location`: Location coordinates/string
- `proposed_at`: When proposal was made
- `accepted_at`: When accepted (NULL = not accepted)

#### `listing_payments`
- `listing_id`: Foreign key to listings
- `buyer_paid_at`: When buyer paid $2 fee (NULL = not paid)
- `seller_paid_at`: When seller paid $2 fee (NULL = not paid)

---

## Status Progression

```
LISTING CREATED
    ↓
USER B PROPOSES TIME
    ├─ User B: "⏳ Waiting for Acceptance"
    └─ User A: "🎯 Action: Acceptance"
    ↓
USER A ACCEPTS OR COUNTERS
    
If Accepted:
    ├─ User A: "🎯 Action: Payment"
    └─ User B: "🎯 Action: Payment"
    ↓
BOTH USERS PAY $2 FEE
    ├─ User A: "🎯 Action: Propose Location"
    └─ User B: "🎯 Action: Propose Location"
    ↓
LOCATION PROPOSED AND ACCEPTED
    ├─ User A: "⏳ Waiting for 12/26 at 2:30 PM"
    └─ User B: "⏳ Waiting for 12/26 at 2:30 PM"
    ↓
MEETING CONFIRMED
    └─ Ready to meet in person

If Countered (repeats until accepted):
    ├─ User A: "⏳ Waiting for Acceptance"
    └─ User B: "🎯 Action: Acceptance"
    (reverses on each counter)
```

---

## Cancel Points

### User A Can Cancel:
- [ ] AI verified | [ ] Human verified
- **Before User B pays**: Removes listing and meeting_time entries
- **After either user pays**: Cannot cancel (payment indicates commitment)

### User B Can Cancel:
- [ ] AI verified | [ ] Human verified
- **Before User A accepts**: Removes time proposal
- **After User A accepts but before either user pays**: Negotiation can be ended
- **After payment starts**: Cannot cancel (payment indicates commitment)

---

## Button Availability by Stage

| Stage | User A | User B |
|-------|--------|--------|
| Time Not Proposed | N/A | Propose |
| User B Proposed | Accept / Counter / Cancel | Cancel Proposal |
| User A Countered | Cancel Proposal | Accept / Counter / Cancel |
| Time Accepted | Pay Fee | Pay Fee |
| Both Paid | Propose Location / Accept Location | Propose Location / Accept Location |
| Location Accepted | Confirm / View Details | Confirm / View Details |

---

## Notes

- All timestamps use ISO 8601 format
- Location coordinates stored as Latitude, Longitude
- Payment fee is hardcoded as $2.00
- Once either user has paid, the listing cannot be deleted
- Time proposals go back and forth until agreement
- Location proposals go back and forth until agreement
- Meeting is only confirmed when BOTH time AND location are accepted
