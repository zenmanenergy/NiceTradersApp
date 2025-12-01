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
        
        title = get_translation(seller_lang, 'PAYMENT_RECEIVED')
        currency_str = format_currency(amount, currency)
        contact_access_text = get_translation(seller_lang, 'listing_contact_access')
        body = f"{buyer_name} {contact_access_text} ({currency_str})"
        
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
        
        title = get_translation(recipient_lang, 'MEETING_PROPOSED')
        proposed_text = get_translation(recipient_lang, 'meeting_proposed_text')
        body = f"{proposer_name} {proposed_text} {proposed_time}"
        
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
        
        title = get_translation(recipient_lang, 'NEW_MESSAGE')
        message_from_text = get_translation(recipient_lang, 'message_from')
        body = f"{sender_name} {message_from_text} {message_preview[:50]}"
        
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
            status: New status (flagged, removed, expired, reactivated)
            reason: Optional reason for the change
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get seller's preferred language
        seller_lang = self.get_user_language(seller_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(seller_id)
        
        # Map status to translation keys
        status_key_map = {
            'flagged': 'listing_flagged',
            'removed': 'listing_removed',
            'expired': 'listing_expired',
            'reactivated': 'listing_reactivated'
        }
        
        translation_key = status_key_map.get(status, 'listing_flagged')
        title = get_translation(seller_lang, translation_key)
        body = reason if reason else f"Your listing #{listing_id[:8]}"
        
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
        # Get user's preferred language
        user_lang = self.get_user_language(user_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(user_id)
        
        title = get_translation(user_lang, 'RATING_RECEIVED')
        stars = "⭐" * rating
        body = f"{rater_name} gave you a {rating}-star rating {stars}"
        
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

    def send_listing_cancelled_notification(self, buyer_id, seller_name, listing_title):
        """
        Send notification when a listing is cancelled by the seller
        Args:
            buyer_id: ID of the buyer
            seller_name: Name of the seller
            listing_title: Title of the listing
        """
        # Get buyer's preferred language
        buyer_lang = self.get_user_language(buyer_id)
        
        # Get session ID for buyer
        session_id = self.get_user_session(buyer_id)
        
        # Get translation for title
        title = get_translation(buyer_lang, 'listing_cancelled')
        body = f"{seller_name}'s listing '{listing_title}' was cancelled"
        
        result = self.apn_service.send_notification(
            user_id=buyer_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='dashboard',
            deep_link_id=None
        )
        
        return result

    def send_exchange_completed_notification(self, user_id, partner_name):
        """
        Send notification when an exchange is completed by the other party
        Args:
            user_id: ID of the user being notified
            partner_name: Name of the partner who completed the exchange
        """
        # Get user's preferred language
        user_lang = self.get_user_language(user_id)
        
        # Get session ID for user
        session_id = self.get_user_session(user_id)
        
        # Get translation for title
        title = get_translation(user_lang, 'exchange_completed')
        body = f"{partner_name} has confirmed the exchange completion"
        
        result = self.apn_service.send_notification(
            user_id=user_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='dashboard',
            deep_link_id=None
        )
        
        return result


# Global instance
notification_service = NotificationService()

