# Admin Interface - New Viewing Capabilities

## Overview
The admin interface has been upgraded with comprehensive viewing capabilities for all listing-related entities:
- Listing details
- Listing meeting times (negotiations)
- Listing meeting locations (proposals)
- Listing payments
- PayPal transactions

## New Endpoints

### 1. GetListingMeetingTimes
**Endpoint:** `GET|POST /Admin/GetListingMeetingTimes`

**Parameters:**
- `listing_id` (required) - The listing ID

**Returns:**
```json
{
  "success": true,
  "listing_id": "...",
  "meetings": [
    {
      "location_negotiation_id": "...",
      "listing_id": "...",
      "buyer_id": "...",
      "buyer_first_name": "...",
      "buyer_last_name": "...",
      "proposed_by": "...",
      "proposed_by_first_name": "...",
      "proposed_by_last_name": "...",
      "meeting_location_lat": 37.78,
      "meeting_location_lng": -122.41,
      "meeting_location_name": "Location Name",
      "accepted_at": "2025-12-19T...",
      "rejected_at": null,
      "created_at": "2025-12-19T...",
      "updated_at": "2025-12-19T..."
    }
  ],
  "count": 1
}
```

### 2. GetListingLocations
**Endpoint:** `GET|POST /Admin/GetListingLocations`

**Parameters:**
- `listing_id` (required) - The listing ID

**Returns:**
All proposed meeting locations with status (accepted/rejected/pending)

### 3. GetListingPayments
**Endpoint:** `GET|POST /Admin/GetListingPayments`

**Parameters:**
- `listing_id` (required) - The listing ID

**Returns:**
```json
{
  "success": true,
  "listing_id": "...",
  "payments": [
    {
      "payment_id": "...",
      "listing_id": "...",
      "buyer_id": "...",
      "buyer_first_name": "...",
      "buyer_last_name": "...",
      "buyer_email": "...",
      "seller_id": "...",
      "seller_first_name": "...",
      "seller_last_name": "...",
      "seller_email": "...",
      "currency": "USD",
      "amount": 100.00,
      "accept_currency": "EUR",
      "buyer_paid_at": "2025-12-19T...",
      "seller_paid_at": "2025-12-19T...",
      "buyer_transaction_id": "...",
      "seller_transaction_id": "...",
      "payment_method": "paypal",
      "status": "completed",
      "created_at": "2025-12-19T...",
      "updated_at": "2025-12-19T..."
    }
  ],
  "count": 1
}
```

### 4. GetPayPalTransactions
**Endpoint:** `GET|POST /Admin/GetPayPalTransactions`

**Parameters:**
- `listing_id` (optional) - Filter by listing
- `user_id` (optional) - Filter by user
- `status` (optional) - Filter by status (CREATED, APPROVED, COMPLETED, FAILED, CANCELLED, VOIDED)
- `limit` (optional) - Default 100
- `offset` (optional) - Default 0

**Returns:**
```json
{
  "success": true,
  "transactions": [
    {
      "order_id": "...",
      "user_id": "...",
      "user_first_name": "...",
      "user_last_name": "...",
      "user_email": "...",
      "listing_id": "...",
      "currency": "USD",
      "amount": 100.00,
      "transaction_id": "...",
      "status": "COMPLETED",
      "payer_email": "...",
      "payer_name": "...",
      "paypal_amount": 100.00,
      "paypal_currency": "USD",
      "created_at": "2025-12-19T...",
      "updated_at": "2025-12-19T..."
    }
  ],
  "count": 1,
  "total_count": 100,
  "limit": 100,
  "offset": 0
}
```

### 5. GetPayPalTransactionById
**Endpoint:** `GET|POST /Admin/GetPayPalTransactionById`

**Parameters:**
- `order_id` (required) - The PayPal order ID

**Returns:**
Detailed PayPal transaction information including user and listing details

## Complete Admin Endpoint Reference

### Search Operations
- `GET|POST /Admin/SearchUsers` - Search users by name or email
- `GET|POST /Admin/SearchListings` - Search listings
- `GET|POST /Admin/SearchTransactions` - Search transactions

### User Operations
- `GET|POST /Admin/GetUserById` - Get user details
- `GET|POST /Admin/UpdateUser` - Update user information
- `GET|POST /Admin/GetUserListings` - Get user's listings
- `GET|POST /Admin/GetUserPurchases` - Get user's purchases
- `GET|POST /Admin/GetUserMessages` - Get user's messages
- `GET|POST /Admin/GetUserRatings` - Get user's ratings
- `GET|POST /Admin/GetUserDevices` - Get user's registered devices

### Listing Operations
- `GET|POST /Admin/GetListingById` - Get listing details
- `GET|POST /Admin/GetListingPurchases` - Get listing purchases (negotiations)
- `GET|POST /Admin/GetListingMessages` - Get listing messages
- `GET|POST /Admin/GetListingMeetingTimes` - **NEW** Get meeting times
- `GET|POST /Admin/GetListingLocations` - **NEW** Get location proposals
- `GET|POST /Admin/GetListingPayments` - **NEW** Get payment records
- `GET|POST /Admin/UpdateListing` - Update listing
- `GET|POST /Admin/DeleteListing` - Delete/deactivate listing
- `POST /Admin/BulkUpdateListings` - Batch update listings

### Payment Operations
- `GET|POST /Admin/GetTransactionById` - Get transaction by ID
- `GET|POST /Admin/GetPaymentReports` - Get payment reports with stats
- `GET|POST /Admin/GetPayPalTransactions` - **NEW** Get PayPal transactions
- `GET|POST /Admin/GetPayPalTransactionById` - **NEW** Get PayPal transaction details

### System Operations
- `GET|POST /Admin/SendApnMessage` - Send push notification
- `GET|POST /Admin/GetLogs` - Get server logs
- `POST /Admin/ClearLogs` - Clear logs

## Data Flow Example

```
Admin → /Admin/GetListingById
    ↓ (Gets listing_id)
Admin → /Admin/GetListingMeetingTimes (shows negotiations)
    ↓
Admin → /Admin/GetListingLocations (shows location proposals)
    ↓
Admin → /Admin/GetListingPayments (shows payment status)
    ↓
Admin → /Admin/GetPayPalTransactions?listing_id=XXX (shows PayPal details)
```

## Use Cases

### Complete Listing Investigation
1. Look up listing with `/Admin/GetListingById`
2. View negotiations with `/Admin/GetListingMeetingTimes`
3. See location proposals with `/Admin/GetListingLocations`
4. Check payment status with `/Admin/GetListingPayments`
5. Verify PayPal transactions with `/Admin/GetPayPalTransactions`

### User Activity Audit
1. Get user with `/Admin/GetUserById`
2. View all their listings with `/Admin/GetUserListings`
3. Check their purchases with `/Admin/GetUserPurchases`
4. Review their PayPal transactions with `/Admin/GetPayPalTransactions?user_id=XXX`

### Payment Reconciliation
1. Get payment reports with `/Admin/GetPaymentReports`
2. View specific payment with `/Admin/GetListingPayments`
3. Verify with PayPal with `/Admin/GetPayPalTransactionById`
