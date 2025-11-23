"""
Unit tests for ExchangeRates endpoints
"""
import json
import pytest

class TestExchangeRatesEndpoints:
    """Test ExchangeRates blueprint routes"""
    
    def test_download_exchange_rates(self, client):
        """Test downloading exchange rates from external API"""
        response = client.get('/ExchangeRates/Download')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
    
    def test_get_exchange_rates(self, client):
        """Test getting all exchange rates"""
        response = client.get('/ExchangeRates/GetRates')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'rates' in data
        assert isinstance(data['rates'], dict)
    
    def test_get_specific_exchange_rate(self, client):
        """Test getting rate between two currencies"""
        response = client.get('/ExchangeRates/GetRate', query_string={
            'fromCurrency': 'USD',
            'toCurrency': 'EUR'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'rate' in data
    
    def test_get_exchange_rate_missing_params(self, client):
        """Test getting rate without required parameters"""
        response = client.get('/ExchangeRates/GetRate', query_string={
            'fromCurrency': 'USD'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'required' in data['error'].lower()
    
    def test_convert_amount(self, client):
        """Test currency amount conversion"""
        response = client.get('/ExchangeRates/Convert', query_string={
            'amount': '100',
            'fromCurrency': 'USD',
            'toCurrency': 'EUR'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'converted_amount' in data
        assert 'exchange_rate' in data
        assert 'original_amount' in data
    
    def test_convert_amount_invalid_amount(self, client):
        """Test conversion with invalid amount"""
        response = client.get('/ExchangeRates/Convert', query_string={
            'amount': 'invalid',
            'fromCurrency': 'USD',
            'toCurrency': 'EUR'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'invalid' in data['error'].lower() or 'number' in data['error'].lower()
    
    def test_convert_amount_missing_params(self, client):
        """Test conversion without all required parameters"""
        response = client.get('/ExchangeRates/Convert', query_string={
            'amount': '100',
            'fromCurrency': 'USD'
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is False
