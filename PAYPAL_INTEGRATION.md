# PayPal Integration Guide

## Overview
Replaced payment simulator with real PayPal integration using the PayPal Checkout SDK.

## Configuration

### 1. Environment Variables (.env)
Located at: `Server/.env`
```
PAYPAL_CLIENT_ID=your_client_id
PAYPAL_CLIENT_SECRET=your_client_secret
PAYPAL_MODE=sandbox  # or "live" for production
```

### 2. Database Tables
- **paypal_orders**: Stores PayPal order records (already exists)
- **vaulted_payment_methods**: Stores saved payment methods for faster future payments (NEW - migration 006)

## Backend Endpoints

### POST/GET `/Payments/CreateOrder`
Creates a PayPal order and returns an approval URL.

**Parameters:**
- `listingId`: Negotiation listing ID
- `sessionId`: User session ID
- `amount`: Amount to charge (default: $2.00)

**Response:**
```json
{
  "success": true,
  "orderId": "paypal_order_id",
  "approvalUrl": "https://sandbox.paypal.com/checkoutnow?token=..."
}
```

**Flow:**
1. Frontend calls this endpoint
2. Backend creates PayPal order
3. Frontend redirects user to `approvalUrl`
4. User approves payment on PayPal
5. PayPal redirects back to app

### POST/GET `/Payments/CaptureOrder`
Finalizes a PayPal order after user approval.

**Parameters:**
- `orderId`: PayPal Order ID from CreateOrder response
- `listingId`: Negotiation listing ID
- `sessionId`: User session ID
- `userId`: User making payment

**Response:**
```json
{
  "success": true,
  "status": "paid_complete|paid_partial",
  "transactionId": "paypal_transaction_id",
  "amountCharged": 2.00,
  "bothPaid": true/false,
  "message": "Payment successful! ...",
  "payerEmail": "user@example.com",
  "payerName": "John Doe"
}
```

## Files Modified

1. **Server/requirements.txt**
   - Added `python-dotenv==1.0.0`
   - Added `paypal-checkout-sdk==1.2.2`

2. **Server/flask_app.py**
   - Added PayPal config loading from environment
   - Added `load_dotenv()` call

3. **Server/Payments/Payments.py**
   - Replaced old `/Payments/ProcessPayment` with:
     - `/Payments/CreateOrder` - Initiates PayPal checkout
     - `/Payments/CaptureOrder` - Finalizes payment

4. **Server/Payments/PayPalPayment.py** (NEW)
   - `PayPalClient` class: Singleton HTTP client for PayPal SDK
   - `create_paypal_order()`: Creates PayPal order
   - `capture_paypal_order()`: Captures and finalizes payment

5. **Server/migrations/006_add_vaulted_payments.sql** (NEW)
   - New `vaulted_payment_methods` table for storing saved payment methods
   - Allows faster payments on subsequent transactions

6. **Server/.env** (NEW)
   - Store PayPal credentials securely
   - Not committed to git

7. **Server/.env.example** (NEW)
   - Template for `.env` file
   - Documents required variables

## How It Works

### Payment Flow Diagram
```
1. User clicks "Confirm Payment"
   ↓
2. Frontend calls POST /Payments/CreateOrder
   ↓
3. Backend creates PayPal order via SDK
   ↓
4. Frontend receives PayPal approval URL
   ↓
5. Frontend redirects user to PayPal
   ↓
6. User approves payment on PayPal
   ↓
7. PayPal redirects user back to app with orderId
   ↓
8. Frontend calls POST /Payments/CaptureOrder
   ↓
9. Backend captures order via SDK
   ↓
10. Payment processed and recorded in DB
    ↓
11. Frontend receives success response
```

## Vaulted Payments (Future Enhancement)

The `vaulted_payment_methods` table allows storing PayPal vault tokens for faster future payments:

```python
# After first payment, save vault token
cursor.execute("""
    INSERT INTO vaulted_payment_methods (
        vault_id, user_id, payment_method_type, paypal_vault_id, 
        paypal_email, is_default
    ) VALUES (%s, %s, %s, %s, %s, %s)
""")

# On next payment, use stored vault token for one-click checkout
```

## iOS Integration

The iOS app needs to:

1. **Create Order**
   ```swift
   let url = "\(baseURL)/Payments/CreateOrder?listingId=\(listingId)&sessionId=\(sessionId)"
   URLSession.shared.dataTask(with: url) { data, _, _ in
       // Parse orderId and approvalUrl
       // Show PayPal checkout using native PayPal SDK
   }
   ```

2. **Capture Order**
   ```swift
   let url = "\(baseURL)/Payments/CaptureOrder?orderId=\(orderId)&listingId=\(listingId)&sessionId=\(sessionId)&userId=\(userId)"
   URLSession.shared.dataTask(with: url) { data, _, _ in
       // Handle payment confirmation
   }
   ```

## Testing

### Sandbox Mode
Use PayPal sandbox accounts for testing:
1. Login to developer.paypal.com
2. Create sandbox buyer and seller accounts
3. Payments won't charge real money

### Switching to Live
When ready for production:
1. Update `.env` with live credentials
2. Change `PAYPAL_MODE=live`
3. Create live PayPal app on developer.paypal.com

## Error Handling

All endpoints return JSON:
```json
{
  "success": false,
  "error": "Descriptive error message"
}
```

Common errors:
- Invalid session
- Listing not found
- Order not completed
- Invalid PayPal credentials

## Database Changes

Run migration 006 to add vaulted_payment_methods table:
```bash
cd Server && python run_migrations.py
```

Or manually:
```bash
mysql -u stevenelson -p nicetraders < migrations/006_add_vaulted_payments.sql
```

## Logging

All PayPal operations are logged to console:
- `[PayPal] create_paypal_order: ...`
- `[PayPal] capture_paypal_order: ...`
- `[PayPal] Exception: ...`

Check server logs for debugging payment issues.

## Next Steps

1. ✅ Set up PayPal credentials in .env
2. ✅ Install PayPal SDK
3. ⬜ Update iOS PaymentView to use new endpoints
4. ⬜ Test in sandbox
5. ⬜ Deploy and switch to live credentials
6. ⬜ Implement vaulted payments for faster checkout
