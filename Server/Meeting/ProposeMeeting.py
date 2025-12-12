from _Lib import Database
import json
import uuid
from datetime import datetime, timedelta

def propose_meeting(session_id, listing_id, proposed_location, proposed_time, proposed_latitude=None, proposed_longitude=None, message=None):
    """Propose a meeting time and/or location for an exchange (using new normalized tables)"""
    try:
        print(f"[ProposeMeeting] ===== START PROPOSAL =====")
        print(f"[ProposeMeeting] Input params:")
        print(f"  session_id: {session_id}")
        print(f"  listing_id: {listing_id}")
        print(f"  proposed_location: {proposed_location}")
        print(f"  proposed_time: {proposed_time}")
        print(f"  proposed_latitude: {proposed_latitude}")
        print(f"  proposed_longitude: {proposed_longitude}")
        
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
            SELECT l.user_id as listing_owner_id, l.buyer_id
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
        buyer_id = listing_result['buyer_id']
        
        # Determine recipient and validate access
        if proposer_id == listing_owner_id:
            # Listing owner is proposing - must have a buyer
            if not buyer_id:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'No buyer has been set for this listing yet'
                })
            recipient_id = buyer_id
        else:
            # Buyer is proposing
            if proposer_id != buyer_id:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'You are not the buyer for this listing'
                })
            recipient_id = listing_owner_id
        
        results = {
            'success': True,
            'proposal_ids': {},
            'message': 'Meeting proposal created'
        }
        
        # Handle TIME proposal
        if proposed_time:
            try:
                proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
            except:
                try:
                    proposed_datetime = datetime.strptime(proposed_time, '%Y-%m-%d %H:%M:%S')
                except:
                    connection.close()
                    return json.dumps({
                        'success': False,
                        'error': 'Invalid time format'
                    })
            
            time_negotiation_id = f"TNL-{uuid.uuid4().hex[:35]}"
            
            # Check if time negotiation already exists for this listing
            cursor.execute("""
                SELECT time_negotiation_id FROM listing_meeting_time 
                WHERE listing_id = %s
                LIMIT 1
            """, (listing_id,))
            existing = cursor.fetchone()
            
            if existing:
                # Update existing time negotiation
                cursor.execute("""
                    UPDATE listing_meeting_time 
                    SET meeting_time = %s, proposed_by = %s, updated_at = NOW()
                    WHERE listing_id = %s
                """, (proposed_datetime, proposer_id, listing_id))
            else:
                # Create new time negotiation
                cursor.execute("""
                    INSERT INTO listing_meeting_time
                    (time_negotiation_id, listing_id, buyer_id, proposed_by, meeting_time, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
                """, (time_negotiation_id, listing_id, buyer_id, proposer_id, proposed_datetime))
            
            results['proposal_ids']['time'] = time_negotiation_id
            print(f"[ProposeMeeting] Time proposal created/updated: {time_negotiation_id}")
        
        # Handle LOCATION proposal
        if proposed_location and proposed_latitude is not None and proposed_longitude is not None:
            try:
                lat = float(proposed_latitude)
                lng = float(proposed_longitude)
                
                # Validate coordinates
                if lat < -90 or lat > 90 or lng < -180 or lng > 180:
                    connection.close()
                    return json.dumps({
                        'success': False,
                        'error': 'Invalid coordinates'
                    })
            except:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Coordinates must be valid numbers'
                })
            
            location_negotiation_id = f"LOC-{uuid.uuid4().hex[:35]}"
            
            # Check if location negotiation already exists for this listing
            cursor.execute("""
                SELECT location_negotiation_id FROM listing_meeting_location 
                WHERE listing_id = %s
                LIMIT 1
            """, (listing_id,))
            existing = cursor.fetchone()
            
            if existing:
                # Update existing location negotiation
                cursor.execute("""
                    UPDATE listing_meeting_location 
                    SET meeting_location_lat = %s, 
                        meeting_location_lng = %s,
                        meeting_location_name = %s,
                        proposed_by = %s,
                        updated_at = NOW()
                    WHERE listing_id = %s
                """, (lat, lng, proposed_location, proposer_id, listing_id))
            else:
                # Create new location negotiation
                cursor.execute("""
                    INSERT INTO listing_meeting_location
                    (location_negotiation_id, listing_id, buyer_id, proposed_by, 
                     meeting_location_lat, meeting_location_lng, meeting_location_name,
                     created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (location_negotiation_id, listing_id, buyer_id, proposer_id, lat, lng, proposed_location))
            
            results['proposal_ids']['location'] = location_negotiation_id
            print(f"[ProposeMeeting] Location proposal created/updated: {location_negotiation_id}")
        
        connection.commit()
        print(f"[ProposeMeeting] Database commit successful")
        
        # Get proposer name for notification
        cursor.execute("SELECT FirstName, LastName FROM users WHERE UserId = %s", (proposer_id,))
        proposer = cursor.fetchone()
        proposer_name = f"{proposer['FirstName']} {proposer['LastName']}" if proposer else "A user"
        
        # Send APN notification to recipient
        try:
            from Admin.NotificationService import notification_service
            notification_service.send_meeting_proposal_notification(
                recipient_id=recipient_id,
                proposer_name=proposer_name,
                proposed_time='',
                listing_id=listing_id,
                proposal_id=results['proposal_ids'].get('time') or results['proposal_ids'].get('location')
            )
        except Exception as apn_error:
            print(f"[ProposeMeeting] Error sending APN notification: {apn_error}")
        
        connection.close()
        
        print(f"[ProposeMeeting] ===== END PROPOSAL =====")
        return json.dumps(results)
        
    except Exception as e:
        print(f"[ProposeMeeting] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to create meeting proposal: {str(e)}'
        })
