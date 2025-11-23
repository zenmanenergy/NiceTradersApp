"""
Unit tests for Dashboard endpoints
"""
import json
import pytest

class TestDashboardEndpoints:
    """Test Dashboard blueprint routes"""
    
    def test_get_user_dashboard_success(self, client, test_user):
        """Test getting user dashboard"""
        response = client.get('/Dashboard/GetUserDashboard', query_string={
            'SessionId': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'dashboard' in data
        assert 'myListings' in data['dashboard']
        assert 'purchasedContacts' in data['dashboard']
    
    def test_get_user_dashboard_invalid_session(self, client):
        """Test getting dashboard with invalid session"""
        response = client.get('/Dashboard/GetUserDashboard', query_string={
            'SessionId': 'INVALID-SESSION'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_get_user_dashboard_missing_session(self, client):
        """Test getting dashboard without session ID"""
        response = client.get('/Dashboard/GetUserDashboard')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'required' in data['error'].lower()
    
    def test_get_user_statistics_success(self, client, test_user):
        """Test getting user statistics"""
        response = client.get('/Dashboard/GetUserStatistics', query_string={
            'SessionId': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'statistics' in data
    
    def test_get_user_statistics_invalid_session(self, client):
        """Test getting statistics with invalid session"""
        response = client.get('/Dashboard/GetUserStatistics', query_string={
            'SessionId': 'INVALID-SESSION'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
