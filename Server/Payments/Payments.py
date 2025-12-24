from flask import Blueprint, request, Response
from flask_cors import cross_origin
import json
from _Lib import Database
from Payments.PayPalPayment import create_paypal_order, capture_paypal_order

payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/Payments/GetPayPalApprovalURL', methods=['GET'])
@cross_origin()
def GetPayPalApprovalURL():
    """
    Get the PayPal approval URL for a given order ID
    Used by iOS app to show approval flow in Safari
    """
    try:
        order_id = request.args.get('orderId')
        
        if not order_id:
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'orderId is required'
                }),
                mimetype='application/json'
            )
        
        # Fetch order from database to get approval link
        cursor, connection = Database.ConnectToDatabase()
        cursor.execute("""
            SELECT approval_link FROM paypal_orders 
            WHERE order_id = %s
        """, (order_id,))
        result = cursor.fetchone()
        cursor.close()
        connection.close()
        
        if not result or not result.get('approval_link'):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'Order not found or approval URL not available'
                }),
                mimetype='application/json'
            )
        
        return Response(
            json.dumps({
                'success': True,
                'approvalURL': result['approval_link']
            }),
            mimetype='application/json'
        )
        
    except Exception as e:
        print(f"[Payments] GetPayPalApprovalURL error: {str(e)}")
        return Response(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            mimetype='application/json',
            status=500
        )

@payments_bp.route('/Payments/CreateOrder', methods=['GET', 'POST'])
@cross_origin()
def CreatePayPalOrder():
    """
    Create a PayPal order for payment
    Initiates the PayPal checkout flow
    """
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        listing_id = request_data.get('listingId')
        session_id = request_data.get('sessionId')
        amount = request_data.get('amount', 2.00)
        
        if not all([listing_id, session_id]):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'listingId and sessionId are required'
                }),
                mimetype='application/json'
            )
        
        # Extract user_id from session
        cursor, connection = Database.ConnectToDatabase()
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'Invalid session'
                }),
                mimetype='application/json'
            )
        
        user_id = session_result['user_id']
        
        # Create the PayPal order
        result = create_paypal_order(
            user_id=user_id,
            listing_id=listing_id,
            amount=float(amount)
        )
        return Response(result, mimetype='application/json')
        
    except Exception as e:
        print(f"[Payments] CreatePayPalOrder error: {str(e)}")
        return Response(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            mimetype='application/json',
            status=500
        )

@payments_bp.route('/Payments/CaptureOrder', methods=['GET', 'POST'])
@cross_origin()
def CapturePayPalOrder():
    """
    Capture (finalize) a PayPal order after user approval
    Called after user returns from PayPal approval
    """
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        order_id = request_data.get('orderId')
        listing_id = request_data.get('listingId')
        session_id = request_data.get('sessionId')
        user_id = request_data.get('userId')
        
        if not all([order_id, listing_id, session_id, user_id]):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'orderId, listingId, sessionId, and userId are required'
                }),
                mimetype='application/json'
            )
        
        # Capture the order
        result = capture_paypal_order(order_id, user_id, listing_id, session_id)
        return Response(result, mimetype='application/json')
        
    except Exception as e:
        print(f"[Payments] CapturePayPalOrder error: {str(e)}")
        return Response(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            mimetype='application/json',
            status=500
        )
