"""
Unit tests for Profile endpoints
"""
import json
import pytest

class TestProfileEndpoints:
    """Test Profile blueprint routes"""
    
    def test_get_profile_success(self, client, test_user):
        """Test getting user profile"""
        response = client.get('/Profile/GetProfile', query_string={
            'SessionId': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'profile' in data
        assert data['profile']['email'] == test_user['email']
    
    def test_get_profile_invalid_session(self, client):
        """Test getting profile with invalid session"""
        response = client.get('/Profile/GetProfile', query_string={
            'SessionId': 'INVALID-SESSION'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_update_profile_success(self, client, test_user):
        """Test updating user profile"""
        response = client.get('/Profile/UpdateProfile', query_string={
            'SessionId': test_user['session_id'],
            'name': 'Updated Name',
            'email': test_user['email'],
            'phone': '555-9999',
            'location': 'New York, NY',
            'bio': 'Updated bio'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
    
    def test_update_profile_invalid_session(self, client):
        """Test updating profile with invalid session"""
        response = client.get('/Profile/UpdateProfile', query_string={
            'SessionId': 'INVALID-SESSION',
            'name': 'Test User',
            'email': 'test@example.com'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_get_exchange_history(self, client, test_user):
        """Test getting exchange history"""
        response = client.get('/Profile/GetExchangeHistory', query_string={
            'SessionId': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'exchanges' in data
        assert isinstance(data['exchanges'], list)
    
    def test_update_settings_success(self, client, test_user):
        """Test updating user settings"""
        settings = json.dumps({'preferredCurrency': 'USD', 'notifications': True})
        
        response = client.get('/Profile/UpdateSettings', query_string={
            'SessionId': test_user['session_id'],
            'settingsJson': settings
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
    
    def test_delete_account_success(self, client, db_connection):
        """Test account deletion"""
        # Create a separate user for deletion test
        cursor, connection = db_connection
        import uuid
        import bcrypt
        
        from tests.test_utils import generate_uuid
        
        user_id = generate_uuid('USR')
        email = f"delete_{uuid.uuid4().hex[:8]}@example.com"
        password = bcrypt.hashpw("TestPass123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        cursor.execute("""
            INSERT INTO users (UserId, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (user_id, "Delete", "Test", email, password, "standard", 1))
        
        session_id = generate_uuid('SES')
        cursor.execute("""
            INSERT INTO usersessions (SessionId, UserId)
            VALUES (%s, %s)
        """, (session_id, user_id))
        connection.commit()
        
        # Test deletion
        response = client.get('/Profile/DeleteAccount', query_string={
            'SessionId': session_id
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        
        # Verify user is deleted
        cursor.execute("SELECT * FROM users WHERE UserId = %s", (user_id,))
        assert cursor.fetchone() is None
