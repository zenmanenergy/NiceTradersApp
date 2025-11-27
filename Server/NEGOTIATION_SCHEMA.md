# Negotiation System Database Schema

## Overview
Migration 004 adds the database infrastructure for the buyer-seller negotiation workflow before payment. This allows buyers and sellers to coordinate meeting times before committing to the $2 transaction fee.

## Migration Files
- **Migration SQL:** `Server/migrations/004_add_negotiation_tables.sql`
- **Runner Script:** `Server/run_negotiation_migration.py`
- **Verification Script:** `Server/verify_negotiation_tables.py`

## Tables Created

### 1. exchange_negotiations
Main table tracking all negotiation sessions between buyers and sellers.

**Key Columns:**
- `negotiation_id` (CHAR 39, PK) - Unique negotiation identifier
- `listing_id` (CHAR 39, FK) - Reference to the listing being negotiated
- `buyer_id` (CHAR 39, FK) - User who wants to buy
- `seller_id` (CHAR 39, FK) - User who owns the listing
- `status` (ENUM) - Current state:
  - `proposed` - Initial buyer proposal
  - `countered` - Someone counter-proposed
  - `agreed` - Both parties agreed (payment window starts)
  - `rejected` - Negotiation rejected outright
  - `expired` - Payment deadline passed
  - `cancelled` - One party cancelled
  - `paid_partial` - Only one party paid within 2 hours
  - `paid_complete` - Both parties paid (unlocks messaging/location)
- `current_proposed_time` (DATETIME) - The currently proposed meeting time
- `proposed_by` (CHAR 39, FK) - Who made the current proposal
- `buyer_paid` (TINYINT) - Boolean, has buyer paid $2
- `seller_paid` (TINYINT) - Boolean, has seller paid $2
- `buyer_paid_at` (TIMESTAMP) - When buyer paid
- `seller_paid_at` (TIMESTAMP) - When seller paid
- `buyer_payment_transaction_id` (CHAR 39) - Links to transactions table
- `seller_payment_transaction_id` (CHAR 39) - Links to transactions table
- `agreement_reached_at` (TIMESTAMP) - When both agreed (starts 2hr timer)
- `payment_deadline` (TIMESTAMP) - agreement_reached_at + 2 hours
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Indexes:** listing_id, buyer_id, seller_id, status, proposed_time, payment_deadline, agreement_reached_at

### 2. negotiation_history
Audit trail of all actions taken during a negotiation (proposals, counters, accepts, rejects).

**Key Columns:**
- `history_id` (CHAR 39, PK)
- `negotiation_id` (CHAR 39, FK) - Reference to negotiation
- `action` (ENUM):
  - `initial_proposal` - Buyer's first proposal
  - `counter_proposal` - Either party proposes new time
  - `accepted` - Party accepts current proposal
  - `rejected` - Party rejects negotiation
  - `cancelled` - Party cancels negotiation
  - `buyer_paid` - Buyer completed payment
  - `seller_paid` - Seller completed payment
  - `expired` - Payment deadline passed
- `proposed_time` (DATETIME) - Time proposed in this action
- `proposed_by` (CHAR 39, FK) - Who took this action
- `notes` (TEXT) - Optional context or reason
- `created_at` (TIMESTAMP)

**Indexes:** negotiation_id, action, proposed_by

### 3. user_credits
Tracks $2 credits issued when a partner fails to pay within 2 hours.

**Key Columns:**
- `credit_id` (CHAR 39, PK)
- `user_id` (CHAR 39, FK) - Who owns this credit
- `amount` (DECIMAL 10,2) - Credit amount (typically $2.00)
- `currency` (VARCHAR 10) - Default 'USD'
- `reason` (ENUM):
  - `partner_no_payment` - Other party didn't pay in time
  - `system_refund` - System-issued refund
  - `promotion` - Promotional credit
  - `other`
