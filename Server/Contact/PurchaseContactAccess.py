from _Lib import Database
import json
import uuid

def simulate_payment_processing(payment_method='paypal'):
    """Simulate PayPal payment processing - always succeeds for testing"""
    transaction_id = f"PAY-{uuid.uuid4().hex[:12].upper()}"
    return {
        'success': True,
        'transaction_id': transaction_id,
        'payment_method': payment_method,
        'amount': 2.00,
        'currency': 'USD',
        'status': 'COMPLETED'
    }

def purchase_contact_access(listing_id, session_id, payment_method='paypal'):
    """Process payment for contact access to a listing"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        # Get user_id from session
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            cursor.close()
            connection.close()
            return json.dumps({'success': False, 'error': 'Invalid session'})
        
        user_id = session_result['UserId']
        
        # Check if already has access
        cursor.execute("""
            SELECT access_id FROM contact_access 
            WHERE user_id = %s AND listing_id = %s AND status = 'active'
        """, (user_id, listing_id))
        
        if cursor.fetchone():
            cursor.close()
            connection.close()
            return json.dumps({'success': False, 'error': 'You already have access to this contact'})
        
        # Check listing exists and get owner
        cursor.execute("""
            SELECT user_id FROM listings 
            WHERE listing_id = %s AND status = 'active'
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            cursor.close()
            connection.close()
            return json.dumps({'success': False, 'error': 'Listing not found'})
        
        if listing['user_id'] == user_id:
            cursor.close()
            connection.close()
            return json.dumps({'success': False, 'error': 'Cannot purchase your own listing'})
        
        # Simulate payment
        payment_result = simulate_payment_processing(payment_method)
        
        # Insert contact access
        access_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO contact_access (
                access_id, user_id, listing_id, purchased_at, 
                status, payment_method, amount_paid, currency
            ) VALUES (%s, %s, %s, NOW(), 'active', %s, 2.00, 'USD')
        """, (access_id, user_id, listing_id, payment_method))
        
        # Insert transaction record
        transaction_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO transactions (
                transaction_id, user_id, listing_id, amount, currency,
                transaction_type, status, created_at, description
            ) VALUES (%s, %s, %s, 2.00, 'USD', 'contact_fee', 'completed', NOW(), %s)
        """, (transaction_id, user_id, listing_id, f'PayPal: {payment_result["transaction_id"]}'))
        
        connection.commit()
        cursor.close()
        connection.close()
        
        return json.dumps({
            'success': True,
            'access_id': access_id,
            'transaction_id': payment_result['transaction_id']
        })
        
    except Exception as e:
        if 'connection' in locals() and connection:
            connection.rollback()
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'connection' in locals() and connection:
            connection.close()
        return json.dumps({'success': False, 'error': str(e)})