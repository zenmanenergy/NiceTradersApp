from _Lib import Database
import json
import uuid
from datetime import datetime, timedelta

def propose_meeting(session_id, listing_id, proposed_location, proposed_time, proposed_latitude=None, proposed_longitude=None, message=None):
    """Propose a meeting time and/or location for an exchange (using new normalized tables)"""
    try:
        print(f"\n🟠 [ProposeMeeting] ===== START PROPOSAL =====")
        print(f"🟠 [ProposeMeeting] Input params:")
        print(f"  session_id: {session_id}")
        print(f"  listing_id: {listing_id}")
        print(f"  proposed_location: {proposed_location}")
        print(f"  proposed_time: {proposed_time}")
        print(f"  proposed_latitude: {proposed_latitude}")
        print(f"  proposed_longitude: {proposed_longitude}")
        
        # Either location or time must be provided
        if not session_id or not listing_id or (not proposed_location and not proposed_time):
            print(f"🔴 [ProposeMeeting] ERROR: Missing required parameters")
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
            print(f"🔴 [ProposeMeeting] ERROR: Invalid session")
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        proposer_id = session_result['user_id']
        print(f"🟠 [ProposeMeeting] Session verified - proposer_id: {proposer_id}")
        
        # Get listing info and determine recipient
        listing_query = """
            SELECT l.user_id as listing_owner_id, l.buyer_id
            FROM listings l
            WHERE l.listing_id = %s
        """
        cursor.execute(listing_query, (listing_id,))
        listing_result = cursor.fetchone()
        
        if not listing_result:
            print(f"🔴 [ProposeMeeting] ERROR: Listing not found: {listing_id}")
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        listing_owner_id = listing_result['listing_owner_id']
        buyer_id = listing_result['buyer_id']
        print(f"🟠 [ProposeMeeting] Listing info - owner: {listing_owner_id}, buyer: {buyer_id}")
        
        # Determine recipient and validate access
        if proposer_id == listing_owner_id:
            # Listing owner is proposing - must have a buyer
            if not buyer_id:
                print(f"🔴 [ProposeMeeting] ERROR: No buyer set for this listing")
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'No buyer has been set for this listing yet'
                })
            recipient_id = buyer_id
            print(f"🟠 [ProposeMeeting] Proposer is owner, recipient is buyer: {recipient_id}")
        else:
            # Buyer is proposing
            if proposer_id != buyer_id:
                print(f"🔴 [ProposeMeeting] ERROR: Proposer {proposer_id} is not buyer {buyer_id}")
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'You are not the buyer for this listing'
                })
            recipient_id = listing_owner_id
            print(f"🟠 [ProposeMeeting] Proposer is buyer, recipient is owner: {recipient_id}")
        
        results = {
            'success': True,
            'proposal_ids': {},
            'message': 'Meeting proposal created'
        }
        
        # Handle TIME proposal
        if proposed_time:
            print(f"🟠 [ProposeMeeting] Processing TIME proposal: {proposed_time}")
            try:
                proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
            except:
                try:
                    proposed_datetime = datetime.strptime(proposed_time, '%Y-%m-%d %H:%M:%S')
                except Exception as parse_error:
                    print(f"🔴 [ProposeMeeting] ERROR: Invalid time format - {parse_error}")
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
                print(f"🟠 [ProposeMeeting] Updating existing time negotiation: {existing['time_negotiation_id']}")
                # Only clear accepted_at if the time has actually changed
                cursor.execute("""
                    SELECT meeting_time, accepted_at FROM listing_meeting_time
                    WHERE listing_id = %s
                """, (listing_id,))
                current = cursor.fetchone()
                
                # Check if time changed
                time_changed = current and current['meeting_time'] != proposed_datetime
                
                if time_changed:
                    # Time changed, so reset acceptance
                    cursor.execute("""
                        UPDATE listing_meeting_time 
                        SET meeting_time = %s, proposed_by = %s, accepted_at = NULL, rejected_at = NULL, updated_at = NOW()
                        WHERE listing_id = %s
                    """, (proposed_datetime, proposer_id, listing_id))
                else:
                    # Time is the same, keep acceptance
                    cursor.execute("""
                        UPDATE listing_meeting_time 
                        SET meeting_time = %s, proposed_by = %s, rejected_at = NULL, updated_at = NOW()
                        WHERE listing_id = %s
                    """, (proposed_datetime, proposer_id, listing_id))
                results['proposal_ids']['time'] = existing['time_negotiation_id']
            else:
                # Create new time negotiation
                print(f"🟠 [ProposeMeeting] Creating new time negotiation: {time_negotiation_id}")
                cursor.execute("""
                    INSERT INTO listing_meeting_time
                    (time_negotiation_id, listing_id, buyer_id, proposed_by, meeting_time, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
                """, (time_negotiation_id, listing_id, buyer_id, proposer_id, proposed_datetime))
                results['proposal_ids']['time'] = time_negotiation_id
            
            print(f"✅ [ProposeMeeting] Time proposal saved: {results['proposal_ids']['time']}")
        
        # Handle LOCATION proposal
        if proposed_location and proposed_latitude is not None and proposed_longitude is not None:
            print(f"🟠 [ProposeMeeting] Processing LOCATION proposal: {proposed_location} ({proposed_latitude}, {proposed_longitude})")
            try:
                lat = float(proposed_latitude)
                lng = float(proposed_longitude)
                
                # Validate coordinates
                if lat < -90 or lat > 90 or lng < -180 or lng > 180:
                    print(f"🔴 [ProposeMeeting] ERROR: Invalid coordinates")
                    connection.close()
                    return json.dumps({
                        'success': False,
                        'error': 'Invalid coordinates'
                    })
            except Exception as coord_error:
                print(f"🔴 [ProposeMeeting] ERROR: Coordinate parse error - {coord_error}")
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
                print(f"🟠 [ProposeMeeting] Updating existing location negotiation: {existing['location_negotiation_id']}")
                # Only clear accepted_at if the location has actually changed
                cursor.execute("""
                    SELECT meeting_location_lat, meeting_location_lng, accepted_at FROM listing_meeting_location
                    WHERE listing_id = %s
                """, (listing_id,))
                current = cursor.fetchone()
                
                # Check if location changed (compare coordinates)
                location_changed = current and (current['meeting_location_lat'] != lat or current['meeting_location_lng'] != lng)
                
                if location_changed:
                    # Location changed, so reset acceptance
                    cursor.execute("""
                        UPDATE listing_meeting_location 
                        SET meeting_location_lat = %s, 
                            meeting_location_lng = %s,
                            meeting_location_name = %s,
                            proposed_by = %s,
                            accepted_at = NULL,
                            rejected_at = NULL,
                            updated_at = NOW()
                        WHERE listing_id = %s
                    """, (lat, lng, proposed_location, proposer_id, listing_id))
                else:
                    # Location is the same, keep acceptance
                    cursor.execute("""
                        UPDATE listing_meeting_location 
                        SET meeting_location_lat = %s, 
                            meeting_location_lng = %s,
                            meeting_location_name = %s,
                            proposed_by = %s,
                            rejected_at = NULL,
                            updated_at = NOW()
                        WHERE listing_id = %s
                    """, (lat, lng, proposed_location, proposer_id, listing_id))
                results['proposal_ids']['location'] = existing['location_negotiation_id']
            else:
                # Create new location negotiation
                print(f"🟠 [ProposeMeeting] Creating new location negotiation: {location_negotiation_id}")
                cursor.execute("""
                    INSERT INTO listing_meeting_location
                    (location_negotiation_id, listing_id, buyer_id, proposed_by, 
                     meeting_location_lat, meeting_location_lng, meeting_location_name,
                     created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (location_negotiation_id, listing_id, buyer_id, proposer_id, lat, lng, proposed_location))
                results['proposal_ids']['location'] = location_negotiation_id
            
            print(f"✅ [ProposeMeeting] Location proposal saved: {results['proposal_ids']['location']}")
        
        connection.commit()
        print(f"✅ [ProposeMeeting] Database commit successful")
        print(f"✅ [ProposeMeeting] Results: {results}")
        
        # Get proposer name for notification
        cursor.execute("SELECT FirstName, LastName FROM users WHERE user_id = %s", (proposer_id,))
        proposer = cursor.fetchone()
        proposer_name = f"{proposer['FirstName']} {proposer['LastName']}" if proposer else "A user"
        print(f"🟠 [ProposeMeeting] Sending notification to user {recipient_id} from {proposer_name}")
        
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
            print(f"✅ [ProposeMeeting] APN notification sent successfully")
        except Exception as apn_error:
            print(f"🔴 [ProposeMeeting] APN error: {apn_error}")
        
        connection.close()
        
        print(f"✅ [ProposeMeeting] ===== END PROPOSAL =====\n")
        return json.dumps(results)
        
    except Exception as e:
        print(f"🔴 [ProposeMeeting] ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return json.dumps({
            'success': False,
            'error': f'Failed to create meeting proposal: {str(e)}'
        })
