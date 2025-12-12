from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import cross_origin
import json
from .GetContactDetails import get_contact_details
from .CheckContactAccess import check_contact_access
from .PurchaseContactAccess import purchase_contact_access
from .SendInterestMessage import send_interest_message
from .ReportListing import report_listing
from .GetPurchasedContacts import get_purchased_contacts
from .GetListingPurchases import get_listing_purchases
from .GetContactMessages import get_contact_messages
from .SendContactMessage import send_contact_message
from .CalculateExchangeRate import calculate_and_lock_exchange_rate, get_locked_exchange_rate

# Create the Contact blueprint
contact_bp = Blueprint('contact', __name__)

@contact_bp.route('/Contact/GetContactDetails', methods=['GET'])
@cross_origin()
def GetContactDetails():
    """Get detailed information about a listing and trader for contact page"""
    try:
        # Get query parameters
        listing_id = request.args.get('listingId')
        session_id = request.args.get('sessionId')
        user_lat = request.args.get('userLat')
        user_lng = request.args.get('userLng')
        
        if not listing_id:
            return json.dumps({
                'success': False,
                'error': 'Listing ID is required'
            })
        
        # Convert coordinates to float if provided
        try:
            user_lat = float(user_lat) if user_lat else None
            user_lng = float(user_lng) if user_lng else None
        except (ValueError, TypeError):
            user_lat = None
            user_lng = None
        
        # Call the function to get contact details
        result = get_contact_details(listing_id=listing_id, session_id=session_id, user_lat=user_lat, user_lng=user_lng)
        return result
        
    except Exception as e:
        print(f"[Contact] GetContactDetails error: {str(e)}")
        import traceback
        print(f"[Contact] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get contact details'
        })

@contact_bp.route('/Contact/CheckContactAccess', methods=['GET'])
@cross_origin()
def CheckContactAccess():
    """Check if user already has paid contact access to a specific listing"""
    try:
        # Get query parameters
        listing_id = request.args.get('listingId')
        session_id = request.args.get('sessionId')
        
        if not listing_id or not session_id:
            return json.dumps({
                'success': False,
                'error': 'Listing ID and Session ID are required'
            })
        
        # Call the function to check access
        result = check_contact_access(listing_id=listing_id, session_id=session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/PurchaseContactAccess', methods=['GET'])
@cross_origin()
def PurchaseContactAccess():
    """Process payment for contact access to a listing"""
    try:
        # Get query parameters
        listing_id = request.args.get('listingId')
        session_id = request.args.get('sessionId')
        payment_method = request.args.get('paymentMethod', 'default')
        
        if not listing_id or not session_id:
            return json.dumps({
                'success': False,
                'error': 'Listing ID and Session ID are required'
            })
        
        # Call the function to process payment
        result = purchase_contact_access(
            listing_id=listing_id, 
            session_id=session_id, 
            payment_method=payment_method
        )
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/SendInterestMessage', methods=['GET'])
@cross_origin()
def SendInterestMessage():
    """Send interest message to a trader"""
    try:
        # Get query parameters
        listing_id = request.args.get('listingId')
        session_id = request.args.get('sessionId')
        message = request.args.get('message', '')
        availability_str = request.args.get('availability', '[]')
        availability = json.loads(availability_str) if availability_str else []
        
        if not listing_id or not session_id:
            return json.dumps({
                'success': False,
                'error': 'Listing ID and Session ID are required'
            })
        
        # Call the function to send message
        result = send_interest_message(
            listing_id=listing_id,
            session_id=session_id,
            message=message,
            availability=availability
        )
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/ReportListing', methods=['GET'])
@cross_origin()
def ReportListing():
    """Report a listing for inappropriate content"""
    try:
        # Get query parameters
        listing_id = request.args.get('listingId')
        session_id = request.args.get('sessionId')
        reason = request.args.get('reason')
        description = request.args.get('description', '')
        
        if not listing_id or not session_id or not reason:
            return json.dumps({
                'success': False,
                'error': 'Listing ID, Session ID, and reason are required'
            })
        
        # Call the function to report listing
        result = report_listing(
            listing_id=listing_id,
            session_id=session_id,
            reason=reason,
            description=description
        )
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/GetPurchasedContacts', methods=['GET'])
@cross_origin()
def GetPurchasedContacts():
    """Get all listings user has purchased contact access to"""
    try:
        # Get query parameters
        session_id = request.args.get('sessionId')
        
        if not session_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID is required'
            })
        
        # Call the function to get purchased contacts
        result = get_purchased_contacts(session_id=session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/GetListingPurchases', methods=['GET'])
@cross_origin()
def GetListingPurchases():
    """Get all purchases made for user's listings"""
    try:
        # Get query parameters
        session_id = request.args.get('sessionId')
        
        if not session_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID is required'
            })
        
        # Call the function to get listing purchases
        result = get_listing_purchases(session_id=session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/GetContactMessages', methods=['GET'])
@cross_origin()
def GetContactMessages():
    """Get messages for a specific listing contact"""
    try:
        # Get query parameters
        session_id = request.args.get('sessionId')
        listing_id = request.args.get('listingId')
        
        if not session_id or not listing_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID and Listing ID are required'
            })
        
        # Call the function to get contact messages
        result = get_contact_messages(session_id=session_id, listing_id=listing_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/SendContactMessage', methods=['GET'])
@cross_origin()
def SendContactMessage():
    """Send a message in a contact conversation"""
    try:
        # Get query parameters
        session_id = request.args.get('sessionId')
        listing_id = request.args.get('listingId')
        message = request.args.get('message')
        
        if not session_id or not listing_id or not message:
            return json.dumps({
                'success': False,
                'error': 'Session ID, Listing ID, and Message are required'
            })
        
        # Call the function to send contact message
        result = send_contact_message(session_id=session_id, listing_id=listing_id, message_text=message)
        return result
        
    except Exception as e:
        return Debugger(e)

@contact_bp.route('/Contact/GetLockedExchangeRate', methods=['GET'])
@cross_origin()
def GetLockedExchangeRate():
    """Get locked exchange rate for a contact access"""
    try:
        session_id = request.args.get('sessionId')
        listing_id = request.args.get('listingId')
        
        if not all([session_id, listing_id]):
            return json.dumps({
                'success': False,
                'error': 'sessionId and listingId are required'
            })
        
        # Get user_id from session
        from _Lib import Database
        cursor, connection = Database.ConnectToDatabase()
        
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            cursor.close()
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        cursor.close()
        connection.close()
        
        result = get_locked_exchange_rate(user_id, listing_id)
        return json.dumps(result)
        
    except Exception as e:
        print(f"[Contact] GetLockedExchangeRate error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get locked exchange rate'
        })