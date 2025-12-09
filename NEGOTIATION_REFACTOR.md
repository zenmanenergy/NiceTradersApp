# Negotiation System Refactor Plan

## How to Use This Document

**This document is a complete implementation specification.** When code is written or issues are fixed:
1. Check off the corresponding `[ ]` checkbox by replacing with `[x]`
2. Add commit message reference in comments if applicable
3. Move to next unchecked item

This allows you to resume work at any time by seeing what's been completed.

## Overview
Refactor from append-only `negotiation_history` table to separate, normalized tables for time negotiations, location negotiations, and payments. Status will be derived from data, not stored.

## Current System Understanding

### Existing negotiation_history Schema
```
history_id (char(39), PK)
negotiation_id (char(39), FK)
listing_id (char(39), nullable)
action (enum: initial_proposal, time_proposal, location_proposal, counter_proposal, accepted, accepted_time, accepted_location, rejected, cancelled, buyer_paid, seller_paid, expired)
proposed_time (datetime, nullable)
accepted_time (datetime, nullable)
proposed_location (varchar(255), nullable)
accepted_location (varchar(255), nullable)
accepted_latitude (decimal(10,8), nullable)
accepted_longitude (decimal(11,8), nullable)
proposed_latitude (decimal(10,8), nullable)
proposed_longitude (decimal(11,8), nullable)
proposed_by (char(39), nullable)
notes (text, nullable)
created_at (timestamp, default CURRENT_TIMESTAMP)
```

### Current API Endpoints

#### Meeting Time Endpoints (MeetingTime.py)
| Endpoint | Method | Purpose | Current Behavior |
|----------|--------|---------|------------------|
| `/MeetingTime/Propose` | GET | **Buyer proposes meeting TIME** | Creates `time_proposal` action in negotiation_history |
| `/MeetingTime/Counter` | GET | **Counter-propose different TIME** | Creates `counter_proposal` action, replaces previous time |
| `/MeetingTime/Accept` | GET | **Accept current TIME proposal** | Creates `accepted_time` action, locks in meeting time |
| `/MeetingTime/Reject` | GET | **Reject current TIME proposal** | Creates `rejected` action, negotiation ends |

#### Meeting Location Endpoints (MeetingLocation.py)
| Endpoint | Method | Purpose | Current Behavior |
|----------|--------|---------|------------------|
| `/MeetingLocation/Propose` | GET | **Propose meeting LOCATION** | Currently NOT IMPLEMENTED in iOS app |
| `/MeetingLocation/Counter` | GET | **Counter-propose different LOCATION** | Currently NOT IMPLEMENTED in iOS app |
| `/MeetingLocation/Accept` | GET | **Accept current LOCATION proposal** | Currently NOT IMPLEMENTED in iOS app |
| `/MeetingLocation/Reject` | GET | **Reject current LOCATION proposal** | Currently NOT IMPLEMENTED in iOS app |

#### Payment Endpoints (ListingPayment.py)
| Endpoint | Method | Purpose | Current Behavior |
|----------|--------|---------|------------------|
| `/ListingPayment/Pay` | GET | **PAY $2 negotiation fee** | Creates `buyer_paid`/`seller_paid` actions, creates contact_access, increments TotalExchanges |

#### Information Endpoints (MeetingTime.py)
| Endpoint | Method | Purpose | Current Behavior |
|----------|--------|---------|------------------|
| `/MeetingTime/Get` | GET | **Get negotiation details** | Queries time_negotiations, location_negotiations, payments tables to determine current status |
| `/MeetingTime/GetMy` | GET | **List user's active negotiations** | Queries time_negotiations table joined with listings to find all user's negotiations (as buyer or seller) |

### Current Workflow Sequence
1. **Buyer proposes time** → `time_proposal` action created
2. **Seller counter-proposes** → `counter_proposal` action created (OR accepts with `accepted_time`)
3. **Buyer accepts** → `accepted_time` action created
4. **Location handling** → Currently MISSING from iOS app but table structure exists for location_proposal/accepted_location
5. **Payment** → Either party can pay, creates `buyer_paid`/`seller_paid` actions
6. **Status determination** → Status derived by finding LAST action in history

### New Workflow Sequence (After Refactor)
1. **Buyer proposes time** → `/MeetingTime/Propose` creates time_negotiations record
2. **Seller counter-proposes OR accepts time** → `/MeetingTime/Counter` or `/MeetingTime/Accept`
3. **Buyer accepts time** → `/MeetingTime/Accept` sets accepted_at
4. **Time accepted, now location phase** → Either party proposes location via `/MeetingLocation/Propose`
5. **Location negotiation** → `/MeetingLocation/Counter` or `/MeetingLocation/Accept` (partial iOS implementation, needs testing)
6. **Both time & location accepted, now payment** → Either party pays via `/ListingPayment/Pay`
7. **Both paid** → Negotiation complete, contact_access created

