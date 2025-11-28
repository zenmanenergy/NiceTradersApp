"""
Notification Service - Centralized module for triggering APN and other notifications
"""
from APNService.APNService import APNService
from _Lib.Database import ConnectToDatabase
from _Lib.i18n import get_translation, format_currency, format_datetime

class NotificationService:
    """Service for managing all types of notifications"""
    
    def __init__(self):
        self.apn_service = APNService()
    
    def send_payment_received_notification(self, seller_id, buyer_name, amount, currency, listing_id, session_id=None):
        """
        Send notification when a buyer has paid for contact access
        Args:
            seller_id: ID of the seller
            buyer_name: Name of the buyer
            amount: Amount paid
            currency: Currency of payment
            listing_id: ID of the listing
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get seller's preferred language
        seller_lang = self.get_user_language(seller_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(seller_id)
        
        title = get_translation(seller_lang, 'payment_received')
        currency_str = format_currency(amount, currency)
        body = f"{buyer_name} {get_translation(seller_lang, 'listing_contact_access')} ({currency_str})"
        
        result = self.apn_service.send_notification(
            user_id=seller_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='listing',
            deep_link_id=listing_id
        )
        
        return result
    
    def send_meeting_proposal_notification(self, recipient_id, proposer_name, proposed_time, 
                                          listing_id, proposal_id, session_id=None):
        """
        Send notification when a meeting is proposed
        Args:
            recipient_id: ID of the user receiving the proposal
            proposer_name: Name of the user proposing the meeting
            proposed_time: Time of the proposed meeting (formatted string)
            listing_id: ID of the listing
            proposal_id: ID of the proposal
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get recipient's preferred language
        recipient_lang = self.get_user_language(recipient_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(recipient_id)
        
        title = get_translation(recipient_lang, 'meeting_proposed')
        body = f"{proposer_name} {get_translation(recipient_lang, 'meeting_proposed_text')} {proposed_time}"
        
        result = self.apn_service.send_notification(
            user_id=recipient_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='meeting',
            deep_link_id=proposal_id
        )
        
        return result
    
    def send_message_received_notification(self, recipient_id, sender_name, message_preview, 
                                          listing_id, message_id, session_id=None):
        """
        Send notification when a message is received
        Args:
            recipient_id: ID of the recipient
            sender_name: Name of the sender
            message_preview: First 50 chars of message
            listing_id: ID of the listing
            message_id: ID of the message
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get recipient's preferred language
        recipient_lang = self.get_user_language(recipient_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(recipient_id)
        
        title = get_translation(recipient_lang, 'new_message')
        body = f"{sender_name} {get_translation(recipient_lang, 'message_from')}: {message_preview[:50]}"
        
        result = self.apn_service.send_notification(
            user_id=recipient_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='message',
            deep_link_id=message_id
        )
        
        return result
    
    def send_listing_status_notification(self, seller_id, listing_id, status, reason=None, session_id=None):
        """
        Send notification when listing status changes (flagged, removed, etc.)
        Args:
            seller_id: ID of the seller
            listing_id: ID of the listing
            status: New status (flagged, removed, expired, etc.)
            reason: Optional reason for the change
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(seller_id)
        
        status_messages = {
            'flagged': '🚩 Your listing has been flagged for review',
            'removed': '❌ Your listing has been removed',
            'expired': '⏰ Your listing has expired',
            'reactivated': '✅ Your listing is active again'
        }
        
        title = status_messages.get(status, f"Listing Status: {status}")
        body = reason if reason else f"Your listing #{listing_id[:8]} {status}"
        
        result = self.apn_service.send_notification(
            user_id=seller_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='listing',
            deep_link_id=listing_id
        )
        
        return result
    
    def send_rating_received_notification(self, user_id, rater_name, rating, listing_id, session_id=None):
        """
        Send notification when user receives a rating
        Args:
            user_id: ID of the rated user
            rater_name: Name of the user giving the rating
            rating: Rating value (1-5)
            listing_id: Related listing ID
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(user_id)
        
        stars = "⭐" * rating
        title = f"You got a rating! {stars}"
        body = f"{rater_name} gave you a {rating}-star rating"
        
        result = self.apn_service.send_notification(
            user_id=user_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='listing',
            deep_link_id=listing_id
        )
        
        return result
    
    def get_user_language(self, user_id):
        """
        Get the user's preferred language
        Args:
            user_id: ID of the user
        
        Returns:
            language code (default 'en')
        """
        try:
            cursor, connection = ConnectToDatabase()
            cursor.execute(
                "SELECT SettingsJson FROM user_settings WHERE UserId = %s",
                (user_id,)
            )
            result = cursor.fetchone()
            cursor.close()
            connection.close()
            
            if result and result.get('SettingsJson'):
                import json
                settings = json.loads(result['SettingsJson'])
                return settings.get('language', 'en')
            return 'en'
        except Exception as e:
            print(f"Error getting user language: {e}")
            return 'en'
    
    def get_user_session(self, user_id):
        """
        Get the user's last session ID for auto-login
        Args:
            user_id: ID of the user
        
        Returns:
            session ID or None if not found
        """
        try:
            cursor, connection = ConnectToDatabase()
            cursor.execute(
                "SELECT SessionId FROM usersessions WHERE UserId = %s ORDER BY DateAdded DESC LIMIT 1",
                (user_id,)
            )
            result = cursor.fetchone()
            cursor.close()
            connection.close()
            
            if result:
                return result['SessionId']
            return None
        except Exception as e:
            print(f"Error getting user session: {e}")
            return None
    
    def send_negotiation_proposal_notification(self, seller_id, buyer_name, proposed_time, 
                                               listing_id, negotiation_id, session_id=None):
        """
        Send notification when a buyer proposes a negotiation
        Args:
            seller_id: ID of the seller receiving the proposal
            buyer_name: Name of the buyer
            proposed_time: Proposed meeting time (ISO format)
            listing_id: ID of the listing
            negotiation_id: ID of the negotiation
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get seller's preferred language
        seller_lang = self.get_user_language(seller_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(seller_id)
        
        # Format the time nicely
        try:
            from datetime import datetime
            dt = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
            formatted_time = dt.strftime('%b %d at %I:%M %p')
        except:
            formatted_time = proposed_time
        
        title = get_translation(seller_lang, 'NEGOTIATION_PROPOSAL')
        body = f"{buyer_name} wants to meet on {formatted_time}"
        
        result = self.apn_service.send_notification(
            user_id=seller_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='negotiation',
            deep_link_id=negotiation_id
        )
        
        return result


# Global instance
notification_service = NotificationService()
