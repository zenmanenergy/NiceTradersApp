"""
Notification Service - Centralized module for triggering APN and other notifications
"""
from APNService.APNService import APNService
from _Lib.Database import ConnectToDatabase
from _Lib.i18n import get_translation, format_currency, format_datetime
import os

# Initialize APN Service with credentials (same as Admin.py)
APN_KEY_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'AuthKey_LST3TZH33S.p8')
APN_KEY_ID = 'LST3TZH33S'
APN_TEAM_ID = 'J7S264TV3T'
APN_TOPIC = 'NiceTraders.Nice-Traders'

class NotificationService:
    """Service for managing all types of notifications"""
    
    def __init__(self):
        self.apn_service = APNService(
            certificate_path=APN_KEY_PATH,
            key_id=APN_KEY_ID,
            team_id=APN_TEAM_ID,
            topic=APN_TOPIC
        )
    
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
        
        title = self.get_translation_from_db(seller_lang, 'PAYMENT_RECEIVED')
        currency_str = format_currency(amount, currency)
        body = f"{buyer_name} {self.get_translation_from_db(seller_lang, 'has_paid_negotiation_fee')} ({currency_str})"
        
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
        Send notification when a meeting time proposal is accepted/confirmed
        Args:
            recipient_id: ID of the user receiving the confirmation
            proposer_name: Name of the user who accepted the meeting time
            proposed_time: Time of the meeting
            listing_id: ID of the listing
            proposal_id: ID of the proposal
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get recipient's preferred language
        recipient_lang = self.get_user_language(recipient_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(recipient_id)
        
        # Format the time nicely
        try:
            from datetime import datetime
            dt = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
            time_str = dt.strftime('%b %d at %I:%M %p')
            # Remove leading zero from hour (02:30 PM -> 2:30 PM)
            parts = time_str.split(' at ')
            date_part = parts[0]
            time_part = parts[1]
            hour, rest = time_part.split(':', 1)
            hour = str(int(hour))
            formatted_time = f"{date_part} at {hour}:{rest}"
        except:
            formatted_time = proposed_time
        
        title = self.get_translation_from_db(recipient_lang, 'MEETING_ACCEPTED')
        accepted_text = self.get_translation_from_db(recipient_lang, 'meeting_time_accepted')
        body = f"{proposer_name} {accepted_text} {formatted_time}"
        
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
    
    def send_meeting_counter_proposal_notification(self, recipient_id, proposer_name, counter_time, 
                                                   listing_id, proposal_id, session_id=None):
        """
        Send notification when a counter-time proposal is made (neither party has accepted yet)
        Args:
            recipient_id: ID of the user receiving the counter-proposal
            proposer_name: Name of the user proposing the counter-time
            counter_time: The newly proposed meeting time
            listing_id: ID of the listing
            proposal_id: ID of the counter-proposal
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        # Get recipient's preferred language
        recipient_lang = self.get_user_language(recipient_id)
        
        # Get session ID if not provided
        if not session_id:
            session_id = self.get_user_session(recipient_id)
        
        # Format the time nicely
        try:
            from datetime import datetime
            dt = datetime.fromisoformat(counter_time.replace('Z', '+00:00'))
            time_str = dt.strftime('%b %d at %I:%M %p')
            # Remove leading zero from hour (02:30 PM -> 2:30 PM)
            parts = time_str.split(' at ')
            date_part = parts[0]
            time_part = parts[1]
            hour, rest = time_part.split(':', 1)
            hour = str(int(hour))
            formatted_time = f"{date_part} at {hour}:{rest}"
        except:
            formatted_time = counter_time
        
        title = self.get_translation_from_db(recipient_lang, 'MEETING_COUNTER_PROPOSAL')
        counter_text = self.get_translation_from_db(recipient_lang, 'meeting_counter_proposal_text')
        body = f"{proposer_name} {counter_text} {formatted_time}"
        
        result = self.apn_service.send_notification(
            user_id=recipient_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='negotiation',
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
        
        title = self.get_translation_from_db(recipient_lang, 'NEW_MESSAGE')
        message_from_text = self.get_translation_from_db(recipient_lang, 'message_from')
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
        title = self.get_translation_from_db(seller_lang, translation_key)
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
        
        title = self.get_translation_from_db(user_lang, 'RATING_RECEIVED')
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
            # Get language from users table (PreferredLanguage column)
            cursor.execute(
                "SELECT PreferredLanguage FROM users WHERE user_id = %s",
                (user_id,)
            )
            result = cursor.fetchone()
            cursor.close()
            connection.close()
            
            if result and result.get('PreferredLanguage'):
                return result['PreferredLanguage']
            return 'en'
        except Exception as e:
            print(f"Error getting user language: {e}")
            return 'en'
    
    def get_translation_from_db(self, language_code, translation_key):
        """
        Get translation from database
        Args:
            language_code: Language code (e.g., 'en', 'es')
            translation_key: Translation key
        
        Returns:
            Translated string or the key itself as fallback
        """
        try:
            cursor, connection = ConnectToDatabase()
            cursor.execute(
                "SELECT translation_value FROM translations WHERE translation_key = %s AND language_code = %s",
                (translation_key, language_code)
            )
            result = cursor.fetchone()
            cursor.close()
            connection.close()
            
            if result:
                return result.get('translation_value', translation_key)
            
            # Fallback to English if translation not found
            if language_code != 'en':
                cursor, connection = ConnectToDatabase()
                cursor.execute(
                    "SELECT translation_value FROM translations WHERE translation_key = %s AND language_code = 'en'",
                    (translation_key,)
                )
                result = cursor.fetchone()
                cursor.close()
                connection.close()
                
                if result:
                    return result.get('translation_value', translation_key)
            
            # Last resort: return the key itself
            return translation_key
        except Exception as e:
            print(f"Error getting translation from database: {e}")
            return translation_key
    
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
                "SELECT session_id FROM user_sessions WHERE user_id = %s ORDER BY DateAdded DESC LIMIT 1",
                (user_id,)
            )
            result = cursor.fetchone()
            cursor.close()
            connection.close()
            
            if result:
                return result.get('session_id')
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
            time_str = dt.strftime('%b %d at %I:%M %p')
            # Remove leading zero from hour (02:30 PM -> 2:30 PM)
            parts = time_str.split(' at ')
            date_part = parts[0]
            time_part = parts[1]
            hour, rest = time_part.split(':', 1)
            hour = str(int(hour))
            formatted_time = f"{date_part} at {hour}:{rest}"
        except:
            formatted_time = proposed_time
        
        title = self.get_translation_from_db(seller_lang, 'NEGOTIATION_PROPOSAL')
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
        title = self.get_translation_from_db(buyer_lang, 'listing_cancelled')
        body = self.get_translation_from_db(buyer_lang, 'listing_cancelled_text').replace('{seller_name}', seller_name).replace('{listing_title}', listing_title)
        
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


    

    
    def send_location_proposed_notification(self, user_id, proposer_name, listing_id, session_id=None):
        """
        Send notification when an alternative meeting location is proposed
        Args:
            user_id: ID of the user being notified
            proposer_name: Name of the user proposing the location
            listing_id: ID of the listing
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        user_lang = self.get_user_language(user_id)
        
        if not session_id:
            session_id = self.get_user_session(user_id)
        
        title = self.get_translation_from_db(user_lang, 'LOCATION_PROPOSED')
        body = f"{proposer_name} {self.get_translation_from_db(user_lang, 'proposed_new_meeting_location')}"
        
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

    def send_location_counter_notification(self, recipient_id, proposer_name, counter_location, listing_id, proposal_id):
        """
        Send notification when a counter-location proposal is made (neither party has accepted yet)
        Args:
            recipient_id: ID of the user receiving the notification
            proposer_name: Name of the user proposing the counter location
            counter_location: The counter location proposed
            listing_id: ID of the listing
            proposal_id: ID of the proposal
        """
        recipient_lang = self.get_user_language(recipient_id)
        session_id = self.get_user_session(recipient_id)
        
        title = self.get_translation_from_db(recipient_lang, 'LOCATION_COUNTER_PROPOSAL')
        body = f"{proposer_name} {self.get_translation_from_db(recipient_lang, 'location_counter_proposal_text')}"
        
        result = self.apn_service.send_notification(
            user_id=recipient_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='listing',
            deep_link_id=listing_id
        )
        
        return result

    def send_location_accepted_notification(self, recipient_id, accepter_name, listing_id, proposal_id):
        """
        Send notification when a location proposal is accepted by the other party
        Args:
            recipient_id: ID of the user receiving the notification
            accepter_name: Name of the user accepting the location
            listing_id: ID of the listing
            proposal_id: ID of the proposal
        """
        recipient_lang = self.get_user_language(recipient_id)
        session_id = self.get_user_session(recipient_id)
        
        title = self.get_translation_from_db(recipient_lang, 'LOCATION_ACCEPTED')
        body = f"{accepter_name} {self.get_translation_from_db(recipient_lang, 'location_accepted_text')}"
        
        result = self.apn_service.send_notification(
            user_id=recipient_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='listing',
            deep_link_id=listing_id
        )
        
        return result

    
    def send_exchange_marked_complete_notification(self, user_id, partner_name, listing_id, session_id=None):
        """
        Send notification when one party marks the exchange as complete
        Args:
            user_id: ID of the user being notified
            partner_name: Name of the partner who completed their part
            listing_id: ID of the listing
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        user_lang = self.get_user_language(user_id)
        
        if not session_id:
            session_id = self.get_user_session(user_id)
        
        title = self.get_translation_from_db(user_lang, 'EXCHANGE_MARKED_COMPLETE')
        body = f"{partner_name} has confirmed their exchange completion"
        
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
    
    def send_listing_reported_notification(self, seller_id, listing_id, reason, session_id=None):
        """
        Send notification when a listing is reported by another user
        Args:
            seller_id: ID of the seller whose listing was reported
            listing_id: ID of the listing
            reason: Reason for the report
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        user_lang = self.get_user_language(seller_id)
        
        if not session_id:
            session_id = self.get_user_session(seller_id)
        
        title = self.get_translation_from_db(user_lang, 'LISTING_REPORTED')
        reason_formatted = reason.replace('_', ' ').title()
        body = f"Your listing was reported for: {reason_formatted}"
        
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
    
    def send_account_issue_notification(self, user_id, issue_type, issue_description, session_id=None):
        """
        Send notification for account/payment issues
        Args:
            user_id: ID of the user
            issue_type: Type of issue (payment_failed, account_suspended, etc.)
            issue_description: Description of the issue
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        user_lang = self.get_user_language(user_id)
        
        if not session_id:
            session_id = self.get_user_session(user_id)
        
        title = self.get_translation_from_db(user_lang, 'ACCOUNT_ISSUE')
        body = issue_description
        
        result = self.apn_service.send_notification(
            user_id=user_id,
            title=title,
            body=body,
            badge=1,
            sound='default',
            session_id=session_id,
            deep_link_type='settings',
            deep_link_id='account'
        )
        
        return result
    
    def send_listing_expiration_warning(self, seller_id, listing_id, days_remaining, listing_title, session_id=None):
        """
        Send notification when listing is about to expire
        Args:
            seller_id: ID of the seller
            listing_id: ID of the listing
            days_remaining: Number of days until expiration
            listing_title: Title of the listing
            session_id: Optional session ID for auto-login (will be fetched if not provided)
        """
        user_lang = self.get_user_language(seller_id)
        
        if not session_id:
            session_id = self.get_user_session(seller_id)
        
        title = self.get_translation_from_db(user_lang, 'LISTING_EXPIRING_SOON')
        body = f"'{listing_title}' expires in {days_remaining} days"
        
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
    

# Global instance
notification_service = NotificationService()

