# Admin Viewing Quick Reference

## 5 New Viewing Endpoints

### 1. Meeting Times
```
GET /Admin/GetListingMeetingTimes?listing_id=XXX
```
Returns all negotiations/meetings for a listing

### 2. Location Proposals  
```
GET /Admin/GetListingLocations?listing_id=XXX
```
Returns all proposed meeting locations with status

### 3. Payment Records
```
GET /Admin/GetListingPayments?listing_id=XXX
```
Returns payment information and status

### 4. PayPal Transactions (with filtering)
```
GET /Admin/GetPayPalTransactions
  ?listing_id=XXX          # Filter by listing
  &user_id=XXX             # Filter by user
  &status=COMPLETED        # Filter by status (CREATED|APPROVED|COMPLETED|FAILED|CANCELLED|VOIDED)
  &limit=100               # Pagination limit
  &offset=0                # Pagination offset
```

### 5. PayPal Transaction Details
```
GET /Admin/GetPayPalTransactionById?order_id=XXX
```
Returns detailed information for a specific PayPal transaction

---

## Quick Workflow

**Investigate a Listing:**
1. `GET /Admin/GetListingById?listingId=XXX` - Get listing details
2. `GET /Admin/GetListingMeetingTimes?listing_id=XXX` - See negotiations
3. `GET /Admin/GetListingLocations?listing_id=XXX` - See locations
4. `GET /Admin/GetListingPayments?listing_id=XXX` - See payment status
5. `GET /Admin/GetPayPalTransactions?listing_id=XXX` - See PayPal details

**Audit User Activity:**
1. `GET /Admin/GetUserById?user_id=XXX` - Get user details
2. `GET /Admin/GetUserListings?user_id=XXX` - See their listings
3. `GET /Admin/GetPayPalTransactions?user_id=XXX` - See their PayPal transactions

**Check Payment Status:**
1. `GET /Admin/GetPaymentReports` - View payment statistics
2. `GET /Admin/GetListingPayments?listing_id=XXX` - See specific payment
3. `GET /Admin/GetPayPalTransactionById?order_id=XXX` - Verify PayPal order

---

## All 26 Admin Endpoints

### View (13)
- GetListingById
- GetListingPurchases
- GetListingMessages
- **GetListingMeetingTimes** ← NEW
- **GetListingLocations** ← NEW
- **GetListingPayments** ← NEW
- GetUserById
- GetUserListings
- GetUserPurchases
- GetUserMessages
- GetUserRatings
- GetUserDevices
- GetTransactionById

### PayPal/Payments (3)
- **GetPayPalTransactions** ← NEW
- **GetPayPalTransactionById** ← NEW
- GetPaymentReports

### Search (3)
- SearchUsers
- SearchListings
- SearchTransactions

### Update/Delete (4)
- UpdateUser
- UpdateListing
- DeleteListing
- BulkUpdateListings

### System (4)
- SendApnMessage
- GetLogs
- ClearLogs

---

**All endpoints return JSON with success/error indicators**
**All endpoints support both GET and POST methods (except noted)**
