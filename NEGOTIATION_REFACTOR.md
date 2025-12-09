# Negotiation System Refactor Plan

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

### Current API Endpoints (Negotiations.py)
| Endpoint | Method | Purpose | Current Behavior |
|----------|--------|---------|------------------|
| `/Negotiations/Propose` | GET | Buyer initiates negotiation | Creates `time_proposal` action |
| `/Negotiations/Accept` | GET | Accept current proposal (time locked in) | Creates `accepted_time` action |
| `/Negotiations/Counter` | GET | Propose different time | Creates `counter_proposal` action |
| `/Negotiations/Reject` | GET | Reject negotiation | Creates `rejected` action |
| `/Negotiations/Get` | GET | Get negotiation details | Parses all history to determine state |
| `/Negotiations/GetMyNegotiations` | GET | List user's negotiations | Queries negotiation_history, finds "last action" to determine status |
| `/Negotiations/Pay` | GET | Pay $2 negotiation fee | Creates `buyer_paid`/`seller_paid` actions, updates TotalExchanges |

### Current Workflow Sequence
1. **Buyer proposes time** → `time_proposal` action created
2. **Seller counter-proposes** → `counter_proposal` action created (OR accepts with `accepted_time`)
3. **Buyer accepts** → `accepted_time` action created
4. **Location handling** → Currently MISSING from app but table structure exists for location_proposal/accepted_location
5. **Payment** → Either party can pay, creates `buyer_paid`/`seller_paid` actions
6. **Status determination** → Status derived by finding LAST action in history (THE BUG SOURCE)

### Known Issues with Current Design
- **No location negotiation flow in iOS app** - Table supports it, but app doesn't use it
- **Time proposal can be re-proposed** - Multiple `counter_proposal` actions exist
- **Status sync bug** - Multiple places query "last action" with different logic
- **Payment logic scattered** - PayNegotiationFee.py determines status based on action count
- **No explicit buyer_id/seller_id** - Must derive from listing owner + first proposer

### Data Migration Complexity
- **Current data**: Only 4 negotiations in negotiation_history (all with time_proposal → counter_proposal → accepted_time → buyer_paid flow)
- **No location data**: No existing location_proposal or accepted_location actions
- **No rejected negotiations**: No cancelled or rejected actions in current data
- **Clean migration path**: Each negotiation has clear buyer (first proposer) and seller (listing owner)

## Phase 1: Database Schema

### 1.1 Create new tables
- [ ] `negotiations` - Master negotiation record
  ```sql
  CREATE TABLE negotiations (
    negotiation_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    buyer_id CHAR(39) NOT NULL,
    seller_id CHAR(39) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
    FOREIGN KEY (buyer_id) REFERENCES users(UserId),
    FOREIGN KEY (seller_id) REFERENCES users(UserId),
    INDEX idx_buyer (buyer_id),
    INDEX idx_seller (seller_id),
    INDEX idx_listing (listing_id)
  );
  ```

- [ ] `time_negotiations` - Time proposal/acceptance lifecycle
  ```sql
  CREATE TABLE time_negotiations (
    time_negotiation_id CHAR(39) PRIMARY KEY,
    negotiation_id CHAR(39) NOT NULL,
    proposed_by CHAR(39) NOT NULL,
    meeting_time DATETIME NOT NULL,
    accepted_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (negotiation_id) REFERENCES negotiations(negotiation_id),
    FOREIGN KEY (proposed_by) REFERENCES users(UserId),
    INDEX idx_negotiation (negotiation_id),
    INDEX idx_status (accepted_at, rejected_at)
  );
  ```

- [ ] `location_negotiations` - Location proposal/acceptance lifecycle
  ```sql
  CREATE TABLE location_negotiations (
    location_negotiation_id CHAR(39) PRIMARY KEY,
    negotiation_id CHAR(39) NOT NULL,
    proposed_by CHAR(39) NOT NULL,
    meeting_location_lat DECIMAL(10, 8) NOT NULL,
    meeting_location_lng DECIMAL(11, 8) NOT NULL,
    meeting_location_name VARCHAR(255),
    accepted_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (negotiation_id) REFERENCES negotiations(negotiation_id),
    FOREIGN KEY (proposed_by) REFERENCES users(UserId),
    INDEX idx_negotiation (negotiation_id),
    INDEX idx_status (accepted_at, rejected_at)
  );
  ```

