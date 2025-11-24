from flask import Blueprint, request, jsonify
from _Lib.Database import ConnectToDatabase

Admin = Blueprint('Admin', __name__)

@Admin.route('/SearchUsers', methods=['GET', 'POST'])
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


@Admin.route('/SearchListings', methods=['GET', 'POST'])
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


@Admin.route('/SearchTransactions', methods=['GET', 'POST'])
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


@Admin.route('/GetUserById', methods=['GET', 'POST'])
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


@Admin.route('/GetUserListings', methods=['GET', 'POST'])
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


@Admin.route('/GetUserPurchases', methods=['GET', 'POST'])
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


@Admin.route('/GetUserMessages', methods=['GET', 'POST'])
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


@Admin.route('/GetUserRatings', methods=['GET', 'POST'])
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


@Admin.route('/GetListingById', methods=['GET', 'POST'])
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


@Admin.route('/GetListingPurchases', methods=['GET', 'POST'])
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


@Admin.route('/GetListingMessages', methods=['GET', 'POST'])
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


@Admin.route('/GetTransactionById', methods=['GET', 'POST'])
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


@Admin.route('/SearchUsers', methods=['GET', 'POST'])
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


@Admin.route('/SearchListings', methods=['GET', 'POST'])
def search_listings():
    """Search listings"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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


@Admin.route('/SearchTransactions', methods=['GET', 'POST'])
def search_transactions():
    """Search transactions"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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


@Admin.route('/GetUserById', methods=['GET', 'POST'])
def get_user_by_id():
    """Get user details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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


@Admin.route('/GetUserListings', methods=['GET', 'POST'])
def get_user_listings():
    """Get all listings for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
        query = "SELECT * FROM listings WHERE user_id = %s ORDER BY created_at DESC"
        cursor.execute(query, (user_id,))
        listings = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'listings': listings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@Admin.route('/GetUserPurchases', methods=['GET', 'POST'])
def get_user_purchases():
    """Get all purchases by a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
        query = "SELECT * FROM contact_access WHERE user_id = %s ORDER BY purchased_at DESC"
        cursor.execute(query, (user_id,))
        purchases = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'purchases': purchases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@Admin.route('/GetUserMessages', methods=['GET', 'POST'])
def get_user_messages():
    """Get all messages for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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


@Admin.route('/GetUserRatings', methods=['GET', 'POST'])
def get_user_ratings():
    """Get all ratings for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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


@Admin.route('/GetListingById', methods=['GET', 'POST'])
def get_listing_by_id():
    """Get listing details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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


@Admin.route('/GetListingPurchases', methods=['GET', 'POST'])
def get_listing_purchases():
    """Get all purchases for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
        query = "SELECT * FROM contact_access WHERE listing_id = %s ORDER BY purchased_at DESC"
        cursor.execute(query, (listing_id,))
        purchases = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'purchases': purchases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@Admin.route('/GetListingMessages', methods=['GET', 'POST'])
def get_listing_messages():
    """Get all messages for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
        query = "SELECT * FROM messages WHERE listing_id = %s ORDER BY sent_at DESC"
        cursor.execute(query, (listing_id,))
        messages = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'messages': messages})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@Admin.route('/GetTransactionById', methods=['GET', 'POST'])
def get_transaction_by_id():
    """Get transaction details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        transaction_id = params.get('transactionId')
        
        connection = ConnectToDatabase()
        cursor = connection.cursor(dictionary=True)
        
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