- `negotiation_id` (CHAR 39, FK) - Which negotiation generated this credit
- `transaction_id` (CHAR 39) - Original payment transaction
- `status` (ENUM):
  - `available` - Can be used
  - `applied` - Already used
  - `expired` - No longer valid
  - `cancelled` - Cancelled/voided
- `applied_to_negotiation_id` (CHAR 39, FK) - Which negotiation used this credit
- `applied_at` (TIMESTAMP) - When credit was used
- `expires_at` (TIMESTAMP) - Optional expiration date
- `created_at` (TIMESTAMP)

**Indexes:** user_id, status, negotiation_id, applied_to_negotiation_id, expires_at

### 4. transactions (Modified)
Added column to link payment transactions to negotiations.

**New Column:**
- `negotiation_id` (CHAR 39) - Links $2 payment to negotiation

## Workflow States

### Buyer Flow
1. Finds listing → Proposes time → Creates negotiation (status: `proposed`)
2. Seller accepts → Negotiation status: `agreed`, `agreement_reached_at` set, `payment_deadline` = +2 hours
3. Buyer pays $2 → `buyer_paid` = 1, `buyer_paid_at` set, transaction created
4. If seller pays too → Status: `paid_complete` (unlocks messaging/location)
5. If seller doesn't pay in 2 hours → Status: `expired`, buyer gets $2 credit

### Seller Flow
1. Receives proposal → Views buyer info (photo, rating, history)
2. Options:
   - Accept → Status: `agreed`
   - Reject → Status: `rejected` (negotiation ends)
   - Counter → Status: `countered`, update `current_proposed_time` and `proposed_by`
3. On agreement → Must pay $2 within 2 hours
4. If both pay → Status: `paid_complete`
5. If only seller pays → Status: `expired`, seller gets $2 credit

### Auto-Rejection Logic
When a negotiation reaches `paid_complete`:
- All other negotiations on the same `listing_id` → Status: `rejected`
- Listing can be marked as "pending exchange" (handled in backend logic)

## Business Rules

1. **Multiple Active Negotiations:**
   - Buyer can have many active negotiations (different listings)
   - Seller can have many active negotiations (same listing, different buyers)

2. **Payment Window:**
   - Both parties have exactly 2 hours from agreement to pay
   - Timer starts when `agreement_reached_at` is set
   - `payment_deadline` = `agreement_reached_at` + 2 hours

3. **Credit System:**
   - If only one party pays within 2 hours → They get $2 credit
   - Credits automatically apply to future negotiations
   - Credits stored in `user_credits` table

4. **Auto-Rejection:**
   - When one negotiation completes (both paid) → All other negotiations on that listing auto-reject
   - Prevents double-booking

## Next Steps

### Backend API (To Be Implemented)
- POST `/negotiations/propose` - Buyer proposes initial time
- GET `/negotiations/{id}` - Get negotiation details
- POST `/negotiations/{id}/accept` - Accept current proposal
- POST `/negotiations/{id}/reject` - Reject negotiation
- POST `/negotiations/{id}/counter` - Propose new time
- POST `/negotiations/{id}/pay` - Pay $2 fee
- GET `/negotiations/my-active` - Get user's active negotiations
- GET `/negotiations/buyer-info/{buyer_id}` - Get buyer details (for seller)

### Background Jobs (To Be Implemented)
- Check `payment_deadline` every minute
- If deadline passed and only one paid → Issue credit, set status to `expired`
- Auto-reject other negotiations when one completes

### iOS UI (To Be Implemented)
- Propose time screen (buyer)
- View proposals screen (seller with buyer info)
- Counter-proposal flow
- Payment screen with credit application
- Active negotiations list

## Running the Migration

```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
/Users/stevenelson/Documents/GitHub/NiceTradersApp/.venv/bin/python run_negotiation_migration.py
```

## Verifying the Migration

```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
/Users/stevenelson/Documents/GitHub/NiceTradersApp/.venv/bin/python verify_negotiation_tables.py
```