### Known Issues with Current Design
- **Location negotiation incomplete** - iOS partially implements location endpoints but needs testing/completion
- **Time proposal can be re-proposed** - Multiple `counter_proposal` actions exist
- **Status sync bug** - Multiple places query "last action" with different logic
- **Payment logic scattered** - ListingPayment.py determines status based on action count
- **No explicit buyer_id/seller_id** - Must derive from listing owner + first proposer
- **iOS location endpoints untested** - `/MeetingLocation/Propose`, `/MeetingLocation/Counter`, `/MeetingLocation/Accept`, `/MeetingLocation/Reject` exist but need validation

### Data Migration Complexity
- **Current data**: Only 4 negotiations in negotiation_history (all with time_proposal → counter_proposal → accepted_time → buyer_paid flow)
- **No location data**: No existing location_proposal or accepted_location actions
- **No rejected negotiations**: No cancelled or rejected actions in current data
- **Clean migration path**: Each negotiation has clear buyer (first proposer) and seller (listing owner)

## Phase 1: Database Schema

### 1.0 Alter existing tables
- [x] `listings` table - Add buyer tracking:
  ```sql
  ALTER TABLE listings ADD COLUMN buyer_id CHAR(39) NULL DEFAULT NULL;
  ALTER TABLE listings ADD FOREIGN KEY (buyer_id) REFERENCES users(UserId);
  ALTER TABLE listings ADD INDEX idx_buyer (buyer_id);
  ```
  - `buyer_id` is NULL until time negotiation is accepted
  - Once accepted, set to buyer_id from time_negotiations
  - If negotiation rejected, set back to NULL
  - Represents "the buyer who won this listing"
  - **Migration**: `012_negotiation_refactor_schema.sql`

### 1.1 Create new tables
**KEY CHANGE**: Removed redundant `negotiations` master table. Since only ONE buyer can win each listing, detail tables reference `listing_id` directly with UNIQUE constraint.

- [x] `listing_meeting_time` - Time proposal/acceptance lifecycle
  ```sql
  CREATE TABLE listing_meeting_time (
    time_negotiation_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL UNIQUE,
    buyer_id CHAR(39) NOT NULL,
    proposed_by CHAR(39) NOT NULL,
    meeting_time DATETIME NOT NULL,
    accepted_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (buyer_id) REFERENCES users(UserId),
    FOREIGN KEY (proposed_by) REFERENCES users(UserId),
    INDEX idx_listing (listing_id),
    INDEX idx_buyer (buyer_id),
    INDEX idx_status (accepted_at, rejected_at)
  );
  ```
  - **Migration**: `012_negotiation_refactor_schema.sql`

- [x] `listing_meeting_location` - Location proposal/acceptance lifecycle
  ```sql
  CREATE TABLE listing_meeting_location (
    location_negotiation_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL UNIQUE,
    buyer_id CHAR(39) NOT NULL,
    proposed_by CHAR(39) NOT NULL,
    meeting_location_lat DECIMAL(10, 8) NOT NULL,
    meeting_location_lng DECIMAL(11, 8) NOT NULL,
    meeting_location_name VARCHAR(255),
    accepted_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (buyer_id) REFERENCES users(UserId),
    FOREIGN KEY (proposed_by) REFERENCES users(UserId),
    INDEX idx_listing (listing_id),
    INDEX idx_buyer (buyer_id),
    INDEX idx_status (accepted_at, rejected_at)
  );
  ```
  - **Migration**: `012_negotiation_refactor_schema.sql`

- [x] `listing_payments` - Payment status tracking
  ```sql
  CREATE TABLE listing_payments (
    payment_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL UNIQUE,
    buyer_id CHAR(39) NOT NULL,
    buyer_paid_at TIMESTAMP NULL,
    seller_paid_at TIMESTAMP NULL,
    buyer_transaction_id CHAR(39),
    seller_transaction_id CHAR(39),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (buyer_id) REFERENCES users(UserId),
    INDEX idx_listing (listing_id),
    INDEX idx_buyer (buyer_id),
    INDEX idx_payment_status (buyer_paid_at, seller_paid_at)
  );
  ```
  - **Migration**: `012_negotiation_refactor_schema.sql`

---

## Phase 2: Backend Utility Functions

