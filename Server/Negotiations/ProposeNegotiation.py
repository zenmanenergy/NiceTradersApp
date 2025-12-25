import json
import uuid
from datetime import datetime
from _Lib import Database
from Admin.NotificationService import notification_service

def propose_negotiation(listing_id, session_id, proposed_time):
    """
    Buyer proposes initial meeting time for a listing
    
    Args:
        listing_id: ID of the listing to negotiate
        session_id: Buyer's session ID
        proposed_time: Proposed meeting time (ISO 8601 format)
    
    Returns:
        JSON response with negotiation details
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        print(f"[Negotiations] ProposeNegotiation called with listing_id={listing_id}, session_id={session_id}, proposed_time={proposed_time}")
        
        # Verify session and get buyer user_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        print(f"[Negotiations] Session lookup result: {session_result}")
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        buyer_id = session_result['user_id']
        print(f"[Negotiations] Buyer ID: {buyer_id}")
        
        # Get listing details and verify it exists
        cursor.execute("""
            SELECT user_id, status, available_until
            FROM listings
            WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Prevent buyer from negotiating on their own listing
        if buyer_id == seller_id:
            return json.dumps({
                'success': False,
                'error': 'You cannot negotiate on your own listing'
            })
        
        # Check if listing is active
        if listing['status'] != 'active':
            return json.dumps({
                'success': False,
                'error': 'Listing is not active'
            })
        
        # Check if listing already has an active time proposal (UNIQUE constraint)
        cursor.execute("""
            SELECT time_negotiation_id, accepted_at, rejected_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        existing_time_neg = cursor.fetchone()
        
        if existing_time_neg:
            # If time negotiation exists and is not rejected, another proposal is in progress
            if existing_time_neg['rejected_at'] is None:
                return json.dumps({
                    'success': False,
                    'error': 'An active time proposal already exists for this listing'
                })
            # If rejected, we allow a new proposal (clean slate)
        
        # Parse and validate proposed time
        try:
            proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
        except ValueError:
            return json.dumps({
                'success': False,
                'error': 'Invalid date format. Use ISO 8601 format'
            })
        
        # Check if proposed time is in the future
        if proposed_datetime <= datetime.now(proposed_datetime.tzinfo):
            return json.dumps({
                'success': False,
                'error': 'Proposed time must be in the future'
            })
        
        # Create a unique time_negotiation_id
        time_negotiation_id = str(uuid.uuid4())
        
        # Delete old rejected record if exists (clean slate for re-proposal)
        if existing_time_neg and existing_time_neg['rejected_at'] is not None:
            cursor.execute("""
                DELETE FROM listing_meeting_time
                WHERE listing_id = %s
            """, (listing_id,))
        
        # Create new time proposal in listing_meeting_time
        cursor.execute("""
            INSERT INTO listing_meeting_time (
                time_negotiation_id, listing_id, buyer_id, proposed_by, meeting_time, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
        """, (time_negotiation_id, listing_id, buyer_id, buyer_id, proposed_datetime))
        
        connection.commit()
        print(f"[Negotiations] Created time proposal: {time_negotiation_id}")
        
        # Get buyer's name for notification
        cursor.execute("""
            SELECT FirstName, LastName
            FROM users
            WHERE user_id = %s
        """, (buyer_id,))
        buyer = cursor.fetchone()
        buyer_name = f"{buyer['FirstName']} {buyer['LastName']}" if buyer else "A buyer"
        
        # Send APN notification to seller
        try:
            notification_service.send_negotiation_proposal_notification(
                seller_id=seller_id,
                buyer_name=buyer_name,
                proposed_time=proposed_time,
                listing_id=listing_id,
                negotiation_id=time_negotiation_id
                # session_id is automatically fetched inside notification_service
            )
            print(f"[Negotiations] Sent APN notification to seller {seller_id}")
        except Exception as notif_error:
            print(f"[Negotiations] Failed to send notification: {str(notif_error)}")
            # Don't fail the negotiation if notification fails
        
        return json.dumps({
            'success': True,
            'negotiationId': time_negotiation_id,
            'status': 'proposed',
            'proposedTime': proposed_time,
            'message': 'Time proposal sent successfully'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] ProposeNegotiation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': f'Failed to create time proposal: {str(e)}'
        })
    
    finally:
        cursor.close()
        connection.close()
