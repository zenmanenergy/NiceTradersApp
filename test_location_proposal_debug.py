#!/usr/bin/env python3
"""Test script to debug location proposal flow"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://localhost:9000"

# Test with known listing_id and session
listing_id = "684e682e-cd15-4084-b92b-3b5c3ab8e639"
session_id = "YOUR_SESSION_ID_HERE"  # Will need to get this

def test_get_meeting_proposals():
    """Test GetMeetingProposals endpoint"""
    print("\n=== Testing GetMeetingProposals ===")
    url = f"{BASE_URL}/Meeting/GetMeetingProposals"
    params = {
        "session_id": session_id,
        "listing_id": listing_id
    }
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

def test_propose_location():
    """Test ProposeMeeting endpoint for location proposal"""
    print("\n=== Testing ProposeMeeting (Location) ===")
    url = f"{BASE_URL}/Meeting/ProposeMeeting"
    
    params = {
        "session_id": session_id,
        "listing_id": listing_id,
        "proposed_location": "TEST_LOCATION",
        "proposed_latitude": "40.7128",
        "proposed_longitude": "-74.0060",
    }
    
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print("Location Proposal Debug Test")
    print(f"Base URL: {BASE_URL}")
    print(f"Listing ID: {listing_id}")
    print("\nNote: Update session_id in script before running")
    
    # Uncomment to test:
    # test_propose_location()
    # test_get_meeting_proposals()