- [ ] `payments` - Payment status tracking
  ```sql
  CREATE TABLE payments (
    payment_id CHAR(39) PRIMARY KEY,
    negotiation_id CHAR(39) NOT NULL UNIQUE,
    buyer_id CHAR(39) NOT NULL,
    seller_id CHAR(39) NOT NULL,
    buyer_paid_at TIMESTAMP NULL,
    seller_paid_at TIMESTAMP NULL,
    buyer_transaction_id CHAR(39),
    seller_transaction_id CHAR(39),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (negotiation_id) REFERENCES negotiations(negotiation_id),
    FOREIGN KEY (buyer_id) REFERENCES users(UserId),
    FOREIGN KEY (seller_id) REFERENCES users(UserId),
    INDEX idx_negotiation (negotiation_id),
    INDEX idx_buyer (buyer_id),
    INDEX idx_seller (seller_id),
    INDEX idx_payment_status (buyer_paid_at, seller_paid_at)
  );
  ```

### 1.2 Migrate existing data from negotiation_history
- [ ] Write migration script to extract data from `negotiation_history` and populate new tables
- [ ] Identify buyer_id and seller_id for each negotiation_id
- [ ] Map all time_proposal/accepted_time/etc. to time_negotiations table
- [ ] Map all location_proposal/accepted_location/etc. to location_negotiations table
- [ ] Map all buyer_paid/seller_paid to payments table
- [ ] Preserve all timestamps and proposed_by values

### 1.3 Archive/backup negotiation_history
- [ ] Rename `negotiation_history` to `negotiation_history_archive` (for audit/compliance)
- [ ] Keep read-only for reference

---

## Phase 2: Backend Utility Functions

### 2.1 Create `_Lib/Negotiations.py` - Status calculation functions
- [ ] `get_time_negotiation_status(time_negotiation)` → 'proposed' | 'accepted' | 'rejected'
- [ ] `get_location_negotiation_status(location_negotiation)` → 'proposed' | 'accepted' | 'rejected'
- [ ] `get_payment_status(payment)` → 'unpaid' | 'paid_partial' | 'paid_complete'
- [ ] `get_negotiation_overall_status(negotiation, time_neg, location_neg, payment)` → 'negotiating' | 'agreed' | 'paid_partial' | 'paid_complete' | 'rejected'
- [ ] `can_user_take_action(user_id, negotiation, time_neg, location_neg)` → bool (for UI action required)

---

## Phase 3: Refactor Backend Endpoints

### 3.1 Negotiate Time (`ProposeTime.py`)
- [ ] **Current behavior**: Inserts 'time_proposal' into negotiation_history
- [ ] **New behavior**: 
  - Check if negotiations record exists, create if not
  - Create/update record in time_negotiations with proposed_by and meeting_time
  - Clear any previous rejected_at (allow re-proposing)
  - Return new time_negotiation record

### 3.2 Accept Time (`AcceptTime.py` - new)
- [ ] **Create new endpoint** to accept proposed time
- [ ] Update time_negotiations.accepted_at = NOW()
- [ ] Return updated time_negotiation

### 3.3 Reject Time (`RejectTime.py` - new)
- [ ] **Create new endpoint** to reject time proposal
- [ ] Update time_negotiations.rejected_at = NOW()
- [ ] Return updated time_negotiation

### 3.4 Propose Location (`ProposeLocation.py`)
- [ ] **Current behavior**: Inserts 'location_proposal' into negotiation_history
- [ ] **New behavior**:
  - Create/update record in location_negotiations with proposed_by, lat, lng
  - Clear any previous rejected_at (allow re-proposing)
  - Return new location_negotiation record

### 3.5 Accept Location (`AcceptLocation.py` - new)
- [ ] **Create new endpoint** to accept proposed location
- [ ] Update location_negotiations.accepted_at = NOW()
- [ ] Return updated location_negotiation

### 3.6 Reject Location (`RejectLocation.py` - new)
- [ ] **Create new endpoint** to reject location proposal
- [ ] Update location_negotiations.rejected_at = NOW()
- [ ] Return updated location_negotiation

### 3.7 GetNegotiation.py (refactor)
- [ ] **Remove**: All negotiation_history query logic
- [ ] **New logic**:
  ```python
  1. SELECT * FROM negotiations WHERE negotiation_id = ?
  2. SELECT * FROM time_negotiations WHERE negotiation_id = ?
  3. SELECT * FROM location_negotiations WHERE negotiation_id = ?
  4. SELECT * FROM payments WHERE negotiation_id = ?
  5. Call get_negotiation_overall_status() to calculate status
  6. Return single clean response
  ```
- [ ] Response structure stays same for iOS compatibility