### 2.1 Create `_Lib/NegotiationStatus.py` - Status calculation functions
**Ready to copy/paste** - No changes needed:
```python
def get_time_negotiation_status(time_negotiation):
    """
    Returns the current status of a time negotiation.
    
    Status logic:
    - None: No time_negotiation record exists yet (buyer hasn't proposed)
    - 'rejected': rejected_at timestamp is set (either party rejected the time proposal)
    - 'accepted': accepted_at timestamp is set AND rejected_at is NULL (time is locked in)
    - 'proposed': accepted_at is NULL AND rejected_at is NULL (awaiting response)
    
    Returns: 'rejected' | 'accepted' | 'proposed' | None
    """
    if time_negotiation is None:
        return None
    if time_negotiation['rejected_at'] is not None:
        return 'rejected'
    if time_negotiation['accepted_at'] is not None:
        return 'accepted'
    return 'proposed'

def get_location_negotiation_status(location_negotiation):
    """
    Returns the current status of a location negotiation.
    
    Status logic:
    - None: No location_negotiation record exists yet (time not accepted or location not proposed)
    - 'rejected': rejected_at timestamp is set (either party rejected the location proposal)
    - 'accepted': accepted_at timestamp is set AND rejected_at is NULL (location is locked in)
    - 'proposed': accepted_at is NULL AND rejected_at is NULL (awaiting response)
    
    Returns: 'rejected' | 'accepted' | 'proposed' | None
    """
    if location_negotiation is None:
        return None
    if location_negotiation['rejected_at'] is not None:
        return 'rejected'
    if location_negotiation['accepted_at'] is not None:
        return 'accepted'
    return 'proposed'

def get_payment_status(payment):
    """
    Returns the current payment status.
    
    Status logic:
    - 'unpaid': No payment record exists OR both buyer_paid_at and seller_paid_at are NULL
    - 'paid_partial': Either buyer_paid_at OR seller_paid_at is set, but not both
    - 'paid_complete': Both buyer_paid_at AND seller_paid_at are NOT NULL (both parties have paid)
    
    Returns: 'paid_complete' | 'paid_partial' | 'unpaid'
    """
    if payment is None:
        return 'unpaid'
    
    buyer_paid = payment['buyer_paid_at'] is not None
    seller_paid = payment['seller_paid_at'] is not None
    
    if buyer_paid and seller_paid:
        return 'paid_complete'
    elif buyer_paid or seller_paid:
        return 'paid_partial'
    else:
        return 'unpaid'

def get_negotiation_overall_status(time_neg, location_neg, payment):
    """
    Determines the overall negotiation workflow status by combining time, location, and payment states.
    
    Status logic (evaluated in order):
    1. If time_negotiation is 'rejected': Return 'rejected' (negotiation ended, no recovery)
    2. If time_negotiation is not 'accepted': Return 'negotiating' (waiting for time agreement)
    3. If location_negotiation is 'rejected': Return 'rejected' (location phase failed)
    4. If location_negotiation is not 'accepted': Return 'negotiating' (waiting for location agreement, time is done)
    5. If payment_status is 'paid_complete': Return 'paid_complete' (both parties paid, transaction complete)
    6. If payment_status is 'paid_partial': Return 'paid_partial' (one party paid, waiting for other)
    7. Otherwise: Return 'agreed' (time + location agreed, awaiting payment)
    
    Returns: 'negotiating' | 'agreed' | 'paid_partial' | 'paid_complete' | 'rejected'
    
    Workflow sequence:
    - 'negotiating' → 'negotiating' (counters) → 'agreed' (time + location accepted) → 'paid_partial' (one pays) → 'paid_complete' (both pay)
    - 'negotiating' → 'rejected' (if time or location rejected at any point)
    """
    time_status = get_time_negotiation_status(time_neg)
    
    # Time negotiation must be accepted to proceed
    if time_status == 'rejected':
        return 'rejected'
    if time_status != 'accepted':
        return 'negotiating'
    
    location_status = get_location_negotiation_status(location_neg)
    
    # Location negotiation must be accepted to proceed to payment
    if location_status == 'rejected':
        return 'rejected'
    if location_status != 'accepted':
        return 'negotiating'
    
    # Both time and location accepted - check payment status
    payment_status = get_payment_status(payment)
    if payment_status == 'paid_complete':
        return 'paid_complete'
    elif payment_status == 'paid_partial':
        return 'paid_partial'
    else:
        return 'agreed'

def action_required_for_user(user_id, time_neg):
    """
    Determines if a specific user needs to take action (respond to pending proposal).
    
    Returns True if:
    - time_negotiation exists
    - time_negotiation status is 'proposed' (not yet accepted or rejected)
    - user_id is NOT the proposed_by user (someone else made the proposal)
    
    This identifies when it's a user's turn to accept/counter/reject.
    
    Returns: bool
    """
    if time_neg is None:
        return False
    time_status = get_time_negotiation_status(time_neg)
    if time_status != 'proposed':
        return False
    return time_neg['proposed_by'] != user_id
```

- [x] Create file `Server/_Lib/NegotiationStatus.py` with above code
  - **File created**: `Server/_Lib/NegotiationStatus.py`
  - **Status**: Complete with all 5 functions
- [ ] No imports needed beyond what's already in _Lib

---

## Phase 3: Refactor Backend Endpoints

### 3.1 ProposeMeetingTime.py → `/MeetingTime/Propose` (REFACTOR)
**Current behavior**: Stores buyer proposal in time_negotiations table (UNIQUE on listing_id)
**New behavior**: Create time_negotiations record with listing_id

