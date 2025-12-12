"""
Unit tests for Signup endpoints
"""
import json
import pytest
import uuid

class TestSignupEndpoints:
    """Test Signup blueprint routes"""
    
    def test_create_account_success(self, client, db_connection):
        """Test successful account creation"""
        cursor, connection = db_connection
        test_email = f"newuser_{uuid.uuid4().hex[:8]}@example.com"
        
        response = client.get('/Signup/CreateAccount', query_string={
            'firstName': 'John',
            'lastName': 'Doe',
            'email': test_email,
            'phone': '555-1234',
            'password': 'SecurePass123'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'sessionId' in data
        assert 'userType' in data
        
        # Cleanup - need to get user_id from session
        session_id = data['sessionId']
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        if session_result:
            user_id = session_result['user_id']
            cursor.execute("DELETE FROM usersessions WHERE user_id = %s", (user_id,))
            cursor.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        else:
            cursor.execute("DELETE FROM users WHERE Email = %s", (test_email,))
        connection.commit()
    
    def test_create_account_duplicate_email(self, client, test_user):
        """Test account creation with existing email"""
        response = client.get('/Signup/CreateAccount', query_string={
            'firstName': 'Jane',
            'lastName': 'Doe',
            'email': test_user['email'],
            'phone': '555-5678',
            'password': 'SecurePass123'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'already exists' in data['error'].lower() or 'duplicate' in data['error'].lower()
    
    def test_create_account_missing_fields(self, client):
        """Test account creation with missing required fields"""
        response = client.get('/Signup/CreateAccount', query_string={
            'firstName': 'John',
            'email': 'incomplete@example.com'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_check_email_exists(self, client, test_user):
        """Test email existence check for existing email"""
        response = client.get('/Signup/CheckEmail', query_string={
            'email': test_user['email']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['exists'] is True
    
    def test_check_email_not_exists(self, client):
        """Test email existence check for non-existing email"""
        response = client.get('/Signup/CheckEmail', query_string={
            'email': f"nonexistent_{uuid.uuid4().hex[:8]}@example.com"
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['exists'] is False
