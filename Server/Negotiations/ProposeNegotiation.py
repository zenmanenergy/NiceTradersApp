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
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        print(f"[Negotiations] Session lookup result: {session_result}")
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        buyer_id = session_result['UserId']
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
        
        # Check if buyer already has an active time proposal for this listing
        cursor.execute("""
            SELECT DISTINCT negotiation_id FROM negotiation_history
            WHERE listing_id = %s 
            AND action IN ('time_proposal', 'accepted_time')
            AND proposed_by = %s
            LIMIT 1
        """, (listing_id, buyer_id))
        
        existing_proposal = cursor.fetchone()
        
        if existing_proposal:
            return json.dumps({
                'success': False,
                'error': 'You already have an active time proposal for this listing'
            })
        
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
        
        # Create a unique negotiation_id for this time proposal
        negotiation_id = str(uuid.uuid4())
        
        # Create initial time proposal in negotiation_history
        history_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, listing_id, action, proposed_time, proposed_by, created_at
            ) VALUES (%s, %s, %s, 'time_proposal', %s, %s, NOW())
        """, (history_id, negotiation_id, listing_id, proposed_datetime, buyer_id))
        
        connection.commit()
        print(f"[Negotiations] Created time proposal: {history_id} with negotiation_id: {negotiation_id}")
        
        # Get buyer's name for notification
        cursor.execute("""
            SELECT FirstName, LastName
            FROM users
            WHERE UserId = %s
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
                negotiation_id=negotiation_id
                # session_id is automatically fetched inside notification_service
            )
            print(f"[Negotiations] Sent APN notification to seller {seller_id}")
        except Exception as notif_error:
            print(f"[Negotiations] Failed to send notification: {str(notif_error)}")
            # Don't fail the negotiation if notification fails
        
        return json.dumps({
            'success': True,
            'negotiationId': negotiation_id,
            'status': 'proposed',
            'proposedTime': proposed_time,
            'message': 'Time proposal sent successfully'
        })
        
    except Exception as e:
        connection.rollback()
        print(f"[Negotiations] ProposeNegotiation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': f'Failed to create negotiation proposal: {str(e)}'
        })
    
    finally:
        cursor.close()
        connection.close()