```python
def propose_meeting_time(listing_id, session_id, proposed_time):
    # 1. Verify session and get buyer_id
    # 2. Get listing to find seller_id from SellerUserId
    # 3. Check if listing_meeting_time exists for listing_id
    # 4. If exists, DELETE it (clean slate for re-proposal)
    # 5. Insert new listing_meeting_time with:
    #    - listing_id (UNIQUE constraint prevents duplicates)
    #    - buyer_id
    #    - proposed_by = buyer_id
    #    - meeting_time = proposed_time
    # 6. Return { success: true, timeNegotiationId, status: 'proposed' }
```
**iOS Impact**: Response format stays same (negotiationId, status)
**Breaking Changes**: None - response compatible

### 3.2 CounterMeetingTime.py → `/MeetingTime/Counter` (REFACTOR)
**Current behavior**: Updates time_negotiations with new meeting_time, clears accepted_at
**New behavior**: Update time_negotiations with new meeting_time

```python
def counter_meeting_time(listing_id, session_id, proposed_time):
    # 1. Verify session and get user_id (seller)
    # 2. Get listing_meeting_time for this listing_id
    # 3. Update listing_meeting_time SET:
    #    - meeting_time = proposed_time
    #    - proposed_by = user_id
    #    - accepted_at = NULL (re-opens negotiation for other party to accept/counter)
    # 4. Call get_time_negotiation_status() to determine new status
    # 5. Return { success: true, status: 'proposed', meetingTime: proposed_time }
```
**iOS Impact**: None - existing functionality preserved
**Breaking Changes**: None

### 3.3 AcceptMeetingTime.py → `/MeetingTime/Accept` (REFACTOR)
**Current behavior**: Sets accepted_at in time_negotiations, sets buyer_id in listings
**New behavior**: Update time_negotiations with accepted_at AND set buyer_id in listings

```python
def accept_meeting_time(listing_id, session_id):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_time for this listing_id
    # 3. Update listing_meeting_time SET accepted_at = NOW()
    # 4. Update listings SET buyer_id = listing_meeting_time.buyer_id (claim this listing)
    # 5. Return { success: true, status: 'agreed' }
```
**iOS Impact**: None - functionality preserved
**Breaking Changes**: None

### 3.4 RejectMeetingTime.py → `/MeetingTime/Reject` (REFACTOR)
**Current behavior**: Sets rejected_at in time_negotiations, clears buyer_id in listings
**New behavior**: Set rejected_at on time_negotiations AND clear buyer_id in listings

```python
def reject_meeting_time(listing_id, session_id):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_time for this listing_id
    # 3. Update listing_meeting_time SET rejected_at = NOW()
    # 4. Update listings SET buyer_id = NULL (release this listing, no winner yet)
    # 5. Return { success: true, status: 'rejected' }
```
**iOS Impact**: None - functionality preserved
**Breaking Changes**: None

### 3.5 ProposeMeetingLocation.py → `/MeetingLocation/Propose` (NEW ENDPOINT)
**Status**: NOT YET IMPLEMENTED in iOS app
**New behavior**: Create location_negotiations record

```python
def propose_meeting_location(listing_id, session_id, latitude, longitude, location_name):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_time to verify time is already accepted
    # 3. Check if listing_meeting_location exists for listing_id
    # 4. If exists, DELETE it (clean slate for re-proposal)
    # 5. Create new listing_meeting_location with:
    #    - listing_id (UNIQUE constraint prevents duplicates)
    #    - buyer_id from listing_meeting_time
    #    - proposed_by = user_id
    #    - meeting_location_lat = latitude
    #    - meeting_location_lng = longitude
    #    - meeting_location_name = location_name
    # 6. Return { success: true, status: 'negotiating', proposedLocation: {...} }
```
**iOS Impact**: REQUIRES NEW iOS CODE to call this endpoint
**Breaking Changes**: New endpoint (backwards compatible)

### 3.6 CounterMeetingLocation.py → `/MeetingLocation/Counter` (NEW ENDPOINT)
**Status**: NOT YET IMPLEMENTED in iOS app
**New behavior**: Update location_negotiations with new location

```python
def counter_meeting_location(listing_id, session_id, latitude, longitude, location_name):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_location for this listing_id
    # 3. Update listing_meeting_location SET:
    #    - meeting_location_lat = latitude
    #    - meeting_location_lng = longitude
    #    - meeting_location_name = location_name
    #    - proposed_by = user_id
    #    - accepted_at = NULL (re-opens negotiation)
    # 4. Return { success: true, status: 'negotiating', proposedLocation: {...} }
```
**iOS Impact**: REQUIRES NEW iOS CODE to call this endpoint
**Breaking Changes**: New endpoint (backwards compatible)

### 3.7 AcceptMeetingLocation.py → `/MeetingLocation/Accept` (NEW ENDPOINT)
**Status**: NOT YET IMPLEMENTED in iOS app
**New behavior**: Set accepted_at on location_negotiations

```python
def accept_meeting_location(listing_id, session_id):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_location for this listing_id
    # 3. Update SET accepted_at = NOW()
    # 4. Return { success: true, status: 'agreed', acceptedLocation: {...} }
```
**iOS Impact**: REQUIRES NEW iOS CODE to call this endpoint
**Breaking Changes**: New endpoint (backwards compatible)

