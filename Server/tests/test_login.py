"""
Unit tests for Login endpoints
"""
import json
import pytest
import hashlib

class TestLoginEndpoints:
    """Test Login blueprint routes"""
    
    def test_login_success(self, client, db_connection):
        """Test successful login"""
        # Create a user with SHA256 password for login test
        cursor, connection = db_connection
        import uuid
        from tests.test_utils import generate_uuid
        
        user_id = generate_uuid('USR')
        email = f"login_{uuid.uuid4().hex[:8]}@example.com"
        password = "TestPassword123"
        hashed_password = hashlib.sha256(password.encode()).hexdigest()
        
        cursor.execute("""
            INSERT INTO users (UserId, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (user_id, "Login", "Test", email, hashed_password, "standard", 1))
        connection.commit()
        
        response = client.get('/Login/Login', query_string={
            'Email': email,
            'Password': password
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'SessionId' in data
        assert 'UserType' in data
        
        # Cleanup
        cursor.execute("DELETE FROM usersessions WHERE UserId = %s", (user_id,))
        cursor.execute("DELETE FROM users WHERE UserId = %s", (user_id,))
        connection.commit()
    
    def test_login_invalid_credentials(self, client):
        """Test login with invalid credentials"""
        response = client.get('/Login/Login', query_string={
            'Email': 'nonexistent@example.com',
            'Password': 'WrongPassword'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'error' in data
    
    def test_login_missing_parameters(self, client):
        """Test login with missing parameters"""
        response = client.get('/Login/Login', query_string={
            'Email': 'test@example.com'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_verify_session_valid(self, client, test_user):
        """Test session verification with valid session"""
        response = client.get('/Login/Verify', query_string={
            'SessionId': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'SessionId' in data
        assert data['SessionId'] == test_user['session_id']
    
    def test_verify_session_invalid(self, client):
        """Test session verification with invalid session"""
        response = client.get('/Login/Verify', query_string={
            'SessionId': 'INVALID-SESSION-ID'
        })
        
        assert response.status_code == 200
        # API returns empty string "" for invalid session
        assert response.data == b'""'
