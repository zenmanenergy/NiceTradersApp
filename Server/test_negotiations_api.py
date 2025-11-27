#!/usr/bin/env python3
"""
Test script for Negotiations API endpoints
This script validates that all endpoints are properly registered
"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://localhost:9000"

def test_endpoint_registration():
    """Test that all negotiation endpoints are registered"""
    print("=" * 70)
    print("TESTING NEGOTIATIONS API ENDPOINTS")
    print("=" * 70)
    
    endpoints = [
        "/Negotiations/Propose",
        "/Negotiations/Get",
        "/Negotiations/Accept",
        "/Negotiations/Reject",
        "/Negotiations/Counter",
        "/Negotiations/Pay",
        "/Negotiations/GetMyNegotiations",
        "/Negotiations/GetBuyerInfo"
    ]
    
    print("\n📋 Testing endpoint registration (without valid parameters)...")
    print("-" * 70)
    
    for endpoint in endpoints:
        url = f"{BASE_URL}{endpoint}"
        try:
            response = requests.get(url, timeout=5)
            
            # We expect error responses due to missing parameters
            # But the endpoint should exist (not 404)
            if response.status_code == 404:
                print(f"❌ {endpoint:<40} NOT FOUND (404)")
            else:
                try:
                    data = response.json()
                    if 'error' in data:
                        print(f"✅ {endpoint:<40} Registered (returns error as expected)")
                    else:
                        print(f"✅ {endpoint:<40} Registered")
                except:
                    print(f"⚠️  {endpoint:<40} Registered (non-JSON response)")
                    
        except requests.exceptions.ConnectionRefused:
            print(f"\n❌ Cannot connect to server at {BASE_URL}")
            print("   Make sure Flask server is running on port 9000")
            return False
        except requests.exceptions.Timeout:
            print(f"⏱️  {endpoint:<40} Timeout")
        except Exception as e:
            print(f"❌ {endpoint:<40} Error: {str(e)}")
    
    print("\n" + "=" * 70)
    print("✅ Endpoint registration test complete!")
    print("\nTo start the Flask server, run:")
    print("  cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server")
    print("  flask --app flask_app run --host=0.0.0.0 --port=9000")
    print("=" * 70)
    return True

def print_api_documentation():
    """Print API documentation for all negotiation endpoints"""
    print("\n" + "=" * 70)
    print("NEGOTIATIONS API DOCUMENTATION")
    print("=" * 70)
    
    docs = [
        {
            "endpoint": "POST /Negotiations/Propose",
            "description": "Buyer proposes initial meeting time",
            "params": "listingId, sessionId, proposedTime (ISO 8601)",
            "returns": "negotiationId, status, proposedTime"
        },
        {
            "endpoint": "GET /Negotiations/Get",
            "description": "Get negotiation details",
            "params": "negotiationId, sessionId",
            "returns": "Full negotiation details with buyer/seller info"
        },
        {
            "endpoint": "POST /Negotiations/Accept",
            "description": "Accept current proposal (sets 2hr payment deadline)",
            "params": "negotiationId, sessionId",
            "returns": "status: agreed, paymentDeadline"
        },
        {
            "endpoint": "POST /Negotiations/Reject",
            "description": "Reject negotiation outright",
            "params": "negotiationId, sessionId",
            "returns": "status: rejected"
        },
        {
            "endpoint": "POST /Negotiations/Counter",
            "description": "Counter-propose new meeting time",
            "params": "negotiationId, sessionId, proposedTime (ISO 8601)",
            "returns": "status: countered, proposedTime"
        },
        {
            "endpoint": "POST /Negotiations/Pay",
            "description": "Pay $2 fee (auto-applies credits)",
            "params": "negotiationId, sessionId",
            "returns": "transactionId, amountCharged, creditApplied, bothPaid"
        },
        {
            "endpoint": "GET /Negotiations/GetMyNegotiations",
            "description": "Get user's active negotiations",
            "params": "sessionId",
            "returns": "Array of negotiations (as buyer or seller)"
        },
        {
            "endpoint": "GET /Negotiations/GetBuyerInfo",
            "description": "Get buyer info for seller review",
            "params": "buyerId, sessionId",
            "returns": "Buyer photo, rating, transaction history"
        }
    ]
    
    for doc in docs:
        print(f"\n📌 {doc['endpoint']}")
        print(f"   Description: {doc['description']}")
        print(f"   Parameters:  {doc['params']}")
        print(f"   Returns:     {doc['returns']}")
    
    print("\n" + "=" * 70)

if __name__ == '__main__':
    test_endpoint_registration()
    print_api_documentation()