### 3.8 RejectMeetingLocation.py → `/MeetingLocation/Reject` (NEW ENDPOINT)
**Status**: NOT YET IMPLEMENTED in iOS app
**New behavior**: Set rejected_at on location_negotiations

```python
def reject_meeting_location(listing_id, session_id):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_location for this listing_id
    # 3. Update SET rejected_at = NOW()
    # 4. Return { success: true, status: 'rejected' }
```
**iOS Impact**: REQUIRES NEW iOS CODE to call this endpoint
**Breaking Changes**: New endpoint (backwards compatible)

### 3.9 PayNegotiationFee.py → `/ListingPayment/Pay` (MAJOR REFACTOR)
**Current behavior**: 
- Tracks buyer_paid_at and seller_paid_at in payments table
- Creates contact_access + increments TotalExchanges

**New behavior**:
```python
def pay_negotiation_fee(listing_id, session_id):
    # 1. Verify session and get user_id
    # 2. Get listing_meeting_time to find buyer_id
    # 3. Get listing to find seller_id from SellerUserId
    # 4. Get or create listing_payments record with listing_id
    # 5. Determine if user is buyer or seller
    # 6. Check if user already paid (if paid_at is not NULL, return error)
    # 7. Update listing_payments SET buyer_paid_at = NOW() OR seller_paid_at = NOW()
    # 8. Create transaction record in transactions table
    # 9. Check if both paid (both buyer_paid_at and seller_paid_at are NOT NULL):
    #    - If both paid:
    #      a. Create contact_access record for buyer:
    #         - access_id = new UUID with CAC- prefix (39 chars)
    #         - user_id = buyer_id
    #         - listing_id = listing_id
    #         - purchased_at = NOW()
    #         - status = 'active'
    #         - amount_paid = 2.00
    #         - currency = 'USD'
    #      b. Create contact_access record for seller: (same structure but seller_id from listing.SellerUserId)
    #      c. Increment TotalExchanges for both buyer and seller: UPDATE users SET TotalExchanges = TotalExchanges + 1
    # 10. Call get_payment_status() to determine new status ('paid_partial' or 'paid_complete')
    # 11. Return { success: true, status, amountCharged: 2.00, bothPaid: bool, message: "..." }
```

**contact_access schema for reference**:
```
access_id (char(39), PK)
user_id (char(39), FK to users)
listing_id (char(39), FK to listings)
purchased_at (timestamp, default NOW())
status (varchar(20), e.g. 'active')
amount_paid (decimal(10,2))
currency (varchar(3), e.g. 'USD')
```

**iOS Impact**: Response format stays same
**Breaking Changes**: None - logic same, data source different

### 3.11 GetNegotiationDetails.py → `/MeetingTime/Get` (MAJOR REFACTOR)
**Current behavior**: Queries time_negotiations, location_negotiations, payments tables
**New behavior**: Single clean query to new tables using listing_id

```python
def get_negotiation_details(listing_id, session_id):
    # 1. Verify session and get user_id
    # 2. SELECT * FROM listing_meeting_time WHERE listing_id = ?
    # 3. SELECT * FROM listing_meeting_location WHERE listing_id = ? (will be NULL until location proposed)
    # 4. SELECT * FROM listing_payments WHERE listing_id = ? (will be NULL until payment attempted)
    # 5. Get listing and buyer/seller details from listing_meeting_time
    # 6. Verify user_id is buyer_id or seller_id (authorization check)
    # 7. Call get_negotiation_overall_status() to derive status
    # 8. Build response (see Response Format section below)
    # 9. Return JSON response
```

**Response Format** (must match iOS expectations):
```json
{
  "success": true,
  "negotiation": {
    "listingId": "...",
    "status": "proposed|countered|agreed|paid_partial|paid_complete|rejected",
    "currentProposedTime": "2025-12-10T04:49:46Z",
    "proposedBy": "USR...",
    "buyerPaid": true|false,
    "sellerPaid": true|false,
    "agreementReachedAt": null,
    "paymentDeadline": null,
    "createdAt": "2025-12-07T11:07:07Z",
    "updatedAt": "2025-12-09T00:28:48Z"
  },
  "listing": {
    "currency": "USD",
    "amount": 10.0,
    "acceptCurrency": "MXN",
    "location": "Mexico City, MX",
    "willRoundToNearestDollar": false
  },
  "location": {
    "latitude": 19.4326,
    "longitude": -99.1332,
    "name": "Mexico City, MX",
    "proposedBy": "USR...",
    "status": "proposed|accepted|rejected"
  },
  "buyer": {
    "userId": "USR...",
    "firstName": "a",
    "lastName": "b",
    "rating": 0.0,
    "totalExchanges": 0
  },
  "seller": {
    "userId": "USR...",
    "firstName": "c",
    "lastName": "D",
    "rating": 0.0,
    "totalExchanges": 0
  },
  "userRole": "buyer|seller",
  "history": []
}
```

**iOS Impact**: Response structure stays same for iOS compatibility
**Breaking Changes**: None - iOS doesn't care where status comes from

