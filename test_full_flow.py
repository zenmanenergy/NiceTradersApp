#!/usr/bin/env python3
"""Test the full location proposal flow"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from Meeting.GetMeetingProposals import get_meeting_proposals
from Meeting.RespondToMeeting import respond_to_meeting
import json
import pymysql
import pymysql.cursors

# Get session
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

cursor.execute("SELECT SessionId, user_id FROM usersessions LIMIT 1")
session_row = cursor.fetchone()
session_id = session_row['SessionId']
user_id = session_row['user_id']

listing_id = '684e682e-cd15-4084-b92b-3b5c3ab8e639'

print("\n===== 1. Get Current Proposals =====\n")
result = get_meeting_proposals(session_id, listing_id)
result_json = json.loads(result)

print(f"Found {len(result_json['proposals'])} proposals")
print(f"Current meeting: {result_json['current_meeting']}")

if result_json['proposals']:
    print("\nProposals:")
    for p in result_json['proposals']:
        print(f"  - {p['proposal_id']}: {p['action']} - {p['proposed_location']} - Status: {p['status']}")
    
    # Try to accept the first proposal
    first_proposal_id = result_json['proposals'][0]['proposal_id']
    
    print(f"\n===== 2. Accept First Proposal: {first_proposal_id} =====\n")
    
    # Get the proposer user to accept as them
    cursor.execute("""
        SELECT DISTINCT proposed_by FROM negotiation_history 
        WHERE history_id = %s
    """, (first_proposal_id,))
    proposer_row = cursor.fetchone()
    
    if proposer_row:
        proposer_id = proposer_row['proposed_by']
        # Get proposer's session
        cursor.execute("SELECT SessionId FROM usersessions WHERE user_id = %s LIMIT 1", (proposer_id,))
        proposer_session_row = cursor.fetchone()
        
        if proposer_session_row:
            proposer_session = proposer_session_row['SessionId']
            
            # Now accept as the other party
            response = respond_to_meeting(session_id, first_proposal_id, 'accepted')
            response_json = json.loads(response)
            
            print(f"Accept response: {json.dumps(response_json, indent=2)}")
            
            # Now get proposals again to see if current_meeting is set
            print(f"\n===== 3. Get Proposals After Acceptance =====\n")
            result2 = get_meeting_proposals(session_id, listing_id)
            result2_json = json.loads(result2)
            
            print(f"Current meeting after acceptance: {result2_json['current_meeting']}")

db.close()
