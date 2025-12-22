# Admin PayPal Transactions Management

## Features Added

### Backend Endpoint
**`POST /Admin/RefundPayPalTransaction`**
- Refunds a PayPal transaction fee to user as account credit
- Updates `paypal_orders` status to `REFUNDED`
- Removes payment from `listing_payments` if applicable
- Creates credit record in `user_credits` table
- User can use credit for future payments

### Frontend Pages

#### 1. PayPal Transactions Page
**Route:** `/paypal-transactions`

**Features:**
- View all PayPal transactions with filters
- Filter by:
  - Status (CREATED, APPROVED, COMPLETED, FAILED, REFUNDED)
  - User ID
  - Listing ID
- Pagination support (50 per page)
- Statistics cards showing:
  - Total transactions
  - Total amount
  - Completed transactions
  - Refunded transactions
- Export to CSV functionality
- Real-time transaction details

#### 2. Refund Modal
- Select a completed PayPal transaction
- Provide refund reason
- Confirm refund with one click
- Transaction fee returned as user credit
- Success notification with reload

### Navigation Updates

**Home Dashboard** (`/`)
- Added "PayPal Transactions" quick action button

**Admin Layout Header**
- Added "🔄 PayPal" button to main navigation
- Quick access from any admin page

## Database

No new tables required - uses existing:
- `paypal_orders` - stores PayPal transactions
- `user_credits` - stores refunded amounts as credits
- `listing_payments` - tracks payment status

## Refund Flow

```
Admin views transaction
    ↓
Clicks "Refund" button
    ↓
Modal opens with transaction details
    ↓
Admin enters refund reason
    ↓
Confirms refund
    ↓
Backend creates credit record
    ↓
Updates transaction status to REFUNDED
    ↓
Removes payment from listing_payments
    ↓
User sees credit in their account
    ↓
User can apply credit to future payments
```

## Implementation Details

### Backend
- Added `RefundPayPalTransaction` endpoint in `Admin/Admin.py`
- Validates transaction is COMPLETED before refunding
- Creates audit trail in `user_credits` table
- Reverts payment status atomically

### Frontend
- Svelte component with full modal UI
- Real-time filtering and pagination
- CSV export for reporting
- Responsive design for all screen sizes
- Success/error notifications

## Testing

To test the refund feature:

1. Navigate to `/paypal-transactions`
2. Find a COMPLETED PayPal transaction
3. Click "💳 Refund" button
4. Enter refund reason
5. Click "Confirm Refund"
6. Transaction status changes to REFUNDED
7. User receives credit to their account

## Security

- Only admin can access `/Admin/RefundPayPalTransaction`
- Validates transaction exists before refunding
- Prevents duplicate refunds (can only refund COMPLETED)
- Atomically updates all related tables
- Refund reason logged for audit trail