### 3.12 GetMyNegotiations.py → `/MeetingTime/GetMy` (MAJOR REFACTOR)
**Current behavior**: Queries time_negotiations table with buyer_id and seller lookups
**New behavior**: Simple JOIN queries with listing_id and buyer_id from listings

```python
def get_my_negotiations(session_id):
    # 1. Verify session and get user_id
    # 2. SELECT lmt.* FROM listing_meeting_time lmt
    #    WHERE buyer_id = user_id OR (SELECT SellerUserId FROM listings WHERE listing_id = lmt.listing_id) = user_id
    # 3. For each listing_meeting_time:
    #    - Get listing_id from listing_meeting_time
    #    - SELECT * FROM listing_meeting_location WHERE listing_id = ? (will be NULL)
    #    - SELECT * FROM listing_payments WHERE listing_id = ?
    #    - Get listing details (currency, amount, accept_currency, location, willRoundToNearestDollar)
    #    - Determine if user_id is buyer or seller (is_buyer = user_id == buyer_id)
    #    - Get other user info (firstName, lastName, rating) based on role
    #    - Call get_negotiation_overall_status() to derive status
    #    - Call action_required_for_user() to determine if user needs to act
    #    - Build negotiation object (see Response Format below)
    # 4. Return { success: true, negotiations: [...], count: N }
```

**Optimization note**: Can also query `listings WHERE buyer_id = user_id OR SellerUserId = user_id` and get buyer_id directly from listings table

**Response Format** (must match iOS expectations):
```json
{
  "success": true,
  "negotiations": [
    {
      "listingId": "593e0b02-50ff-4b12-a4b1-f097eb83e2c2",
      "status": "paid_partial",
      "currentProposedTime": "2025-12-10T04:49:46Z",
      "proposedBy": "USR...",
      "actionRequired": false,
      "buyerPaid": true,
      "sellerPaid": false,
      "createdAt": "2025-12-07T11:07:07Z",
      "updatedAt": "2025-12-09T00:28:48Z",
      "listing": {
        "currency": "USD",
        "amount": 10.0,
        "acceptCurrency": "MXN",
        "location": "Mexico City, MX",
        "willRoundToNearestDollar": false
      },
      "location": {
        "latitude": 19.4326,
        "longitude": -99.1332,
        "name": "Mexico City, MX",
        "proposedBy": "USR...",
        "status": "proposed|accepted|rejected"
      },
      "userRole": "buyer",
      "otherUser": {
        "userId": "USR...",
        "name": "a b",
        "rating": 0.0
      }
    }
  ],
  "count": 1
}
```

**Key Details**:
- Filter only negotiations where status is in: 'proposed', 'countered', 'agreed', 'paid_partial' (NOT rejected or paid_complete)
- `actionRequired` = true only if user didn't make the last proposal and negotiation is still "proposed"
- `currentProposedTime` = time from time_negotiations.meeting_time
- `userRole` = 'buyer' if user_id == buyer_id, else 'seller'
- `otherUser` = buyer info if user is seller, seller info if user is buyer

**iOS Impact**: Response format stays same
**Breaking Changes**: None - significantly faster queries

### 3.13 GetBuyerInfo.py (NO CHANGES)
- Doesn't depend on negotiation status
- Stays as-is

---

## API Compatibility Matrix

| Endpoint | Old Data Source | New Data Source | Response Format | iOS App Change |
|----------|-----------------|-----------------|-----------------|----------------|
| /MeetingTime/Propose | listing_meeting_time | listing_meeting_time | Same | Existing |
| /MeetingTime/Counter | listing_meeting_time | listing_meeting_time | Same | Existing |
| /MeetingTime/Accept | listing_meeting_time | listing_meeting_time + listings | Same | Existing |
| /MeetingTime/Reject | listing_meeting_time | listing_meeting_time + listings | Same | Existing |
| /MeetingTime/Get | listing_meeting_time + location + payments | listing_meeting_time + location + payments | Same | No change |
| /MeetingTime/GetMy | listing_meeting_time + location + payments | listing_meeting_time + location + payments | Same | No change |
| /MeetingLocation/Propose | listing_meeting_location | listing_meeting_location | New | **NEW - REQUIRED** |
| /MeetingLocation/Counter | listing_meeting_location | listing_meeting_location | New | **NEW - REQUIRED** |
| /MeetingLocation/Accept | listing_meeting_location | listing_meeting_location | New | **NEW - REQUIRED** |
| /MeetingLocation/Reject | listing_meeting_location | listing_meeting_location | New | **NEW - REQUIRED** |
| /ListingPayment/Pay | listing_payments | listing_payments | Same | No change |

**Key point**: No negotiation_history queries - all data from listing_* normalized tables

---

## Phase 4: Update iOS Routes & Response Decoding

**NOTE**: Existing iOS views for location negotiation already exist. Only need to update API routes and response decoding for new endpoint data formats.

