#!/usr/bin/env python3
"""
Test script to check if dashboard displayStatus is being calculated correctly
"""
import sys
import json
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from Dashboard.GetUserDashboard import get_user_dashboard

# Test with a known session
session_id = "YOUR_SESSION_ID_HERE"

print("Testing Dashboard API...")
result = get_user_dashboard(session_id)
data = json.loads(result)

if data['success']:
    print(f"\n✓ Dashboard fetch successful")
    dashboard_data = data['data']
    
    print(f"\nTotal active exchanges: {len(dashboard_data['activeExchanges'])}")
    for exchange in dashboard_data['activeExchanges']:
        print(f"\n---")
        print(f"Listing ID: {exchange['listingId']}")
        print(f"Amount: {exchange['amount']} {exchange['currency']} → {exchange['acceptCurrency']}")
        print(f"Trader: {exchange['otherUser']['name']}")
        print(f"displayStatus: {exchange.get('displayStatus', 'MISSING!')}")
        print(f"negotiationStatus: {exchange.get('negotiationStatus', 'MISSING!')}")
        print(f"acceptedAt: {exchange.get('acceptedAt', 'None')}")
        
        # These should be used by calculate_negotiation_status
        listing = exchange['listing']
        print(f"\nDebug info:")
        print(f"  - Has location proposal: {exchange.get('hasLocationProposal', '?')}")
        print(f"  - Time accepted: {exchange.get('acceptedAt') is not None}")
else:
    print(f"✗ Dashboard fetch failed: {data.get('error', 'Unknown error')}")
