#!/usr/bin/env python3
"""Test script to debug negotiation proposal"""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from Negotiations.ProposeNegotiation import propose_negotiation
from datetime import datetime, timedelta

# Test data - replace with actual values from your app
listing_id = "29b6d8a7-0b21-4be9-a0f7-db78188eb1ef"
session_id = "SESd4bc838a-3a96-40df-ae38-d26b5a5bcdb1"  # From the URL in screenshot

# Propose a time 2 days from now
proposed_time = (datetime.now() + timedelta(days=2)).isoformat()

print(f"Testing negotiation proposal...")
print(f"Listing ID: {listing_id}")
print(f"Session ID: {session_id}")
print(f"Proposed Time: {proposed_time}")
print()

result = propose_negotiation(listing_id, session_id, proposed_time)
print("Result:")
print(result)
