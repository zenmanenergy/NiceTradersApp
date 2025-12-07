from _Lib import Database
import json
import uuid
from datetime import datetime, timedelta

def propose_meeting(session_id, listing_id, proposed_location, proposed_time, proposed_latitude=None, proposed_longitude=None, message=None):
    """Propose a meeting time and/or location for an exchange"""
    try:
        print(f"[ProposeMeeting] Creating meeting proposal for listing: {listing_id}")
        
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
            SELECT UserId FROM usersessions 
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
        
        proposer_id = session_result['UserId']
        
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
        
        # Get or create negotiation for this listing
        negotiation_query = """
            SELECT negotiation_id, status, current_proposed_time FROM exchange_negotiations
            WHERE listing_id = %s AND user_id IN (%s, %s)
            LIMIT 1
        """
        cursor.execute(negotiation_query, (listing_id, proposer_id, recipient_id))
        negotiation = cursor.fetchone()
        
        if not negotiation:
            # Create new negotiation - requires time for initial proposal
            if not proposed_time:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Initial proposal requires both time and location'
                })
            negotiation_id = str(uuid.uuid4())
            create_negotiation_query = """
                INSERT INTO exchange_negotiations 
                (negotiation_id, listing_id, user_id, status, created_at)
                VALUES (%s, %s, %s, %s, NOW())
            """
            cursor.execute(create_negotiation_query, (negotiation_id, listing_id, proposer_id, 'pending'))
            connection.commit()
            negotiation_id_str = negotiation_id
            agreed_time = None
        else:
            negotiation_id_str = negotiation['negotiation_id']
            agreed_time = negotiation['current_proposed_time']
        
        # Parse proposed time if provided, otherwise use existing agreed time
        proposed_datetime = None
        if proposed_time:
            try:
                proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
            except ValueError:
                try:
                    proposed_datetime = datetime.strptime(proposed_time, '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    connection.close()
                    return json.dumps({
                        'success': False,
                        'error': 'Invalid datetime format. Use ISO format or YYYY-MM-DD HH:MM:SS'
                    })
        elif agreed_time:
            # Use existing agreed time for location-only proposals
            proposed_datetime = agreed_time
        else:
            # No time provided and no existing agreed time
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'No meeting time available. Please agree on a time first.'
            })
        
        # Create history record in negotiation_history table
        history_id = str(uuid.uuid4())
        insert_query = """
            INSERT INTO negotiation_history 
            (history_id, negotiation_id, action, proposed_time, proposed_location, 
             proposed_latitude, proposed_longitude, proposed_by, notes, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """
        cursor.execute(insert_query, (
            history_id, negotiation_id_str, 'initial_proposal',
            proposed_datetime, proposed_location, proposed_latitude, proposed_longitude,
            proposer_id, message
        ))
        
        connection.commit()
        
        # Get proposer name for notification
        cursor.execute("SELECT FirstName, LastName FROM users WHERE UserId = %s", (proposer_id,))
        proposer = cursor.fetchone()
        proposer_name = f"{proposer['FirstName']} {proposer['LastName']}" if proposer else "A user"
        
        # Format the proposed time for the notification
        time_str = proposed_datetime.strftime('%b %d at %I:%M %p')
        
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