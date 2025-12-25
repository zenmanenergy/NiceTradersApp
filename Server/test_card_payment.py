#!/usr/bin/env python3
"""
Unit test for ProcessCardPayment endpoint
Tests the payment processing flow
"""

import sys
import json
import os
from dotenv import load_dotenv

# Load .env file
load_dotenv()

from _Lib import Database
from Payments.PayPalPayment import create_paypal_order, capture_paypal_order
from Payments.Payments import ProcessCardPayment
from flask import Flask
from unittest.mock import MagicMock, patch

# Create a simple Flask app context for testing
app = Flask(__name__)
app.config['PAYPAL_CLIENT_ID'] = os.getenv('PAYPAL_CLIENT_ID', '')
app.config['PAYPAL_CLIENT_SECRET'] = os.getenv('PAYPAL_CLIENT_SECRET', '')
app.config['PAYPAL_MODE'] = os.getenv('PAYPAL_MODE', 'sandbox')

def test_process_card_payment():
    """Test the ProcessCardPayment endpoint"""
    
    print("\n" + "="*60)
    print("TEST: Process Card Payment")
    print("="*60)
    
    # The user who has the order with listing
    test_user_id = "USR53a3c642-4914-4de8-8217-03ee3da42224"
    test_listing_id = "1ed56571-d1db-4c68-b487-a05b8ac84b54"
    
    with app.app_context():
        print("\n1. Getting session ID for user...")
        try:
            cursor, connection = Database.ConnectToDatabase()
            # Get or create a session for the test user
            cursor.execute("SELECT session_id FROM user_sessions WHERE user_id = %s LIMIT 1", (test_user_id,))
            result = cursor.fetchone()
            cursor.close()
            connection.close()
            
            if result:
                session_id = result['session_id']
                print(f"✅ Using session: {session_id}")
            else:
                print("❌ No session found for test user - create one first!")
                return False
        except Exception as e:
            print(f"❌ Error getting session: {e}")
            return False
        
        # Create a new PayPal order
        print(f"\n2. Creating PayPal order...")
        order_response = create_paypal_order(
            user_id=test_user_id,
            listing_id=test_listing_id
        )
        
        order_data = json.loads(order_response)
        if not order_data.get('success'):
            print(f"❌ Failed to create order: {order_data.get('error')}")
            return False
        
        order_id = order_data.get('orderId')
        print(f"✅ Order created: {order_id}")
        
        # Test ProcessCardPayment with mock request
        print("\n4. Testing ProcessCardPayment endpoint...")
        
        with app.test_request_context(
            '/Payments/ProcessCardPayment',
            method='POST',
            data=json.dumps({
                'orderId': order_id,
                'sessionId': session_id,
                'cardNumber': '4111111111111111',
                'cardholderName': 'Test User',
                'expiryMonth': '12',
                'expiryYear': '25',
                'cvv': '123'
            }),
            content_type='application/json'
        ):
            try:
                response = ProcessCardPayment()
                response_data = json.loads(response.get_data(as_text=True))
                
                print(f"Response: {response_data}")
                
                if response_data.get('success'):
                    print("✅ Payment processed successfully!")
                    
                    # Verify order status in database
                    print("\n5. Verifying order status...")
                    cursor, connection = Database.ConnectToDatabase()
                    cursor.execute("SELECT status FROM paypal_orders WHERE order_id = %s", (order_id,))
                    result = cursor.fetchone()
                    cursor.close()
                    connection.close()
                    
                    if result:
                        status = result['status']
                        print(f"✅ Order status: {status}")
                        
                        if status == 'COMPLETED':
                            print("\n" + "="*60)
                            print("✅ ALL TESTS PASSED")
                            print("="*60)
                            return True
                        else:
                            print(f"⚠️  Expected COMPLETED, got {status}")
                            return False
                    else:
                        print("❌ Order not found in database")
                        return False
                else:
                    print(f"❌ Payment failed: {response_data.get('error')}")
                    return False
                    
            except Exception as e:
                print(f"❌ Error testing endpoint: {e}")
                import traceback
                traceback.print_exc()
                return False

if __name__ == '__main__':
    success = test_process_card_payment()
    sys.exit(0 if success else 1)
