#!/usr/bin/env python3
"""Direct test of GetMeetingProposals to see debug output"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from Meeting.GetMeetingProposals import get_meeting_proposals
import json

# We need a valid session - let's check the database for one
import pymysql
import pymysql.cursors

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

# Get a valid session ID
cursor.execute("SELECT session_id, user_id FROM user_sessions LIMIT 1")
session_row = cursor.fetchone()

if not session_row:
    print("ERROR: No active sessions found in database")
    sys.exit(1)

session_id = session_row['session_id']
user_id = session_row['user_id']

print(f"\nUsing session_id: {session_id}")
print(f"User ID: {user_id}")

db.close()

# Now call GetMeetingProposals with debugging
listing_id = '684e682e-cd15-4084-b92b-3b5c3ab8e639'

print(f"\nCalling get_meeting_proposals({session_id}, {listing_id})")
print("=" * 60)

result = get_meeting_proposals(session_id, listing_id)
result_json = json.loads(result)

print("=" * 60)
print("\nResult:")
print(json.dumps(result_json, indent=2, default=str))
