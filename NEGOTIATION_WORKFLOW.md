# Nice Traders Negotiation Workflow

## Overview
This document outlines the complete end-to-end workflow for a negotiation between two users, from listing creation through meeting preparation.

---

## Backend Status Reference

The backend calculates status values based on timestamp states (not stored in database):

| Backend Status | Display on Dashboard | Meaning |
|---|---|---|
| `negotiating` | "🎯 Action Required" (if actionRequired=true) or "⏳ Waiting for Acceptance" (if actionRequired=false) | Time or location negotiation in progress |
| `agreed` | "✅ Payment Required" | Time and location agreed, payment pending |
| `paid_partial` | "⏳ Awaiting Payment" | One party has paid $2 fee, waiting for other |
| `paid_complete` | "✅ Ready to Meet" | Both parties paid, ready to meet |

**Status Calculation Logic:**
- `negotiating`: Time negotiation not yet accepted, or time accepted but location negotiation not yet accepted
- `agreed`: Both time and location accepted, but payment not started
- `paid_partial`: One party has paid fee, other hasn't
- `paid_complete`: Both parties have paid fee
- `rejected`: Either time or location negotiation was rejected (negotiation ended)

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
- [x] AI verified | [ ] Human verified
- User B performs a search and finds User A's listing
- Listing details are displayed with exchange rate, amount, and location
- **No dashboard activity yet** - User B hasn't engaged with the listing

### User B - Proposes Date/Time
- [x] AI verified | [ ] Human verified
- User B clicks "Propose time & location" on the listing
- User B is redirected to **ProposeTimeView**
- User B selects a date and time for the meeting
- User B submits the proposal
- `listing_meeting_time` table is created with:
  - `proposed_by`: User B's ID
  - `meeting_time`: The proposed meeting datetime
  - `created_at`: Current timestamp
  - `accepted_at`: NULL (not yet accepted)

### User B - Dashboard: Active Exchanges
- [x] AI verified | [ ] Human verified
- User B sees the listing in **Active Exchanges** section
- **Backend Status**: `negotiating` (actionRequired=false)
- **Dashboard Display**: "⏳ Waiting for Acceptance"
- The proposed meeting time is displayed

### User B - Meeting Detail View
- [x] AI verified | [ ] Human verified
- During time negotiation (before acceptance):
  - Button available: **"Cancel Proposal"**
  - User B can cancel their time proposal at this stage
- After time is accepted:
  - Buttons available: **"Pay Fee"** (if not yet paid), **"View Details"** (if payment complete)
- During location negotiation:
  - Buttons available: **"Propose Location"**, **"Accept Location"**, **"Counter Location"**

---

## Phase 3: Seller Acceptance/Counter

### User A - Dashboard: Active Exchanges
- [x] AI verified | [ ] Human verified
- User A sees the listing in **Active Exchanges** section
- **Backend Status**: `negotiating` (actionRequired=true)
- **Dashboard Display**: "🎯 Action Required"
- The proposed meeting time is displayed

### User A - Actions Available
- [x] AI verified | [ ] Human verified
User A has three options:

#### Option 1: Accept the Proposal
- [x] AI verified | [ ] Human verified
- User A clicks **"Accept"** button
- `listing_meeting_time.accepted_at` is updated with current timestamp
- **Backend Status**: Changes from `negotiating` → `agreed` (both users)
- **Dashboard Display** for User A: "✅ Payment Required"
- **Dashboard Display** for User B: "✅ Payment Required"
- Workflow moves to **Phase 4: Payment**

