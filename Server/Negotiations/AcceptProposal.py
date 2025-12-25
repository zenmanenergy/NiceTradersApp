import json
import uuid
from datetime import datetime, timedelta
from _Lib import Database

def accept_proposal(listing_id, session_id):
    """
    Accept the current time proposal
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
    
    Returns:
        JSON response with updated negotiation status
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get time negotiation for this listing
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, meeting_time, accepted_at, rejected_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'No time proposal found for this listing'
            })
        
        # Check if already accepted or rejected
        if time_neg['accepted_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This time proposal has already been accepted'
            })
        
        if time_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This time proposal has been rejected'
            })
        
        # Get listing to verify user is part of negotiation
        cursor.execute("""
            SELECT user_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Verify user is part of this negotiation (buyer or seller)
        if user_id != seller_id and user_id != time_neg['buyer_id']:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Accept the time proposal
        cursor.execute("""
            UPDATE listing_meeting_time
            SET accepted_at = NOW(), updated_at = NOW()
            WHERE listing_id = %s
        """, (listing_id,))
        
        # Set buyer_id in listings table (mark buyer as winner)
        cursor.execute("""
            UPDATE listings
            SET buyer_id = %s
            WHERE listing_id = %s
        """, (time_neg['buyer_id'], listing_id))
        
        connection.commit()
        
        agreement_time = datetime.now()
        
        print(f"[Negotiations] AcceptProposal success: listing_id={listing_id}, user_id={user_id}")
        
        # Send APN notification to buyer
        try:
            from Admin.NotificationService import notification_service
            
            # Get acceptor name for notification
            cursor.execute("SELECT FirstName, LastName FROM users WHERE user_id = %s", (user_id,))
            acceptor = cursor.fetchone()
            acceptor_name = f"{acceptor['FirstName']} {acceptor['LastName']}" if acceptor else "A user"
            
            # Determine who is the buyer/seller for notification
            if user_id == seller_id:
                # Seller accepted, notify buyer
                notification_service.send_meeting_proposal_notification(
                    recipient_id=time_neg['buyer_id'],
                    proposer_name=acceptor_name,
                    proposed_time=str(time_neg['meeting_time']),
                    listing_id=listing_id,
                    proposal_id=time_neg['time_negotiation_id']
                )
            else:
                # Buyer accepted, notify seller
                notification_service.send_meeting_proposal_notification(
                    recipient_id=seller_id,
                    proposer_name=acceptor_name,
                    proposed_time=str(time_neg['meeting_time']),
                    listing_id=listing_id,
                    proposal_id=time_neg['time_negotiation_id']
                )
            print(f"[Negotiations] Sent APN notification for accepted proposal")
        except Exception as notif_error:
            print(f"[Negotiations] Failed to send notification: {str(notif_error)}")
        
        return json.dumps({
            'success': True,
            'status': 'agreed',
            'agreementReachedAt': agreement_time.isoformat(),
            'message': 'Meeting time accepted. Location negotiation phase begins.'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] AcceptProposal error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to accept proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
