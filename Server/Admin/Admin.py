from flask import Blueprint, request, jsonify
from flask_cors import cross_origin
from _Lib.Database import ConnectToDatabase
from APNService.APNService import APNService

blueprint = Blueprint('admin', __name__)

# Initialize APN Service
apn_service = APNService()

@blueprint.route('/Admin/SearchUsers', methods=['GET', 'POST'])
@cross_origin()
def search_users():
    """Search users by name or email"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        email = params.get('email', '')
        
        cursor, connection = ConnectToDatabase()
        
        if email:
            query = """
                SELECT * FROM users 
                WHERE Email LIKE %s
                ORDER BY DateCreated DESC
                LIMIT 100
            """
            cursor.execute(query, (f'%{email}%',))
        elif search_term:
            query = """
                SELECT * FROM users 
                WHERE FirstName LIKE %s 
                   OR LastName LIKE %s 
                   OR Email LIKE %s
                ORDER BY DateCreated DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search, search))
        else:
            query = "SELECT * FROM users ORDER BY DateCreated DESC LIMIT 100"
            cursor.execute(query)
        
        users = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'data': users})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/SearchListings', methods=['GET', 'POST'])
@cross_origin()
def search_listings():
    """Search listings"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        
        cursor, connection = ConnectToDatabase()
        
        if search_term:
            query = """
                SELECT * FROM listings 
                WHERE currency LIKE %s 
                   OR accept_currency LIKE %s 
                   OR location LIKE %s
                ORDER BY created_at DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search, search))
        else:
            query = "SELECT * FROM listings ORDER BY created_at DESC LIMIT 100"
            cursor.execute(query)
        
        listings = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'data': listings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/SearchTransactions', methods=['GET', 'POST'])
@cross_origin()
def search_transactions():
    """Search transactions"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        
        cursor, connection = ConnectToDatabase()
        
        if search_term:
            query = """
                SELECT * FROM contact_access 
                WHERE payment_method LIKE %s 
                   OR transaction_id LIKE %s
                ORDER BY purchased_at DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search))
        else:
            query = "SELECT * FROM contact_access ORDER BY purchased_at DESC LIMIT 100"
            cursor.execute(query)
        
        transactions = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'data': transactions})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserById', methods=['GET', 'POST'])
@cross_origin()
def get_user_by_id():
    """Get user details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM users WHERE UserId = %s"
        cursor.execute(query, (user_id,))
        user = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if user:
            return jsonify({'success': True, 'user': user})
        else:
            return jsonify({'success': False, 'error': 'User not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/UpdateUser', methods=['GET', 'POST'])
@cross_origin()
def update_user():
    """Update basic user information"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        if not user_id:
            return jsonify({'success': False, 'error': 'userId is required'})

        allowed_fields = ['FirstName', 'LastName', 'Email', 'Phone', 'Location', 'Bio', 'IsActive']
        updates = {}
        for field in allowed_fields:
            if field in params and params[field] is not None:
                value = params[field]
                if field == 'IsActive':
                    if isinstance(value, str):
                        value = 1 if value.lower() in ['1', 'true', 'yes', 'on'] else 0
                    else:
                        value = 1 if value else 0
                updates[field] = value

        if not updates:
            return jsonify({'success': False, 'error': 'No fields to update'})

        cursor, connection = ConnectToDatabase()
        set_clause = ', '.join(f"{field} = %s" for field in updates.keys())
        values = list(updates.values())
        values.append(user_id)
        cursor.execute(f"UPDATE users SET {set_clause} WHERE UserId = %s", values)
        connection.commit()

        cursor.execute("SELECT * FROM users WHERE UserId = %s", (user_id,))
        user = cursor.fetchone()
        cursor.close()
        connection.close()

        return jsonify({'success': True, 'user': user})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserListings', methods=['GET', 'POST'])
@cross_origin()
def get_user_listings():
    """Get all listings for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM listings WHERE user_id = %s ORDER BY created_at DESC"
        cursor.execute(query, (user_id,))
        listings = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'listings': listings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserPurchases', methods=['GET', 'POST'])
@cross_origin()
def get_user_purchases():
    """Get all purchases by a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM contact_access WHERE user_id = %s ORDER BY purchased_at DESC"
        cursor.execute(query, (user_id,))
        purchases = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'purchases': purchases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserMessages', methods=['GET', 'POST'])
@cross_origin()
def get_user_messages():
    """Get all messages for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT * FROM messages 
            WHERE sender_id = %s OR recipient_id = %s 
            ORDER BY sent_at DESC
        """
        cursor.execute(query, (user_id, user_id))
        messages = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'messages': messages})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserRatings', methods=['GET', 'POST'])
@cross_origin()
def get_user_ratings():
    """Get all ratings for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        # Check if table exists
        cursor.execute("SHOW TABLES LIKE 'user_ratings'")
        if not cursor.fetchone():
            cursor.close()
            connection.close()
            return jsonify({'success': True, 'ratings': []})
        
        query = "SELECT * FROM user_ratings WHERE user_id = %s ORDER BY created_at DESC"
        cursor.execute(query, (user_id,))
        ratings = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'ratings': ratings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingById', methods=['GET', 'POST'])
@cross_origin()
def get_listing_by_id():
    """Get listing details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM listings WHERE listing_id = %s"
        cursor.execute(query, (listing_id,))
        listing = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if listing:
            return jsonify({'success': True, 'listing': listing})
        else:
            return jsonify({'success': False, 'error': 'Listing not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingPurchases', methods=['GET', 'POST'])
@cross_origin()
def get_listing_purchases():
    """Get all purchases for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM contact_access WHERE listing_id = %s ORDER BY purchased_at DESC"
        cursor.execute(query, (listing_id,))
        purchases = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'purchases': purchases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingMessages', methods=['GET', 'POST'])
@cross_origin()
def get_listing_messages():
    """Get all messages for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM messages WHERE listing_id = %s ORDER BY sent_at DESC"
        cursor.execute(query, (listing_id,))
        messages = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'messages': messages})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetTransactionById', methods=['GET', 'POST'])
@cross_origin()
def get_transaction_by_id():
    """Get transaction details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        transaction_id = params.get('transactionId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM contact_access WHERE access_id = %s"
        cursor.execute(query, (transaction_id,))
        transaction = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if transaction:
            return jsonify({'success': True, 'transaction': transaction})
        else:
            return jsonify({'success': False, 'error': 'Transaction not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/SendApnMessage', methods=['POST'])
@cross_origin()
def send_apn_message():
    """Send an Apple Push Notification (APN) to a user"""
    try:
        params = request.get_json()
        user_id = params.get('user_id')
        title = params.get('title')
        body = params.get('body')
        badge = params.get('badge', 1)
        sound = params.get('sound', 'default')
        
        if not user_id or not title or not body:
            return jsonify({
                'success': False,
                'error': 'user_id, title, and body are required'
            }), 400
        
        # Send the notification
        result = apn_service.send_notification(
            user_id=user_id,
            title=title,
            body=body,
            badge=badge,
            sound=sound
        )
        
        if result['success']:
            return jsonify({
                'success': True,
                'message': result['message']
            })
        else:
            return jsonify({
                'success': False,
                'error': result.get('error', 'Failed to send notification')
            }), 400
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