#### Option 2: Counter the Proposal
- [x] AI verified | [ ] Human verified
- User A clicks **"Counter Proposal"** button
- User A is redirected to **ProposeTimeView**
- User A selects a different date/time
- `listing_meeting_time` is updated with:
  - `proposed_by`: User A's ID
  - `meeting_time`: The new proposed meeting datetime
  - `updated_at`: Current timestamp
  - `accepted_at`: NULL (reset, awaiting User B's response)
- **Backend Status**: Remains `negotiating` (both users)
- **Dashboard Display** for User A: "⏳ Waiting for Acceptance"
- **Dashboard Display** for User B: "🎯 Action Required"
- Time proposals continue to go back and forth until one party accepts

#### Option 3: Cancel the Listing
- [x] AI verified | [ ] Human verified
- User A can **cancel the listing** at any time **UNLESS someone has already paid**
- When cancelled:
  - `listings` row is **deleted** or marked as inactive
  - `listing_meeting_time` row is **deleted**
  - Negotiation ends

### User A - Meeting Detail View
- [x] AI verified | [ ] Human verified
- While time is not yet accepted:
  - Buttons available: **"Accept"**, **"Counter Proposal"**, **"Cancel"**
  - **"Cancel Proposal"** removes the counter-proposal if User A countered
- After time is accepted:
  - Buttons available: **"Pay Fee"** (if not yet paid), **"View Details"** (if payment complete)
- During location negotiation:
  - Buttons available: **"Propose Location"**, **"Accept Location"**, **"Counter Location"**

---

## Phase 4: Payment

### Both Users - Dashboard Status Update
- [x] AI verified | [ ] Human verified
- Once time proposal is **accepted by User A**:
- **Backend Status**: Changes to `agreed` (both users)
- **Dashboard Display** for both User A and User B: "✅ Payment Required"
- Both users need to pay the $2 fee before proceeding

### User B (Buyer) - Payment View
- [x] AI verified | [ ] Human verified
- User B sees **"Payment Required"** or similar message
- Fee amount: **$2.00**
- User B clicks **"Confirm Payment"**
- Payment is processed
- `listing_payments` table is updated/inserted with:
  - `listing_id`: The negotiation listing ID
  - `buyer_paid_at`: Current timestamp
  - `seller_paid_at`: NULL (User A hasn't paid yet)
- If User A hasn't paid yet:
  - **Backend Status**: `paid_partial`
  - **Dashboard Display** for User B: "⏳ Awaiting Payment"
  - **Dashboard Display** for User A: "✅ Payment Required"

### User A (Seller) - Payment View
- [x] AI verified | [ ] Human verified
- User A sees **"Payment Required"** message
- Fee amount: **$2.00**
- User A clicks **"Confirm Payment"**
- Payment is processed
- `listing_payments` table is updated with:
  - `seller_paid_at`: Current timestamp
- If User B has already paid:
  - Workflow automatically advances to **Phase 5: Location Negotiation**

### Both Users - Payment Complete
- [x] AI verified | [ ] Human verified
- Once **both** have paid the $2 fee:
- **Backend Status**: Changes to `paid_complete`
- **Dashboard Display** for both User A and User B: "✅ Ready to Meet"
- `listing_payments.buyer_paid_at` AND `listing_payments.seller_paid_at` are both set
- **Dashboard Display** for both User A and User B: "✅ Ready to Meet"
- Workflow automatically advances to **Phase 5: Location Negotiation**

---

## Phase 5: Location Negotiation

### Either User - Propose Location
- [x] AI verified | [ ] Human verified
- User A or User B can initiate location proposal
- User is redirected to **MeetingLocationView**
- User searches for a location on the map
- User clicks on a location to propose it
- `listing_meeting_location` table is created with:
  - `proposed_by`: Current user's ID
  - `meeting_location_lat`: Latitude of proposed location
  - `meeting_location_lng`: Longitude of proposed location
  - `meeting_location_name`: Location name/description
  - `created_at`: Current timestamp
  - `accepted_at`: NULL (awaiting approval)
- Buttons available: **"Propose Location"** (select and submit location)
- After proposing:
  - Proposer sees: **"View Details"**, **"Counter Location"** buttons
  - Non-proposer sees: **"Accept Location"**, **"Counter Location"** buttons

### User A - Dashboard Status
- [x] AI verified | [ ] Human verified
- If **User B proposed location**: **Backend Status** `negotiating` (actionRequired=true), **Display**: "🎯 Action Required"
- If **User A proposed location**: **Backend Status** `negotiating` (actionRequired=false), **Display**: "⏳ Waiting for Acceptance"

### User B - Dashboard Status
- [x] AI verified | [ ] Human verified
- If **User A proposed location**: **Backend Status** `negotiating` (actionRequired=true), **Display**: "🎯 Action Required"
- If **User B proposed location**: **Backend Status** `negotiating` (actionRequired=false), **Display**: "⏳ Waiting for Acceptance"

### Location Counter-Proposals
- [x] AI verified | [ ] Human verified
- Either user can counter the location proposal
- User is redirected back to **MeetingLocationView**
- User proposes a different location
- `listing_meeting_location` is updated with:
  - `proposed_by`: Current user's ID
  - `meeting_location_lat`: New latitude
  - `meeting_location_lng`: New longitude
  - `meeting_location_name`: New location name
  - `updated_at`: Current timestamp
  - `accepted_at`: NULL
- **Backend Status**: Remains `negotiating` (both users)
- Dashboard statuses update:
  - Proposer's **Display**: "⏳ Waiting for Acceptance"
  - Non-proposer's **Display**: "🎯 Action Required"
- Location proposals continue back and forth until one party accepts

### User Accepts Location
- [x] AI verified | [ ] Human verified
- User clicks **"Accept Location"** button
- `listing_meeting_location.accepted_at` is updated with current timestamp
- **Backend Status**: Changes to `paid_complete` (since both time and location are now accepted, and payments already made)
- Dashboard status updates:
  - Both users: "✅ Ready to Meet"
- After accepting:
  - Buttons show **"MARK EXCHANGE COMPLETE"** (both users ready to finalize)

### Both Locations Accepted
- [x] AI verified | [ ] Human verified
- Once **both** time AND location are accepted AND both parties have paid:
- **Backend Status**: `paid_complete`
- **Dashboard Display** for both User A and User B: "✅ Ready to Meet"
- Meeting is confirmed and ready

---

## Phase 6: Meeting Confirmed

### Final Status
- [x] AI verified | [ ] Human verified
- **Backend Status**: `paid_complete`
- **Dashboard Display**: "✅ Ready to Meet"
- Both users can now see:
  - Confirmed meeting date and time
  - Confirmed meeting location
  - Payment completed (✅ marks)
  - "MARK EXCHANGE COMPLETE" button
- Users can proceed to meet in person

---

## Database Schema Reference

### Key Tables

#### `listings`
- `listing_id`: Primary key
- `user_id`: Creator/seller of listing
- `currency`: Currency offering
- `amount`: Amount offering
- `accept_currency`: Currency accepting
- `location`: Meeting location
- `latitude`: Location latitude
- `longitude`: Location longitude
- `status`: Listing status (active/inactive)
- `available_until`: Expiration timestamp

#### `listing_meeting_time`
- `listing_id`: Foreign key to listings
- `proposed_by`: User ID of who proposed
- `meeting_time`: The proposed meeting datetime
- `created_at`: When proposal was created
- `updated_at`: When proposal was last updated
- `accepted_at`: When accepted (NULL = not accepted)
- `rejected_at`: When rejected (NULL = not rejected)

#### `listing_meeting_location`
- `listing_id`: Foreign key to listings
- `proposed_by`: User ID of who proposed
- `meeting_location_lat`: Latitude of proposed location
- `meeting_location_lng`: Longitude of proposed location
- `meeting_location_name`: Location name/description
- `created_at`: When proposal was created
- `updated_at`: When proposal was last updated
- `accepted_at`: When accepted (NULL = not accepted)
- `rejected_at`: When rejected (NULL = not rejected)

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
    └─ Backend Status: negotiating (actionRequired=false for B, true for A)
    ├─ User B: "⏳ Waiting for Acceptance"
    └─ User A: "🎯 Action Required"
    ↓
USER A ACCEPTS OR COUNTERS
    
If Accepted:
    └─ Backend Status: agreed
    ├─ User A: "✅ Payment Required"
    └─ User B: "✅ Payment Required"
    ↓
BOTH USERS PAY $2 FEE
    └─ Backend Status: paid_complete
    ├─ User A: "✅ Ready to Meet"
    └─ User B: "✅ Ready to Meet"
    ↓
LOCATION PROPOSED AND ACCEPTED
    └─ Backend Status: paid_complete (unchanged, both time and location accepted)
    ├─ User A: "✅ Ready to Meet"
    └─ User B: "✅ Ready to Meet"
    ↓
MARK EXCHANGE COMPLETE
    └─ Both users mark exchange as complete and proceed to rating

If Countered at Any Stage (repeats until accepted):
    └─ Backend Status: negotiating (actionRequired toggles based on who proposed)
    ├─ Proposer: "⏳ Waiting for Acceptance"
    └─ Non-proposer: "🎯 Action Required"
    (reverses on each counter)
```

---

## Cancel Points

### User A Can Cancel:
- [x] AI verified | [ ] Human verified
- **Before User B pays**: Removes listing and meeting_time entries
- **After either user pays**: Cannot cancel (payment indicates commitment)
- **Code verified**: DeleteListing.py checks `buyer_paid_at IS NOT NULL OR seller_paid_at IS NOT NULL` to block deletion

### User B Can Cancel:
- [x] AI verified | [ ] Human verified
- **Before User A accepts**: Removes time proposal via `DELETE /Negotiations/RejectNegotiation`
- **After User A accepts but before either user pays**: Negotiation can be ended via DeleteListing
- **After payment starts**: Cannot cancel (payment indicates commitment)
- **Code verified**: RejectNegotiation.py removes proposal, DeleteListing.py blocks if either user paid

---

## Button Availability by Stage

| Stage | User A | User B |
|-------|--------|--------|
| Time Not Proposed | N/A | Propose |
| User B Proposed | Accept / Counter / Cancel | Cancel Proposal |
| User A Countered | Cancel Proposal | Accept / Counter / Cancel |
| Time Accepted | Pay Fee | Pay Fee |
| Buyer Paid, Seller Waiting | Pay Fee | View Details |
| Seller Paid, Buyer Waiting | View Details | Pay Fee |
| Both Paid | Propose Location / Accept Location | Propose Location / Accept Location |
| Location Proposed (User A) | N/A | Counter / Accept Location |
| Location Proposed (User B) | Counter / Accept Location | N/A |
| Both Locations Accepted | View Details / Confirm | View Details / Confirm |
| Meeting Confirmed | View Details | View Details |
| Both Paid | Propose Location / Accept Location | Propose Location / Accept Location |
| Location Accepted | Confirm / View Details | Confirm / View Details |

---

## Phase 7: Exchange Complete & Rating

### Mark Exchange Complete Button

**Visibility:**
- Button shows only when: `timeAcceptedAt != nil AND locationAcceptedAt != nil`
- Button appears on both users' Meeting Detail View
- Label: "MARK EXCHANGE COMPLETE" with checkmark icon

**Endpoint:**
- **GET** `/Negotiations/CompleteExchange`
- **Parameters:** `SessionId`, `ListingId`
- **User:** Both users can initiate completion

**Prerequisites (all must be true):**
- ✅ Time negotiation accepted (accepted_at IS NOT NULL)
- ✅ Location negotiation accepted (accepted_at IS NOT NULL)
- ✅ Buyer has paid $2.00 fee (buyer_paid_at IS NOT NULL)
- ✅ Seller has paid $2.00 fee (seller_paid_at IS NOT NULL)

**Backend Process:**
1. Verify session is valid
2. Fetch listing, time negotiation, location negotiation, and payment records
3. Validate all prerequisites are met
4. Determine user role (buyer or seller) and identify partner
5. Mark listing as completed
6. Return success response with `partner_id` for rating step

**Response:**
```json
{
  "success": true,
  "message": "Exchange marked as completed",
  "exchange_id": "UUID",
  "listing_id": "listing_id",
  "partner_id": "user_id_to_rate"
}
```

**Error Conditions:**
- ❌ Invalid session → "Invalid or expired session"
- ❌ Listing not found → "Listing not found"
- ❌ Time not agreed → "Time has not been agreed upon yet"
- ❌ Location not agreed → "Location has not been agreed upon yet"
- ❌ Either party hasn't paid → "Exchange must have both parties paid before completion"

### Rating System (Follows Completion)

**Trigger:**
- Automatically shown after CompleteExchange returns success
- iOS presents rating view with partner_id from response

**UI Flow:**
1. Confirmation alert: "Confirm Exchange Complete?"
2. User taps "Complete"
3. iOS sends request to CompleteExchange endpoint
4. Backend returns partner_id
5. Rating view appears with:
   - 5-star rating selector
   - Optional feedback text box
   - "SUBMIT RATING" button

**Rating Submission:**
- **Endpoint:** `POST /Ratings/SubmitRating`
- **Parameters:** `SessionId`, `user_id` (partner_id), `Rating` (1-5), `Review` (optional)
- **Backend:** Creates user_ratings record and updates user's overall rating

**Database Records Created:**
1. **user_ratings**: Records the rating given by current user to partner

---

## Notes

- All timestamps use ISO 8601 format
- Location coordinates stored as Latitude, Longitude
- Payment fee is hardcoded as $2.00
- Once either user has paid, the listing cannot be deleted
- Time proposals go back and forth until agreement
- Location proposals go back and forth until agreement
- Meeting is only confirmed when BOTH time AND location are accepted
