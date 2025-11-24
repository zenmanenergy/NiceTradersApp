"""
Apple Push Notification (APN) service for sending push notifications to iOS devices
"""
import json
from datetime import datetime

try:
    from apns2.client import APNsClient
    from apns2.errors import APNsException
    from apns2.payload import Payload
    HAS_APNS = True
except ImportError:
    HAS_APNS = False

from _Lib.Database import ConnectToDatabase


class APNService:
    """Service for sending APN messages to users"""
    
    def __init__(self, certificate_path=None):
        """
        Initialize APN service
        Args:
            certificate_path: Path to Apple's APNS certificate file (.p8)
        """
        self.certificate_path = certificate_path
        self.client = None
        if HAS_APNS and certificate_path:
            try:
                self.client = APNsClient(certificate=certificate_path)
            except Exception as e:
                print(f"Failed to initialize APNs client: {e}")
    
    def send_notification(self, user_id, title, body, badge=1, sound='default', 
                         session_id=None, deep_link_type=None, deep_link_id=None):
        """
        Send a push notification to a user
        Args:
            user_id: User ID to send to
            title: Notification title
            body: Notification message body
            badge: Badge number (default 1)
            sound: Sound file name or 'default'
            session_id: Optional session ID for auto-login
            deep_link_type: Type of deep link (listing, meeting, message, etc.)
            deep_link_id: ID to deep link to
        
        Returns:
            dict with success status and message
        """
        if not HAS_APNS:
            return {
                'success': False,
                'error': 'apns2 library not installed. Install with: pip install apns2'
            }
        
        if not self.client:
            return {
                'success': False,
                'error': 'APN certificate not configured. Set APNS_CERTIFICATE_PATH environment variable.'
            }
        
        try:
            # Get user's device tokens from database
            cursor, connection = ConnectToDatabase()
            cursor.execute(
                "SELECT device_token FROM user_devices WHERE UserId = %s AND device_type = 'ios'",
                (user_id,)
            )
            tokens = [row['device_token'] for row in cursor.fetchall()]
            
            if not tokens:
                cursor.close()
                connection.close()
                return {
                    'success': False,
                    'error': f'No iOS device tokens found for user {user_id}'
                }
            
            # Create payload
            payload = Payload(
                alert={
                    'title': title,
                    'body': body
                },
                badge=badge,
                sound=sound,
                custom={
                    'timestamp': datetime.now().isoformat()
                }
            )
            
            # Add deep linking data if provided
            if session_id:
                payload.custom['sessionId'] = session_id
            if deep_link_type and deep_link_id:
                payload.custom['deepLinkType'] = deep_link_type
                payload.custom['deepLinkId'] = deep_link_id
            
            # Send to all device tokens
            failed_tokens = []
            for token in tokens:
                try:
                    self.client.send_notification(token, payload)
                except APNsException as e:
                    failed_tokens.append({'token': token, 'error': str(e)})
            
            # Log the notification
            notification_log = {
                'user_id': user_id,
                'title': title,
                'body': body,
                'tokens_sent': len(tokens) - len(failed_tokens),
                'failed_tokens': len(failed_tokens),
                'timestamp': datetime.now().isoformat(),
                'deep_link_type': deep_link_type,
                'deep_link_id': deep_link_id
            }
            
            try:
                cursor.execute(
                    "INSERT INTO apn_logs (UserId, Data, DateSent) VALUES (%s, %s, NOW())",
                    (user_id, json.dumps(notification_log))
                )
                connection.commit()
            except Exception as log_err:
                print(f"Failed to log notification: {log_err}")
            
            cursor.close()
            connection.close()
            
            if failed_tokens:
                return {
                    'success': True,
                    'message': f'Sent to {len(tokens) - len(failed_tokens)} devices',
                    'failed': failed_tokens
                }
            else:
                return {
                    'success': True,
                    'message': f'Successfully sent to {len(tokens)} device(s)'
                }
        
        except Exception as e:
            return {'success': False, 'error': str(e)}
