"""
PayPal Payment Integration using REST API
Handles order creation, capture, and payment method vaulting
"""

import json
import uuid
import base64
import requests
from datetime import datetime
from flask import current_app
from _Lib import Database


def get_paypal_access_token():
    """Get PayPal OAuth access token"""
    client_id = current_app.config.get('PAYPAL_CLIENT_ID', '')
    client_secret = current_app.config.get('PAYPAL_CLIENT_SECRET', '')
    mode = current_app.config.get('PAYPAL_MODE', 'sandbox')
    
    if not client_id or not client_secret:
        raise ValueError("PayPal CLIENT_ID and CLIENT_SECRET not configured in .env")
    
    # Determine API base URL
    base_url = 'https://api.sandbox.paypal.com' if mode == 'sandbox' else 'https://api.paypal.com'
    
    # Create Basic Auth header
    auth_string = f"{client_id}:{client_secret}"
    auth_bytes = auth_string.encode('utf-8')
    auth_b64 = base64.b64encode(auth_bytes).decode('utf-8')
    
    headers = {
        'Authorization': f'Basic {auth_b64}',
        'Content-Type': 'application/x-www-form-urlencoded'
    }
    
    data = {'grant_type': 'client_credentials'}
    
    try:
        response = requests.post(f'{base_url}/v1/oauth2/token', headers=headers, data=data, timeout=10)
        response.raise_for_status()
        token_data = response.json()
        return token_data.get('access_token')
    except Exception as e:
        print(f"[PayPal] Error getting access token: {str(e)}")
        raise