### 4.1 Update API Route Calls
- [ ] Update `/MeetingTime/Propose` call - GET with listing_id, proposed_time parameters
- [ ] Update `/MeetingTime/Counter` call - GET with listing_id, proposed_time parameters
- [ ] Update `/MeetingTime/Accept` call - GET with listing_id parameter
- [ ] Update `/MeetingTime/Reject` call - GET with listing_id parameter
- [ ] Update `/MeetingTime/Get` call - GET with listing_id parameter
- [ ] Update `/MeetingTime/GetMy` call - GET to fetch all user's negotiations
- [ ] Update `/MeetingLocation/Propose` call - POST with listing_id, latitude, longitude, location_name
- [ ] Update `/MeetingLocation/Counter` call - POST with listing_id, latitude, longitude, location_name
- [ ] Update `/MeetingLocation/Accept` call - GET with listing_id parameter
- [ ] Update `/MeetingLocation/Reject` call - GET with listing_id parameter
- [ ] Update `/ListingPayment/Pay` call - GET with listing_id parameter

### 4.2 Update Response Decoding Models
- [ ] Update NegotiationModels.swift to decode new response structure:
  - Remove `negotiationId` field (no longer exists)
  - Use `listingId` as primary identifier
  - Add `location` object with fields: latitude, longitude, name, proposedBy, status
  - Ensure `buyerPaid` and `sellerPaid` boolean fields are decoded correctly
  
- [ ] Update GetMyNegotiations response decoding:
  - Array items now include full `location` object (even when null/not proposed)
  - Remove any references to `negotiationId`
  - Handle new `status` values derived from database

### 4.3 Update Status Display Logic
- [ ] Update status text mapping to handle derived status:
  - 'proposed' → "Awaiting response"
  - 'agreed' → "Time & Location Confirmed"
  - 'paid_partial' → "One party paid"
  - 'paid_complete' → "Transaction complete"
  - 'rejected' → "Negotiation ended"
  
- [ ] Update UI to show correct phase based on status:
  - Show time negotiation UI until time status is 'accepted'
  - Show location negotiation UI until location status is 'accepted'
  - Show pay button only when both time AND location are 'accepted'

### 4.4 Testing on iOS
- [ ] Test full flow: time → location → payment with new routes
- [ ] Test location counter-proposals with new endpoint
- [ ] Test location rejection with new endpoint
- [ ] Verify existing views work with new response data format
- [ ] Verify all status transitions display correctly
- [ ] Test switching between negotiating users

---

## Phase 5: Testing & Validation

### 5.1 Unit tests for status calculation functions
- [ ] `test_get_time_negotiation_status()` - Test all timestamp combinations
- [ ] `test_get_payment_status()` - Test all payment combinations
- [ ] `test_get_negotiation_overall_status()` - Test complete workflows
- [ ] `test_action_required_for_user()` - Test all user/action combinations

### 5.2 Database migration validation
- [ ] Run migration on test database
- [ ] Verify: All 4 existing negotiations migrated correctly
- [ ] Verify: All buyer/seller assignments correct
- [ ] Verify: All timestamps preserved
- [ ] Verify: No data loss

### 5.3 Endpoint integration tests
- [ ] **Test ProposeNegotiation**
  - Buyer proposes time → creates negotiations + time_negotiations
  - GetNegotiation shows status='proposed'
  - GetMyNegotiations shows in buyer's list
  
- [ ] **Test CounterProposal**
  - Seller counters → updates time_negotiations.meeting_time
  - Clears accepted_at
  - GetNegotiation shows new time, status='proposed'
  
- [ ] **Test AcceptProposal**
  - Buyer accepts → sets time_negotiations.accepted_at
  - GetNegotiation shows status='agreed'
  
- [ ] **Test RejectNegotiation**
  - User rejects → sets rejected_at
  - GetNegotiation shows status='rejected'
  - Cannot accept after rejection
  
- [ ] **Test PayNegotiationFee**
  - One party pays → status='paid_partial'
  - Both pay → status='paid_complete', TotalExchanges incremented
  - Cannot pay twice
  
- [ ] **Test GetMyNegotiations**
  - Returns all user's negotiations (as buyer or seller)
  - Status correct for each
  - Query performance faster than before

### 5.4 Backward compatibility validation
- [ ] Old negotiation_history_archive still readable
- [ ] No references to old table in new code
- [ ] iOS app continues working unchanged
- [ ] API responses identical to before

---

## Phase 6: Cleanup & Documentation

### 6.1 Remove old code
- [ ] Delete all negotiation_history query code:
  - Remove status mapping dictionaries (replaced by functions)
  - Remove "find last action" logic
  - Remove history parsing code
- [ ] Verify no remaining references to negotiation_history (except archive queries)

### 6.2 Update documentation
- [ ] Update API documentation with new schema reference
- [ ] Document status calculation logic in NegotiationStatus.py
- [ ] Update database schema docs
- [ ] Add this refactor plan to git history for reference

### 6.3 Archive old table
- [ ] Mark negotiation_history_archive as read-only in docs
- [ ] Document for audit/compliance purposes
- [ ] Set up retention policy if needed

