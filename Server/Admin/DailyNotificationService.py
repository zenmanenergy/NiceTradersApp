"""
Daily Notification Service - Sends daily reminder notifications to users
Handles pending negotiations, unread messages, and other pending actions
"""
from _Lib.Database import ConnectToDatabase
from _Lib.i18n import get_translation
from Admin.NotificationService import notification_service
from datetime import datetime, timedelta
import json

class DailyNotificationService:
    """Service for sending daily reminder notifications"""
    
    def __init__(self):
        self.apn_service = notification_service.apn_service
    
    def send_pending_negotiations_reminder(self, user_id, pending_count):
        """
        Send daily reminder for pending negotiations if no action taken in 24 hours
        Args:
            user_id: ID of the user
            pending_count: Number of pending negotiations
        """
        if pending_count == 0:
            return {'success': False, 'message': 'No pending negotiations'}
        
        try:
            user_lang = notification_service.get_user_language(user_id)
            session_id = notification_service.get_user_session(user_id)
            
            title = get_translation(user_lang, 'PENDING_NEGOTIATIONS_REMINDER')
            body = f"You have {pending_count} pending negotiation(s) waiting for your response"
            
            result = self.apn_service.send_notification(
                user_id=user_id,
                title=title,
                body=body,
                badge=pending_count,
                sound='default',
                session_id=session_id,
                deep_link_type='dashboard',
                deep_link_id='negotiations'
            )
            
            # Log the daily reminder send
            self._log_daily_reminder(user_id, 'pending_negotiations', pending_count)
            return result
        except Exception as e:
            print(f"[DailyNotificationService] Error sending pending negotiations reminder: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def send_unread_messages_reminder(self, user_id, unread_count):
        """
        Send daily reminder for unread messages if no action taken in 24 hours
        Args:
            user_id: ID of the user
            unread_count: Number of unread messages
        """
        if unread_count == 0:
            return {'success': False, 'message': 'No unread messages'}
        
        try:
            user_lang = notification_service.get_user_language(user_id)
            session_id = notification_service.get_user_session(user_id)
            
            title = get_translation(user_lang, 'UNREAD_MESSAGES_REMINDER')
            body = f"You have {unread_count} unread message(s) waiting"
            
            result = self.apn_service.send_notification(
                user_id=user_id,
                title=title,
                body=body,
                badge=unread_count,
                sound='default',
                session_id=session_id,
                deep_link_type='messages',
                deep_link_id='unread'
            )
            
            # Log the daily reminder send
            self._log_daily_reminder(user_id, 'unread_messages', unread_count)
            return result
        except Exception as e:
            print(f"[DailyNotificationService] Error sending unread messages reminder: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def send_pending_approvals_reminder(self, user_id, pending_count):
        """
        Send daily reminder for pending location approvals if no action taken in 24 hours
        Args:
            user_id: ID of the seller
            pending_count: Number of pending location approvals
        """
        if pending_count == 0:
            return {'success': False, 'message': 'No pending approvals'}
        
        try:
            user_lang = notification_service.get_user_language(user_id)
            session_id = notification_service.get_user_session(user_id)
            
            title = get_translation(user_lang, 'PENDING_APPROVALS_REMINDER')
            body = f"You have {pending_count} pending location approval(s)"
            
            result = self.apn_service.send_notification(
                user_id=user_id,
                title=title,
                body=body,
                badge=pending_count,
                sound='default',
                session_id=session_id,
                deep_link_type='dashboard',
                deep_link_id='approvals'
            )
            
            # Log the daily reminder send
            self._log_daily_reminder(user_id, 'pending_approvals', pending_count)
            return result
        except Exception as e:
            print(f"[DailyNotificationService] Error sending pending approvals reminder: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def check_and_send_daily_reminders(self):
        """
        Main function to check all users and send appropriate daily reminders
        Should be called once per day by a scheduled task
        Returns:
            dict with statistics about reminders sent
        """
        cursor, connection = ConnectToDatabase()
        stats = {
            'pending_negotiations_sent': 0,
            'unread_messages_sent': 0,
            'pending_approvals_sent': 0,
            'total_sent': 0,
            'errors': []
        }
        
        try:
            # Get all active users
            cursor.execute("""
                SELECT DISTINCT user_id FROM users WHERE IsActive = 1
            """)
            users = cursor.fetchall()
            
            for user in users:
                user_id = user['user_id']
                
                try:
                    # Check for pending negotiations (unanswered time/location proposals)
                    cursor.execute("""
                        SELECT COUNT(*) as pending_count FROM listing_meeting_time
                        WHERE (buyer_id = %s OR proposed_by = %s)
                        AND accepted_at IS NULL
                        AND rejected_at IS NULL
                        AND updated_at < DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    """, (user_id, user_id))
                    result = cursor.fetchone()
                    pending_negotiations = result['pending_count'] if result else 0
                    
                    if pending_negotiations > 0:
                        self.send_pending_negotiations_reminder(user_id, pending_negotiations)
                        stats['pending_negotiations_sent'] += 1
                        stats['total_sent'] += 1
                    
                    # Check for unread messages
                    cursor.execute("""
                        SELECT COUNT(*) as unread_count FROM messages
                        WHERE recipient_id = %s
                        AND status = 'sent'
                        AND sent_at < DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    """, (user_id,))
                    result = cursor.fetchone()
                    unread_messages = result['unread_count'] if result else 0
                    
                    if unread_messages > 0:
                        self.send_unread_messages_reminder(user_id, unread_messages)
                        stats['unread_messages_sent'] += 1
                        stats['total_sent'] += 1
                    
                    # Check for pending location approvals (for sellers)
                    cursor.execute("""
                        SELECT COUNT(*) as pending_count FROM listing_meeting_location
                        WHERE proposed_by != %s
                        AND (buyer_id = %s OR listing_id IN (
                            SELECT listing_id FROM listings WHERE user_id = %s
                        ))
                        AND accepted_at IS NULL
                        AND rejected_at IS NULL
                        AND updated_at < DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    """, (user_id, user_id, user_id))
                    result = cursor.fetchone()
                    pending_approvals = result['pending_count'] if result else 0
                    
                    if pending_approvals > 0:
                        self.send_pending_approvals_reminder(user_id, pending_approvals)
                        stats['pending_approvals_sent'] += 1
                        stats['total_sent'] += 1
                
                except Exception as user_error:
                    stats['errors'].append(f"Error processing user {user_id}: {str(user_error)}")
                    print(f"[DailyNotificationService] Error processing user {user_id}: {str(user_error)}")
        
        except Exception as e:
            stats['errors'].append(f"Fatal error: {str(e)}")
            print(f"[DailyNotificationService] Fatal error: {str(e)}")
        
        finally:
            cursor.close()
            connection.close()
        
        return stats
    
    def _log_daily_reminder(self, user_id, reminder_type, count):
        """Log that a daily reminder was sent"""
        try:
            cursor, connection = ConnectToDatabase()
            cursor.execute("""
                INSERT INTO daily_notification_log (user_id, reminder_type, count, sent_at)
                VALUES (%s, %s, %s, NOW())
            """, (user_id, reminder_type, count))
            connection.commit()
            cursor.close()
            connection.close()
        except Exception as e:
            print(f"[DailyNotificationService] Failed to log reminder: {str(e)}")


# Global instance
daily_notification_service = DailyNotificationService()
