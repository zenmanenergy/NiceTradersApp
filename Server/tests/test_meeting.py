"""
Unit tests for Meeting endpoints
"""
import json
import pytest
from datetime import datetime, timedelta

class TestMeetingEndpoints:
    """Test Meeting blueprint routes"""
    
    def test_propose_meeting(self, client, db_connection):
        """Test proposing a meeting"""
        # Create two users and a listing with contact access
        cursor, connection = db_connection
        import uuid
        import bcrypt
        
        from tests.test_utils import generate_uuid
        
        # Create proposer user
        proposer_id = generate_uuid('USR')
        proposer_email = f"proposer_{uuid.uuid4().hex[:8]}@example.com"
        password = bcrypt.hashpw("TestPass123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        cursor.execute("""
            INSERT INTO users (user_id, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (proposer_id, "Proposer", "User", proposer_email, password, "standard", 1))
        
        proposer_session = generate_uuid('SES')
        cursor.execute("""
            INSERT INTO user_sessions (session_id, user_id)
            VALUES (%s, %s)
        """, (proposer_session, proposer_id))
        
        # Create recipient user
        recipient_id = generate_uuid('USR')
        recipient_email = f"recipient_{uuid.uuid4().hex[:8]}@example.com"
        
        cursor.execute("""
            INSERT INTO users (user_id, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (recipient_id, "Recipient", "User", recipient_email, password, "standard", 1))
        
        # Create listing
        listing_id = generate_uuid('LST')
        available_until = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
        
        cursor.execute("""
            INSERT INTO listings (
                listing_id, user_id, currency, amount, accept_currency,
                location, location_radius, meeting_preference,
                available_until, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (listing_id, recipient_id, 'USD', 1000.00, 'EUR',
              'Test Location', 10, 'public', available_until, 'active'))
        
        # Create listing_meeting_time entry for negotiation
        cursor.execute("""
            INSERT INTO listing_meeting_time (
                listing_id, buyer_id, meeting_time, created_at
            ) VALUES (%s, %s, NOW(), NOW())
        """, (listing_id, proposer_id))
        connection.commit()
        
        # Test propose meeting
        proposed_time = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d %H:%M:%S')
        
        response = client.post('/Meeting/ProposeMeeting',
            json={
                'session_id': proposer_session,
                'listingId': listing_id,
                'proposedLocation': 'Starbucks on Main St',
                'proposedTime': proposed_time,
                'message': 'Let\'s meet tomorrow'
            },
            content_type='application/json'
        )
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        
        # Cleanup
        cursor.execute("DELETE FROM meeting_proposals WHERE listing_id = %s", (listing_id,))
        cursor.execute("DELETE FROM listing_meeting_time WHERE listing_id = %s", (listing_id,))
        cursor.execute("DELETE FROM listing_payments WHERE listing_id = %s", (listing_id,))
        cursor.execute("DELETE FROM listings WHERE listing_id = %s", (listing_id,))
        cursor.execute("DELETE FROM user_sessions WHERE user_id IN (%s, %s)", (proposer_id, recipient_id))
        cursor.execute("DELETE FROM users WHERE user_id IN (%s, %s)", (proposer_id, recipient_id))
        connection.commit()
    
    def test_get_meeting_proposals(self, client, test_listing, test_user):
        """Test getting meeting proposals for a listing"""
        response = client.get('/Meeting/GetMeetingProposals', query_string={
            'session_id': test_user['session_id'],
            'listingId': test_listing['listing_id']
        })
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        assert 'proposals' in data
    
    def test_respond_to_meeting(self, client, db_connection):
        """Test responding to a meeting proposal"""
        # Create meeting proposal first
        cursor, connection = db_connection
        import uuid
        import bcrypt
        from tests.test_utils import generate_uuid
        
        # Create users and listing
        user1_id = generate_uuid('USR')
        user1_email = f"user1_{uuid.uuid4().hex[:8]}@example.com"
        password = bcrypt.hashpw("TestPass123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        cursor.execute("""
            INSERT INTO users (user_id, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (user1_id, "User1", "Test", user1_email, password, "standard", 1))
        
        user1_session = generate_uuid('SES')
        cursor.execute("""
            INSERT INTO user_sessions (session_id, user_id)
            VALUES (%s, %s)
        """, (user1_session, user1_id))
        
        user2_id = generate_uuid('USR')
        user2_email = f"user2_{uuid.uuid4().hex[:8]}@example.com"
        
        cursor.execute("""
            INSERT INTO users (user_id, FirstName, LastName, Email, Password, UserType, IsActive)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (user2_id, "User2", "Test", user2_email, password, "standard", 1))
        
        # Create listing
        listing_id = generate_uuid('LST')
        available_until = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
        
        cursor.execute("""
            INSERT INTO listings (
                listing_id, user_id, currency, amount, accept_currency,
                location, location_radius, meeting_preference,
                available_until, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (listing_id, user1_id, 'USD', 1000.00, 'EUR',
              'Test Location', 10, 'public', available_until, 'active'))
        
        # Create proposal
        proposal_id = generate_uuid('MPR')
        proposed_time = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d %H:%M:%S')
        
        cursor.execute("""
            INSERT INTO meeting_proposals (
                proposal_id, listing_id, proposer_id, recipient_id,
                proposed_location, proposed_time, status
            ) VALUES (%s, %s, %s, %s, %s, %s, 'pending')
        """, (proposal_id, listing_id, user2_id, user1_id, 'Test Location', proposed_time))
        connection.commit()
        
        # Test respond to meeting
        response = client.post('/Meeting/RespondToMeeting',
            json={
                'session_id': user1_session,
                'proposalId': proposal_id,
                'response': 'accepted'
            },
            content_type='application/json'
        )
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] is True
        
        # Cleanup
        cursor.execute("DELETE FROM meeting_proposals WHERE proposal_id = %s", (proposal_id,))
        cursor.execute("DELETE FROM listings WHERE listing_id = %s", (listing_id,))
        cursor.execute("DELETE FROM user_sessions WHERE user_id IN (%s, %s)", (user1_id, user2_id))
        cursor.execute("DELETE FROM users WHERE user_id IN (%s, %s)", (user1_id, user2_id))
        connection.commit()