---

## Benefits of New Design

1. **No more status sync bugs** - Status derived from actual data timestamps
2. **Simpler queries** - No "find last action" complexity, direct lookups by listing_id
3. **Simpler schema** - Only 3 tables needed (removed redundant negotiations master table)
4. **Better debugging** - Exact timestamps show when each action occurred
5. **Faster queries** - Simple SELECTs on listing_id vs complex history parsing
6. **Easier to extend** - Adding new features (notifications, retries) doesn't break status logic
7. **Data integrity** - Can't have inconsistent state (status column out of sync with timestamps)
8. **One negotiation per listing** - UNIQUE constraint enforces business logic at database level

---

## Implementation Notes

### Key Decisions Made
1. **Removed master `negotiations` table** - Unnecessary since only ONE buyer can win each listing
   - Detail tables (time_negotiations, location_negotiations, payments) now reference listing_id directly
   - UNIQUE constraint on listing_id enforces one negotiation per listing at database level
   
2. **seller_id removed from detail tables** - Already exists in `listings` table as SellerUserId
   - JOINs to listings table to get seller_id when needed
   - Eliminates data duplication
   
3. **buyer_id added to listings table** - Represents "the winning buyer for this listing"
   - Set to buyer_id when `/MeetingTime/Accept` is called (time negotiation accepted)
   - Set to NULL if negotiation is rejected or fails
   - Single source of truth for "who claimed this listing"
   - Allows fast queries: `listings WHERE buyer_id = user_id` to get all claimed listings
   
4. **proposed_by kept in listing_meeting_time** - Audit trail of who proposed what
   - Shows full negotiation history (all proposals and counter-proposals)
   - listings.buyer_id shows final accepted buyer
   - Together they provide both history and current state
   
5. **listing_meeting_time UNIQUE on listing_id** - Only one "current" time proposal per listing
   - When countering, DELETE old record and INSERT new one (or UPDATE)
   - Keeps current state clean while archive has full history
   
6. **listing_meeting_location also UNIQUE on listing_id** - Same reasoning
   - iOS doesn't use location yet, but structure ready for future
   
7. **listing_payments UNIQUE on listing_id** - One payment record per listing
   - Track both buyer_paid_at and seller_paid_at timestamps
   - Easy to check completion status: `IF buyer_paid_at IS NOT NULL AND seller_paid_at IS NOT NULL`

8. **Status is calculated, never stored**
   - Single source of truth (timestamps)
   - Impossible to have "status=agreed" but no accepted_at timestamp
   - Status functions are pure/deterministic

9. **negotiation_history_archive kept for compliance**
   - Provides audit trail
   - Can debug any issues by comparing old vs new
   - Not queried by active code

### Implementation Validation
1. **Run on test database first** - Verify all tables created correctly
2. **Compare row counts** - Spot check a few negotiations
3. **Verify endpoint logic** - Test before going live

### Performance Improvements Expected
| Operation | Old System | New System | Speedup |
|-----------|-----------|-----------|---------|
| GetNegotiation | Parse all history rows | 3-4 simple SELECTs on listing_id (listing_*) | ~5-10x |
| GetMyNegotiations | Complex GROUP BY + history parse | Simple listing_id JOINs (listing_*) | ~10-20x |
| CounterProposal | INSERT history row | UPDATE single row | ~2-3x |
| PayNegotiationFee | Check payment by counting actions | Check timestamps | ~2x |

---

## Database Schema Summary

**Before**: 1 append-only table (negotiation_history) with 16 fields and status determined by action parsing
**After**: 3 normalized listing_* tables + enhanced listings table

**New negotiation tables** (with listing_ prefix for grouping):
- `listing_meeting_time` (listing_id UNIQUE, buyer_id FK, proposed_by track history) - Time proposal/counter/accept/reject
- `listing_meeting_location` (listing_id UNIQUE, buyer_id FK, proposed_by track history) - Location proposal/counter/accept/reject  
- `listing_payments` (listing_id UNIQUE, buyer_id FK) - Payment tracking (buyer_paid_at, seller_paid_at)

**Enhanced listings table**:
- Add `buyer_id CHAR(39) NULL` - Set when time negotiation accepted, NULL if rejected
- Represents "the winning buyer" for this listing
- Allows fast queries: `listings WHERE buyer_id = user_id` for claimed listings

**Key constraints**: 
- UNIQUE(listing_id) on all detail tables enforces one-negotiation-per-listing
- seller_id sourced from listings.SellerUserId (no duplication)
- buyer_id sourced from listings.buyer_id (single source of truth for winner)
- proposed_by in listing_meeting_time keeps full audit trail

---

## Benefits of This Refactor

1. **Eliminates status sync bugs** - Status derived from timestamps, impossible to desynchronize
2. **Simpler code** - No complex "find last action" logic
3. **Better performance** - 5-20x faster queries
4. **Clearer data model** - Each table has single responsibility
5. **Future-proof** - Easy to extend with new features (notifications, retries, etc.)
