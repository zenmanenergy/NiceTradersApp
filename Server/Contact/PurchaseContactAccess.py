from _Lib import Database
import json
from datetime import datetime, timedelta
import uuid
import time
import random

def simulate_payment_processing(payment_method='paypal'):
    """
    Simulate PayPal payment processing for testing purposes
    Returns True for successful payment, False for failed payment
    """
    print(f"[PayPal Simulator] Processing payment via {payment_method}")
    
    # Simulate network delay (PayPal API call time)
    time.sleep(0.5)
    
    # Temporary: 100% success rate for debugging
    success_rate = 1.0
    random_value = random.random()
    payment_successful = random_value < success_rate
    print(f"[PayPal Simulator] Random value: {random_value}, Success rate: {success_rate}, Successful: {payment_successful}")
    
    if payment_successful:
        # Generate fake PayPal transaction ID
        fake_paypal_transaction_id = f"PAY-{uuid.uuid4().hex[:12].upper()}"
        print(f"[PayPal Simulator] Payment successful! Transaction ID: {fake_paypal_transaction_id}")
        return {
            'success': True,
            'transaction_id': fake_paypal_transaction_id,
            'payment_method': payment_method,
            'amount': 2.00,
            'currency': 'USD',
            'status': 'COMPLETED'
        }
    else:
        # Simulate various payment failure reasons
        failure_reasons = [
            'Insufficient funds',
            'Payment method declined',
            'PayPal account restricted',
            'Transaction timeout',
            'Invalid payment method'
        ]
        failure_reason = random.choice(failure_reasons)
        print(f"[PayPal Simulator] Payment failed: {failure_reason}")
        return {
            'success': False,
            'error': failure_reason,
            'payment_method': payment_method
        }

def purchase_contact_access(listing_id, session_id, payment_method='default'):
    """Process payment for contact access to a listing"""
    try:
        print(f"[PurchaseContactAccess] Processing payment for listing {listing_id}, session {session_id}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # First, get user_id from session_id
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Check if user already has access to prevent duplicate purchases
        cursor.execute("""
            SELECT access_id FROM contact_access 
            WHERE user_id = %s AND listing_id = %s AND status = 'active'
            AND (expires_at IS NULL OR expires_at > NOW())
        """, (user_id, listing_id))
        
        existing_access = cursor.fetchone()
        if existing_access:
            return json.dumps({
                'success': False,
                'error': 'You already have access to this contact'
            })
        
        # Check if listing exists and is active
        cursor.execute("""
            SELECT user_id, currency, amount FROM listings 
            WHERE listing_id = %s AND status = 'active'
        """, (listing_id,))
        
        listing_result = cursor.fetchone()
        if not listing_result:
            return json.dumps({
                'success': False,
                'error': 'Listing not found or inactive'
            })
        
        # Check if user is trying to buy access to their own listing
        if listing_result['user_id'] == user_id:
            return json.dumps({
                'success': False,
                'error': 'Cannot purchase contact access to your own listing'
            })
        
        # Simulate PayPal payment processing (replace with real PayPal API later)
        amount = 2.00  # Fixed $2 fee for contact access
        print(f"[DEBUG] Processing payment for amount: ${amount}")
        payment_result = simulate_payment_processing(amount)
        print(f"[DEBUG] Payment result: {payment_result}")
        
        if not payment_result['success']:
            return json.dumps({
                'success': False,
                'error': f'Payment failed: {payment_result["error"]}'
            })
        
        # Create contact access record
        access_id = str(uuid.uuid4())
        purchase_time = datetime.now()
        expires_at = None  # Contact access doesn't expire by default
        
        access_query = """
            INSERT INTO contact_access (
                access_id, user_id, listing_id, purchased_at, expires_at, 
                status, payment_method, amount_paid, currency
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.execute(access_query, (
            access_id, user_id, listing_id, purchase_time, expires_at,
            'active', 'paypal', 2.00, 'USD'
        ))
        
        # Calculate and lock in exchange rate for this purchase
        print(f"[PurchaseContactAccess] Calculating exchange rate for purchase")
        from .CalculateExchangeRate import calculate_and_lock_exchange_rate
        
        exchange_result = calculate_and_lock_exchange_rate(listing_id, user_id)
        if not exchange_result['success']:
            print(f"[PurchaseContactAccess] Warning: Failed to calculate exchange rate: {exchange_result['error']}")
            # Don't fail the purchase, just log the warning
        else:
            print(f"[PurchaseContactAccess] Exchange rate locked: {exchange_result['calculation']}")
        
        # Create transaction record for accounting
        transaction_id = str(uuid.uuid4())
        transaction_query = """
            INSERT INTO transactions (
                transaction_id, user_id, listing_id, amount, currency,
                transaction_type, status, created_at, description
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.execute(transaction_query, (
            transaction_id, user_id, listing_id, 2.00, 'USD',
            'contact_fee', 'completed', purchase_time,
            f'PayPal payment for contact access (Transaction: {payment_result["transaction_id"]})'
        ))
        
        # Commit the transaction
        connection.commit()
        
        response_data = {
            'success': True,
            'message': 'Payment processed successfully via PayPal',
            'access_details': {
                'access_id': access_id,
                'purchased_at': purchase_time.isoformat(),
                'expires_at': expires_at.isoformat() if expires_at else None,
                'amount_paid': 2.00,
                'currency': 'USD'
            },
            'payment_details': {
                'transaction_id': payment_result['transaction_id'],
                'payment_method': 'paypal',
                'status': payment_result['status']
            },
            'exchange_rate_details': exchange_result if exchange_result['success'] else None,
            'internal_transaction_id': transaction_id
        }
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps(response_data)
        
    except Exception as e:
        print(f"[PurchaseContactAccess] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to process payment'
        })