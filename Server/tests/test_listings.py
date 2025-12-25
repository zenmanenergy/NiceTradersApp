"""
Unit tests for Listings endpoints
"""
import json
import pytest
from datetime import datetime, timedelta

class TestListingsEndpoints:
    """Test Listings blueprint routes"""
    
    def test_create_listing_success(self, client, test_user):
        """Test creating a new listing"""
        available_until = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
        
        response = client.get('/Listings/CreateListing', query_string={
            'SessionId': test_user['session_id'],
            'currency': 'USD',
            'amount': '500',
            'acceptCurrency': 'EUR',
            'location': 'Los Angeles, CA',
            'latitude': '34.0522',
            'longitude': '-118.2437',
            'locationRadius': '10',
            'meetingPreference': 'public',
            'availableUntil': available_until
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listingId' in data
        
        # Cleanup
        if 'listingId' in data:
            from _Lib import Database
            cursor, connection = Database.ConnectToDatabase()
            cursor.execute("DELETE FROM listings WHERE listing_id = %s", (data['listingId'],))
            connection.commit()
            connection.close()
    
    def test_create_listing_invalid_session(self, client):
        """Test creating listing with invalid session"""
        available_until = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
        
        response = client.get('/Listings/CreateListing', query_string={
            'SessionId': 'INVALID-SESSION',
            'currency': 'USD',
            'amount': '500',
            'acceptCurrency': 'EUR',
            'location': 'Test Location',
            'availableUntil': available_until
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_get_listings(self, client):
        """Test getting listings"""
        response = client.get('/Listings/GetListings', query_string={
            'currency': 'USD',
            'limit': '10',
            'offset': '0'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listings' in data
        assert isinstance(data['listings'], list)
    
    def test_get_listing_by_id(self, client, test_listing):
        """Test getting a specific listing by ID"""
        response = client.get('/Listings/GetListingById', query_string={
            'listingId': test_listing['listing_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listing' in data
        assert data['listing']['id'] == test_listing['listing_id']
    
    def test_get_listing_by_invalid_id(self, client):
        """Test getting listing with invalid ID"""
        response = client.get('/Listings/GetListingById', query_string={
            'listingId': 'INVALID-LISTING-ID'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_update_listing_success(self, client, test_listing, test_user):
        """Test updating a listing"""
        response = client.get('/Listings/UpdateListing', query_string={
            'SessionId': test_user['session_id'],
            'listingId': test_listing['listing_id'],
            'amount': '1500',
            'locationRadius': '15'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
    
    def test_update_listing_unauthorized(self, client, test_listing, db_connection):
        """Test updating listing by non-owner"""
        # Create another user
        cursor, connection = db_connection
        import uuid
        import bcrypt
        
        from tests.test_utils import generate_uuid
        
        user_id = generate_uuid('USR')
        email = f"other_{uuid.uuid4().hex[:8]}@example.com"
        password = bcrypt.hashpw("TestPass123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        cursor.execute("""
            INSERT INTO users (user_id, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (user_id, "Other", "User", email, password, "standard", 1))
        
        session_id = generate_uuid('SES')
        cursor.execute("""
            INSERT INTO user_sessions (session_id, user_id)
            VALUES (%s, %s)
        """, (session_id, user_id))
        connection.commit()
        
        response = client.get('/Listings/UpdateListing', query_string={
            'SessionId': session_id,
            'listingId': test_listing['listing_id'],
            'amount': '2000'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
        
        # Cleanup
        cursor.execute("DELETE FROM user_sessions WHERE user_id = %s", (user_id,))
        cursor.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        connection.commit()
    
    def test_delete_listing_success(self, client, db_connection, test_user):
        """Test deleting a listing"""
        # Create a listing to delete
        cursor, connection = db_connection
        import uuid
        from datetime import datetime, timedelta
        from tests.test_utils import generate_uuid
        
        listing_id = generate_uuid('LST')
        available_until = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
        
        cursor.execute("""
            INSERT INTO listings (
                listing_id, user_id, currency, amount, accept_currency,
                location, location_radius, meeting_preference,
                available_until, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (listing_id, test_user['user_id'], 'USD', 500.00, 'EUR',
              'Test Location', 10, 'public', available_until, 'active'))
        connection.commit()
        
        response = client.get('/Listings/DeleteListing', query_string={
            'SessionId': test_user['session_id'],
            'listingId': listing_id,
            'permanent': 'true'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        
        # Verify listing is deleted
        cursor.execute("SELECT * FROM listings WHERE listing_id = %s", (listing_id,))
        assert cursor.fetchone() is None
