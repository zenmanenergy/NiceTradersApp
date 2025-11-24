"""
Unit tests for Search endpoints
"""
import json
import pytest

class TestSearchEndpoints:
    """Test Search blueprint routes"""
    
    def test_search_listings_basic(self, client):
        """Test basic listing search"""
        response = client.get('/Search/SearchListings', query_string={
            'currency': 'USD',
            'limit': 10,
            'offset': 0
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listings' in data
        assert isinstance(data['listings'], list)
    
    def test_search_listings_with_filters(self, client):
        """Test listing search with multiple filters"""
        response = client.get('/Search/SearchListings', query_string={
            'currency': 'USD',
            'acceptCurrency': 'EUR',
            'minAmount': '100',
            'maxAmount': '1000',
            'maxDistance': '25',
            'userLatitude': '37.7749',
            'userLongitude': '-122.4194',
            'limit': 20,
            'offset': 0
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listings' in data
        assert 'pagination' in data
    
    def test_search_listings_with_location(self, client):
        """Test listing search with location filter and distance"""
        response = client.get('/Search/SearchListings', query_string={
            'currency': 'USD',
            'location': 'San Francisco, CA',
            'maxDistance': '50',
            'userLatitude': '37.7749',
            'userLongitude': '-122.4194',
            'limit': 10
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listings' in data
        assert 'pagination' in data
    
    def test_search_currency_swap_logic(self, client):
        """Test that currency search logic works correctly.
        When searching for 'I have USD, want GBP', we need to find
        listings that have GBP and accept USD."""
        response = client.get('/Search/SearchListings', query_string={
            'currency': 'GBP',  # What the listing owner has (what I want)
            'acceptCurrency': 'USD',  # What the listing owner wants (what I have)
            'limit': 10
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'listings' in data
        
        # Verify returned listings match the filter criteria
        for listing in data['listings']:
            if listing['currency'] and listing['acceptCurrency']:
                assert listing['currency'] == 'GBP'
                assert listing['acceptCurrency'] == 'USD'
    
    def test_get_search_filters(self, client):
        """Test getting available search filters"""
        response = client.get('/Search/GetSearchFilters')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'currencies' in data
        assert 'acceptCurrencies' in data
    
    def test_get_popular_searches(self, client):
        """Test getting popular searches"""
        response = client.get('/Search/GetPopularSearches')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'popularPairs' in data
        assert 'popularLocations' in data
        assert 'trendingCurrencies' in data