def create_paypal_order(user_id, listing_id, amount=2.00, currency='USD', return_url=None, cancel_url=None):
    """
    Create a PayPal order for payment
    
    Args:
        user_id: User making the payment
        listing_id: Listing ID for the negotiation
        amount: Amount to charge (default $2.00)
        currency: Currency code (default USD)
        return_url: URL to return to after approval
        cancel_url: URL to return to if cancelled
    
    Returns:
        JSON response with order ID or error
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Don't reuse old orders - always create fresh ones to avoid capture conflicts
        # Each payment attempt should have its own order
        
        mode = current_app.config.get('PAYPAL_MODE', 'sandbox')
        base_url = 'https://api.sandbox.paypal.com' if mode == 'sandbox' else 'https://api.paypal.com'
        
        # Set default URLs if not provided
        if not return_url:
            return_url = current_app.config.get('PAYPAL_RETURN_URL', 'https://example.com/payment-success')
        if not cancel_url:
            cancel_url = current_app.config.get('PAYPAL_CANCEL_URL', 'https://example.com/payment-cancel')
        
        # Get access token
        access_token = get_paypal_access_token()
        
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {access_token}'
        }
        
        # Create order request body
        order_data = {
            'intent': 'CAPTURE',
            'purchase_units': [{
                'reference_id': listing_id,
                'amount': {
                    'currency_code': currency,
                    'value': f"{amount:.2f}"
                },
                'description': 'Nice Traders - Meeting Negotiation Fee'
            }],
            'payment_source': {
                'paypal': {
                    'experience_context': {
                        'return_url': return_url,
                        'cancel_url': cancel_url,
                        'user_action': 'CONTINUE'
                    }
                }
            }
        }
        
        # Create order
        response = requests.post(
            f'{base_url}/v2/checkout/orders',
            headers=headers,
            json=order_data,
            timeout=10
        )
        
        # Log the response for debugging
        print(f"[PayPal] Order creation response status: {response.status_code}")
        print(f"[PayPal] Order creation response: {response.text}")
        
        response.raise_for_status()
        result = response.json()
        order_id = result.get('id')
        
        if not order_id:
            return json.dumps({
                'success': False,
                'error': 'Failed to create PayPal order'
            })
        
        # Find approval link
        approval_link = None
        for link in result.get('links', []):
            if link.get('rel') == 'payer-action':
                approval_link = link.get('href')
                break
        
        # Store order in database
        cursor.execute("""
            INSERT INTO paypal_orders (
                order_id, user_id, listing_id, status, amount, currency, approval_link, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        """, (order_id, user_id, listing_id, 'CREATED', amount, currency, approval_link))
        
        connection.commit()
        
        return json.dumps({
            'success': True,
            'orderId': order_id,
            'approvalUrl': approval_link
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[PayPal] create_paypal_order error: {str(e)}")
        import traceback
        print(f"[PayPal] Traceback: {traceback.format_exc()}")
        
        return json.dumps({
            'success': False,
            'error': f'Failed to create PayPal order: {str(e)}'
        })
    finally:
        cursor.close()
        connection.close()


def capture_paypal_order(order_id, user_id, listing_id, session_id, card_details=None):
    """
    Capture (finalize) a PayPal order after approval
    
    Args:
        order_id: PayPal Order ID to capture
        user_id: User making the payment
        listing_id: Listing ID for the negotiation
        session_id: User's session ID for verification
    
    Returns:
        JSON response with payment confirmation
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result or session_result['user_id'] != user_id:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        # Verify listing exists and get seller
        cursor.execute("SELECT user_id FROM listings WHERE listing_id = %s", (listing_id,))
        listing = cursor.fetchone()
        
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Determine if user is buyer or seller
        cursor.execute("""
            SELECT buyer_id, rejected_at, accepted_at FROM listing_meeting_time WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'Time negotiation not found'
            })
        
        # Check if negotiation was rejected
        if time_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This negotiation has been closed'
            })
        
        # Check if negotiation was not yet accepted
        if time_neg['accepted_at'] is None:
            return json.dumps({
                'success': False,
                'error': 'This negotiation has not been accepted yet'
            })
        
        buyer_id = time_neg['buyer_id']
        is_buyer = (user_id == buyer_id)
        
        # Capture the order with PayPal
        mode = current_app.config.get('PAYPAL_MODE', 'sandbox')
        base_url = 'https://api.sandbox.paypal.com' if mode == 'sandbox' else 'https://api.paypal.com'
        
        access_token = get_paypal_access_token()
        
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {access_token}'
        }
        
        # Prepare capture payload
        capture_payload = {}
        
        # If card details are provided, include them in the payment_source
        if card_details and 'payment_source' in card_details:
            capture_payload['payment_source'] = card_details['payment_source']
        
        response = requests.post(
            f'{base_url}/v2/checkout/orders/{order_id}/capture',
            headers=headers,
            json=capture_payload,
            timeout=10
        )
        
        result = None
        
        if response.status_code != 201:
            error_details = response.text
            error_json = {}
            
            try:
                error_json = response.json()
                error_details = json.dumps(error_json, indent=2)
            except:
                pass
            
            # Check for specific 422 errors
            if response.status_code == 422 and error_json:
                details = error_json.get('details', [])
                if details and len(details) > 0:
                    issue = details[0].get('issue', '')
                    
                    if issue == 'ORDER_ALREADY_CAPTURED':
                        print(f"[PayPal] Order {order_id} already captured - treating as success")
                        # Fetch the completed order to extract transaction details
                        try:
                            get_response = requests.get(
                                f'{base_url}/v2/checkout/orders/{order_id}',
                                headers=headers,
                                timeout=10
                            )
                            if get_response.status_code == 200:
                                result = get_response.json()
                            else:
                                # Order was captured but we can't fetch details, still treat as success
                                result = {'status': 'COMPLETED', 'payer': {}, 'purchase_units': []}
                        except Exception as fetch_error:
                            print(f"[PayPal] Could not fetch order details: {str(fetch_error)}")
                            result = {'status': 'COMPLETED', 'payer': {}, 'purchase_units': []}
                    elif issue == 'ORDER_NOT_APPROVED':
                        print(f"[PayPal] Order not approved - user must approve PayPal payment first")
                        print(f"[PayPal] Error details: {error_details}")
                        response.raise_for_status()
                    else:
                        print(f"[PayPal] Capture failed with status {response.status_code}: {error_details}")
                        response.raise_for_status()
                else:
                    print(f"[PayPal] Capture failed with status {response.status_code}: {error_details}")
                    response.raise_for_status()
            else:
                print(f"[PayPal] Capture failed with status {response.status_code}: {error_details}")
                response.raise_for_status()
        else:
            result = response.json()
        
        if result.get('status') != 'COMPLETED':
            print(f"[PayPal-Capture] ❌ Payment status not COMPLETED: {result.get('status')}")
            return json.dumps({
                'success': False,
                'error': f'PayPal payment not completed. Status: {result.get("status")}'
            })
        
        print(f"[PayPal-Capture] ✅ PayPal capture confirmed as COMPLETED")
        
        # Extract transaction details
        transaction_id = None
        payer_email = None
        payer_name = None
        
        # Get payer info
        payer = result.get('payer', {})
        if payer:
            payer_email = payer.get('email_address')
            name = payer.get('name', {})
            if name:
                given_name = name.get('given_name', '')
                surname = name.get('surname', '')
                payer_name = f"{given_name} {surname}".strip()
        
        # Get transaction ID from capture
        purchase_units = result.get('purchase_units', [])
        if purchase_units:
            captures = purchase_units[0].get('payments', {}).get('captures', [])
            if captures:
                transaction_id = captures[0].get('id')
        
        # Update paypal_orders table
        cursor.execute("""
            UPDATE paypal_orders
            SET status = %s, transaction_id = %s, payer_email = %s, payer_name = %s, updated_at = NOW()
            WHERE order_id = %s
        """, ('COMPLETED', transaction_id, payer_email, payer_name, order_id))
        
        # Get or create payment record
        cursor.execute("""
            SELECT payment_id, buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment_record = cursor.fetchone()
        
        # Check if user has already paid BEFORE updating
        if payment_record:
            if is_buyer and payment_record['buyer_paid_at']:
                print(f"[PayPal-Capture] ❌ ALREADY PAID - buyer_paid_at is NOT NULL: {payment_record['buyer_paid_at']}")
                cursor.close()
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'You have already paid for this negotiation'
                })
            elif not is_buyer and payment_record['seller_paid_at']:
                print(f"[PayPal-Capture] ❌ ALREADY PAID - seller_paid_at is NOT NULL: {payment_record['seller_paid_at']}")
                cursor.close()
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'You have already paid for this negotiation'
                })
        
        if not payment_record:
            # Create new payment record
            payment_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO listing_payments (
                    payment_id, listing_id, buyer_id, created_at, updated_at
                ) VALUES (%s, %s, %s, NOW(), NOW())
            """, (payment_id, listing_id, buyer_id))
        else:
            payment_id = payment_record['payment_id']
        
        # Update payment record based on user role
        if is_buyer:
            print(f"[PayPal-Capture] ✅ Updating buyer payment - setting buyer_paid_at = NOW()")
            cursor.execute("""
                UPDATE listing_payments
                SET buyer_paid_at = NOW(), buyer_transaction_id = %s, payment_method = 'paypal', updated_at = NOW()
                WHERE listing_id = %s
            """, (transaction_id, listing_id))
        else:
            print(f"[PayPal-Capture] ✅ Updating seller payment - setting seller_paid_at = NOW()")
            cursor.execute("""
                UPDATE listing_payments
                SET seller_paid_at = NOW(), seller_transaction_id = %s, payment_method = 'paypal', updated_at = NOW()
                WHERE listing_id = %s
            """, (transaction_id, listing_id))
        
        # Check if both paid
        cursor.execute("""
            SELECT buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment_check = cursor.fetchone()
        both_paid = (payment_check['buyer_paid_at'] is not None and payment_check['seller_paid_at'] is not None)
        print(f"[PayPal-Capture] ✅ Both paid status: {both_paid}")
        
        if both_paid:
            cursor.execute("""
                UPDATE users
                SET TotalExchanges = TotalExchanges + 1
                WHERE user_id IN (%s, %s)
            """, (buyer_id, seller_id))
            new_status = 'paid_complete'
            message = 'Payment successful! Both parties have paid. Messaging and location coordination now unlocked.'
            print(f"[PayPal-Capture] ✅ Both users paid - incremented TotalExchanges")
        else:
            new_status = 'paid_partial'
            message = 'Payment successful! Waiting for other party to pay.'
            print(f"[PayPal-Capture] ✅ One user paid - waiting for other party")
        
        connection.commit()
        print(f"[PayPal-Capture] ✅ DATABASE COMMITTED - returning success response")
        
        return json.dumps({
            'success': True,
            'status': new_status,
            'transactionId': transaction_id,
            'amountCharged': 2.00,
            'bothPaid': both_paid,
            'message': message,
            'payerEmail': payer_email,
            'payerName': payer_name
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[PayPal] capture_paypal_order error: {str(e)}")
        import traceback
        print(f"[PayPal] Traceback: {traceback.format_exc()}")
        
        return json.dumps({
            'success': False,
            'error': f'Failed to capture payment: {str(e)}'
        })
    finally:
        try:
            cursor.close()
        except:
            pass
        try:
            connection.close()
        except:
            pass
