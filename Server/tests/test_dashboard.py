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
            'session_id': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'data' in data
        assert 'recentListings' in data['data']
        assert 'pendingOffers' in data['data']
        assert 'stats' in data['data']
        assert 'user' in data['data']
    
    def test_get_user_dashboard_invalid_session(self, client):
        """Test getting dashboard with invalid session"""
        response = client.get('/Dashboard/GetUserDashboard', query_string={
            'session_id': 'INVALID-SESSION'
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
            'session_id': test_user['session_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'data' in data
        assert 'tradingVolume' in data['data']
        assert 'listingsByStatus' in data['data']
        assert 'transactionsByStatus' in data['data']
        assert 'topCurrencies' in data['data']
    
    def test_get_user_statistics_invalid_session(self, client):
        """Test getting statistics with invalid session"""
        response = client.get('/Dashboard/GetUserStatistics', query_string={
            'session_id': 'INVALID-SESSION'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
