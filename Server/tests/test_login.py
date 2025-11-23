"""
Unit tests for Login endpoints
"""
import json
import pytest

class TestLoginEndpoints:
    """Test Login blueprint routes"""
    
    def test_login_success(self, client, test_user):
        """Test successful login"""
        response = client.get('/Login/Login', query_string={
            'Email': test_user['email'],
            'Password': test_user['password']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'sessionId' in data
        assert 'userType' in data
    
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
        assert data['success'] is True
        assert data['userId'] == test_user['user_id']
    
    def test_verify_session_invalid(self, client):
        """Test session verification with invalid session"""
        response = client.get('/Login/Verify', query_string={
            'SessionId': 'INVALID-SESSION-ID'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
