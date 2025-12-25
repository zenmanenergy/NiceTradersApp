from _Lib import Database
import json
from datetime import datetime
import uuid

def report_listing(listing_id, session_id, reason, description=''):
    """Report a listing for inappropriate content or behavior"""
    try:
        print(f"[ReportListing] Reporting listing {listing_id} for reason: {reason}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # First, get user_id from session_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Check if listing exists
        cursor.execute("SELECT user_id, status FROM listings WHERE listing_id = %s", (listing_id,))
        listing_result = cursor.fetchone()
        
        if not listing_result:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        listing_owner_id = listing_result['user_id']
        
        # Check if user is trying to report their own listing
        if listing_owner_id == user_id:
            return json.dumps({
                'success': False,
                'error': 'Cannot report your own listing'
            })
        
        # Check if user has already reported this listing
        cursor.execute("""
            SELECT report_id FROM listing_reports 
            WHERE listing_id = %s AND reporter_id = %s AND status != 'resolved'
        """, (listing_id, user_id))
        
        existing_report = cursor.fetchone()
        if existing_report:
            return json.dumps({
                'success': False,
                'error': 'You have already reported this listing'
            })
        
        # Validate report reason
        valid_reasons = [
            'spam', 'fraud', 'inappropriate_content', 'fake_listing',
            'abusive_behavior', 'misleading_information', 'other'
        ]
        
        if reason not in valid_reasons:
            return json.dumps({
                'success': False,
                'error': 'Invalid report reason'
            })
        
        # Create the report
        report_id = str(uuid.uuid4())
        created_at = datetime.now()
        
        report_query = """
            INSERT INTO listing_reports (
                report_id, listing_id, reporter_id, reported_user_id,
                reason, description, status, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.execute(report_query, (
            report_id, listing_id, user_id, listing_owner_id,
            reason, description, 'pending', created_at
        ))
        
        # Update listing report count
        cursor.execute("""
            UPDATE listings 
            SET report_count = COALESCE(report_count, 0) + 1,
                last_reported_at = %s
            WHERE listing_id = %s
        """, (created_at, listing_id))
        
        # Check if listing should be automatically flagged for review
        cursor.execute("SELECT report_count FROM listings WHERE listing_id = %s", (listing_id,))
        report_count_result = cursor.fetchone()
        report_count = report_count_result['report_count'] if report_count_result else 0
        
        # Auto-flag for admin review if multiple reports
        if report_count >= 3:
            cursor.execute("""
                UPDATE listings 
                SET status = 'under_review', 
                    flagged_at = %s,
                    flagged_reason = 'Multiple reports received'
                WHERE listing_id = %s
            """, (created_at, listing_id))
        
        # Create notification for admins
        admin_notification_id = str(uuid.uuid4())
        admin_notification_query = """
            INSERT INTO admin_notifications (
                notification_id, type, priority, title, message,
                related_id, status, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        priority = 'high' if report_count >= 3 else 'medium'
        title = f"Listing Reported: {reason.replace('_', ' ').title()}"
        message = f"Listing {listing_id} reported for {reason}. Total reports: {report_count}"
        
        cursor.execute(admin_notification_query, (
            admin_notification_id, 'listing_report', priority, title,
            message, listing_id, 'unread', created_at
        ))
        
        # Commit the transaction
        connection.commit()
        
        # Send notification to seller that their listing was reported
        try:
            from Admin.NotificationService import notification_service
            notification_service.send_listing_reported_notification(
                seller_id=listing_owner_id,
                listing_id=listing_id,
                reason=reason
            )
            print(f"[ReportListing] Sent notification to seller {listing_owner_id}")
        except Exception as notif_error:
            print(f"[ReportListing] Warning: Failed to send notification: {str(notif_error)}")
        
        response_data = {
            'success': True,
            'message': 'Report submitted successfully',
            'report_details': {
                'report_id': report_id,
                'submitted_at': created_at.isoformat(),
                'reason': reason,
                'status': 'pending'
            }
        }
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps(response_data)
        
    except Exception as e:
        print(f"[ReportListing] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to submit report'
        })