### 3.8 GetMyNegotiations.py (refactor)
- [ ] **Remove**: negotiation_history table joins and status mapping
- [ ] **New logic**:
  ```python
  1. SELECT * FROM negotiations WHERE buyer_id = ? OR seller_id = ?
  2. For each negotiation:
     a. SELECT * FROM time_negotiations WHERE negotiation_id = ?
     b. SELECT * FROM location_negotiations WHERE negotiation_id = ?
     c. SELECT * FROM payments WHERE negotiation_id = ?
     d. Call get_negotiation_overall_status() to calculate status
  3. Return list of negotiations
  ```
- [ ] Much simpler, no complex status mapping

### 3.9 PayNegotiationFee.py (refactor)
- [ ] **Remove**: negotiation_history payment action insertion
- [ ] **New logic**:
  ```python
  1. Find/create payments record
  2. Set buyer_paid_at or seller_paid_at = NOW()
  3. Create transaction record
  4. If both paid_at timestamps exist:
     a. Create contact_access records
     b. Increment TotalExchanges for both users
  5. Return payment status
  ```
- [ ] No more "action" records - just update timestamps

### 3.10 RejectNegotiation.py (refactor)
- [ ] **Remove**: negotiation_history rejection logic
- [ ] **New logic**:
  ```python
  1. Set time_negotiations.rejected_at = NOW() (if not already rejected/accepted)
  2. Set location_negotiations.rejected_at = NOW() (if not already rejected/accepted)
  3. Return updated records
  ```

---

## Phase 4: Refactor iOS Frontend

### 4.1 Update response models (NegotiationModels.swift)
- [ ] Update `NegotiationStatus` enum if needed (statuses derived same way)
- [ ] Update Codable structures to match new API responses
- [ ] No functional changes expected - API response format stays similar

### 4.2 Update NegotiationDetailView.swift
- [ ] Remove any references to "action" history items
- [ ] Update display logic to use timestamps (accepted_at, rejected_at)
- [ ] No major changes - display logic stays mostly same

### 4.3 Update DashboardView.swift
- [ ] Update status filtering to match new derived statuses
- [ ] Remove any negotiation_history-specific logic
- [ ] Should work exactly same - status calculation moved to backend

---

## Phase 5: Testing & Validation

### 5.1 Unit tests for status calculation functions
- [ ] Test all combinations of accepted_at/rejected_at values
- [ ] Test payment status with various timestamp combinations
- [ ] Test overall negotiation status progression

### 5.2 Integration tests for endpoints
- [ ] Test ProposeTime → AcceptTime workflow
- [ ] Test ProposeLocation → AcceptLocation workflow
- [ ] Test payment after both accepted
- [ ] Test rejection at each stage
- [ ] Test re-proposal after rejection
- [ ] Test GetMyNegotiations returns correct status

### 5.3 Data validation
- [ ] Run queries on migrated data to verify integrity
- [ ] Verify existing negotiations show correct status
- [ ] Verify payment records match transactions table
- [ ] Verify TotalExchanges counts are still accurate

---

## Phase 6: Cleanup

### 6.1 Remove old code
- [ ] Delete negotiation_history querying code
- [ ] Delete status mapping dictionaries (replaced by functions)
- [ ] Delete old negotiation endpoints if replaced (ProposeNegotiation.py, etc.)

### 6.2 Documentation
- [ ] Update API documentation with new endpoints
- [ ] Document status calculation logic
- [ ] Document database schema in README

### 6.3 Keep audit log
- [ ] Keep `negotiation_history_archive` read-only
- [ ] Document for compliance/debugging purposes

---

## Benefits of New Design

1. **No more status sync bugs** - Status derived from actual data
2. **Simpler queries** - No "find last action" complexity
3. **Clearer code** - Each table has single responsibility
4. **Easier debugging** - Timestamps show exact when each action occurred
5. **Better scalability** - Easier to add features (e.g., notification tracking, retry logic)
6. **Audit trail preserved** - negotiation_history_archive keeps historical data

---

## Estimated Effort

- **Phase 1 (Database)**: 2-3 hours (migration script testing critical)
- **Phase 2 (Utilities)**: 1 hour
- **Phase 3 (Backend)**: 4-5 hours (most endpoints relatively straightforward)
- **Phase 4 (iOS)**: 1-2 hours (minimal changes expected)
- **Phase 5 (Testing)**: 2-3 hours
- **Phase 6 (Cleanup)**: 1 hour

**Total: ~12-16 hours of focused development**

Could be done incrementally endpoint-by-endpoint to avoid large risky refactor.
