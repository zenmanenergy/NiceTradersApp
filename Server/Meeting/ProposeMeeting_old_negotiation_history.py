from _Lib import Database
import json
import uuid
from datetime import datetime, timedelta

def propose_meeting(session_id, listing_id, proposed_location, proposed_time, proposed_latitude=None, proposed_longitude=None, message=None):
    """Propose a meeting time and/or location for an exchange"""
    try:
        print(f"[ProposeMeeting] ===== START PROPOSAL =====")
        print(f"[ProposeMeeting] Input params:")
        print(f"  session_id: {session_id}")
        print(f"  listing_id: {listing_id}")
        print(f"  proposed_location: {proposed_location}")
        print(f"  proposed_time: {proposed_time}")
        print(f"  proposed_latitude: {proposed_latitude}")
        print(f"  proposed_longitude: {proposed_longitude}")
        print(f"  message: {message}")
        
        # Either location or time must be provided
        if not session_id or not listing_id or (not proposed_location and not proposed_time):
            return json.dumps({
                'success': False,
                'error': 'Session ID, listing ID, and either location or time are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM usersessions 
            WHERE SessionId = %s
        """
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        proposer_id = session_result['user_id']
        
        # Get listing info and determine recipient
        listing_query = """
            SELECT l.user_id as listing_owner_id
            FROM listings l
            WHERE l.listing_id = %s
        """
        cursor.execute(listing_query, (listing_id,))
        listing_result = cursor.fetchone()
        
        if not listing_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        listing_owner_id = listing_result['listing_owner_id']
        
        # Determine recipient based on who is proposing
        if proposer_id == listing_owner_id:
            # Listing owner is proposing - find the buyer from contact_access
            recipient_query = """
                SELECT user_id FROM contact_access 
                WHERE listing_id = %s AND status = 'active'
                ORDER BY purchased_at DESC LIMIT 1
            """
            cursor.execute(recipient_query, (listing_id,))
            recipient_result = cursor.fetchone()
            
            if not recipient_result:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'No active contact access found for this listing'
                })
            recipient_id = recipient_result['user_id']
        else:
            # Buyer is proposing to listing owner
            # Verify buyer has access to this listing
            access_query = """
                SELECT access_id FROM contact_access 
                WHERE listing_id = %s AND user_id = %s AND status = 'active'
            """
            cursor.execute(access_query, (listing_id, proposer_id))
            if not cursor.fetchone():
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'You do not have access to propose meetings for this listing'
                })
            recipient_id = listing_owner_id
        
        # For meeting proposals (location/time), we work directly with negotiation_history
        # Get any existing negotiation for this listing to link proposals together
        negotiation_query = """
            SELECT negotiation_id FROM negotiation_history
            WHERE listing_id = %s 
            LIMIT 1
        """
        cursor.execute(negotiation_query, (listing_id,))
        negotiation = cursor.fetchone()
        
        if negotiation:
            negotiation_id_str = negotiation['negotiation_id']
            is_counter_proposal = True  # Existing proposals exist, so this is a counter-proposal
            print(f"[ProposeMeeting] Existing negotiation found: {negotiation_id_str}")
        else:
            # Create new negotiation ID for this listing
            negotiation_id_str = str(uuid.uuid4())
            is_counter_proposal = False  # First proposal
            print(f"[ProposeMeeting] Creating NEW negotiation: {negotiation_id_str}")
        
        # Parse proposed time if provided
        proposed_datetime = None
        if proposed_time:
            try:
                proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
                print(f"[ProposeMeeting] Parsed time (ISO format): {proposed_datetime}")
            except ValueError:
                try:
                    proposed_datetime = datetime.strptime(proposed_time, '%Y-%m-%d %H:%M:%S')
                    print(f"[ProposeMeeting] Parsed time (SQL format): {proposed_datetime}")
                except ValueError:
                    # If we can't parse it, just ignore it and continue with location-only proposal
                    print(f"[ProposeMeeting] Warning: Could not parse time format: {proposed_time}")
                    proposed_datetime = None
        
        # Create history record in negotiation_history table
        history_id = str(uuid.uuid4())
        
        # Determine action type
        if proposed_location and is_counter_proposal:
            action = 'counter_proposal'  # Counter-proposing a different location
        elif proposed_location:
            action = 'location_proposal'  # First location proposal
        else:
            action = 'time_proposal'  # First time proposal (location will be added later)
        
        print(f"[ProposeMeeting] Action type: {action}")
        print(f"[ProposeMeeting] Proposed location: {proposed_location}")
        print(f"[ProposeMeeting] Proposed datetime: {proposed_datetime}")
        print(f"[ProposeMeeting] Coordinates: ({proposed_latitude}, {proposed_longitude})")
        
        insert_query = """
            INSERT INTO negotiation_history 
            (history_id, negotiation_id, listing_id, action, proposed_time, proposed_location, 
             proposed_latitude, proposed_longitude, proposed_by, notes, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """
        print(f"[ProposeMeeting] Inserting record with:")
        print(f"  history_id: {history_id}")
        print(f"  negotiation_id: {negotiation_id_str}")
        print(f"  listing_id: {listing_id}")
        print(f"  action: {action}")
        
        cursor.execute(insert_query, (
            history_id, negotiation_id_str, listing_id, action,
            proposed_datetime, proposed_location, proposed_latitude, proposed_longitude,
            proposer_id, message
        ))
        
        connection.commit()
        print(f"[ProposeMeeting] Database commit successful")
        
        # Get proposer name for notification
        cursor.execute("SELECT FirstName, LastName FROM users WHERE user_id = %s", (proposer_id,))
        proposer = cursor.fetchone()
        proposer_name = f"{proposer['FirstName']} {proposer['LastName']}" if proposer else "A user"
        
        # Format the proposed time for the notification (if available)
        time_str = proposed_datetime.strftime('%b %d at %I:%M %p') if proposed_datetime else "TBD"
        
        # Send APN notification to recipient
        try:
            from Admin.NotificationService import notification_service
            notification_service.send_meeting_proposal_notification(
                recipient_id=recipient_id,
                proposer_name=proposer_name,
                proposed_time=time_str,
                listing_id=listing_id,
                proposal_id=history_id
                # session_id is automatically fetched inside notification_service
            )
        except Exception as apn_error:
            # Log error but don't fail the transaction
            print(f"[ProposeMeeting] Error sending APN notification: {apn_error}")
        
        connection.close()
        
        print(f"[ProposeMeeting] Meeting proposal created successfully: {history_id}")
        print(f"[ProposeMeeting] ===== END PROPOSAL =====")
        
        return json.dumps({
            'success': True,
            'proposal_id': history_id,
            'message': 'Meeting proposal sent successfully'
        })
        
    except Exception as e:
        print(f"[ProposeMeeting] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to create meeting proposal: {str(e)}'
        })