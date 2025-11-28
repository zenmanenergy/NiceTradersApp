"""
Apple Push Notification (APN) service for sending push notifications to iOS devices
"""
import json
import asyncio
from datetime import datetime

try:
    from aioapns import APNs, NotificationRequest, PushType
    HAS_APNS = True
    print("✓ aioapns imported successfully!")
except Exception as e:
    HAS_APNS = False
    print(f"✗ Failed to import aioapns: {e}")

from _Lib.Database import ConnectToDatabase


class APNService:
    """Service for sending APN messages to users"""
    
    def __init__(self, certificate_path=None, key_id=None, team_id=None, topic=None):
        """
        Initialize APN service
        Args:
            certificate_path: Path to Apple's APNS .p8 key file
            key_id: Your 10-character Key ID from Apple
            team_id: Your 10-character Team ID from Apple
            topic: Your app's bundle ID (e.g., NiceTraders.Nice-Traders)
        """
        self.certificate_path = certificate_path
        self.key_id = key_id
        self.team_id = team_id
        self.topic = topic or "NiceTraders.Nice-Traders"
        self.use_sandbox = True  # Set to False for production
    
    def send_notification(self, user_id, title, body, badge=1, sound='default', 
                         session_id=None, deep_link_type=None, deep_link_id=None, device_id=None):
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
            device_id: Optional specific device ID to send to (if not provided, sends to all active devices)
        
        Returns:
            dict with success status and message
        """
        print(f"DEBUG: HAS_APNS = {HAS_APNS}")
        if not HAS_APNS:
            return {
                'success': False,
                'error': 'aioapns library not installed. Install with: pip install aioapns'
            }
        
        if not self.certificate_path or not self.key_id or not self.team_id:
            return {
                'success': False,
                'error': 'APN credentials not configured. Need certificate_path, key_id, and team_id.'
            }
        
        # Run async send in sync context
        return asyncio.run(self._async_send_notification(
            user_id, title, body, badge, sound, 
            session_id, deep_link_type, deep_link_id, device_id
        ))
    
    async def _async_send_notification(self, user_id, title, body, badge, sound,
                                       session_id, deep_link_type, deep_link_id, device_id=None):
        """Async implementation of send_notification"""
        try:
            # Get user's device tokens from database
            cursor, connection = ConnectToDatabase()
            
            # If specific device_id provided, get only that device
            if device_id:
                cursor.execute(
                    "SELECT device_token FROM user_devices WHERE UserId = %s AND device_id = %s AND device_type = 'ios' AND device_token IS NOT NULL AND is_active = 1",
                    (user_id, device_id)
                )
            else:
                # Otherwise get all active iOS devices
                cursor.execute(
                    "SELECT device_token FROM user_devices WHERE UserId = %s AND device_type = 'ios' AND device_token IS NOT NULL AND is_active = 1",
                    (user_id,)
                )
            tokens = [row['device_token'] for row in cursor.fetchall()]
            
            if not tokens:
                cursor.close()
                connection.close()
                return {
                    'success': False,
                    'error': f'No active iOS device tokens found for user {user_id}. User may need to log in on a physical device.'
                }
            
            # Create APNs client
            apns = APNs(
                key=self.certificate_path,
                key_id=self.key_id,
                team_id=self.team_id,
                topic=self.topic,
                use_sandbox=self.use_sandbox
            )
            
            # Build alert payload
            alert = {
                'title': title,
                'body': body
            }
            
            # Build custom data
            custom_data = {
                'timestamp': datetime.now().isoformat()
            }
            if session_id:
                custom_data['sessionId'] = session_id
            if deep_link_type and deep_link_id:
                custom_data['deepLinkType'] = deep_link_type
                custom_data['deepLinkId'] = deep_link_id
            
            # Send to all device tokens
            failed_tokens = []
            for token in tokens:
                try:
                    request = NotificationRequest(
                        device_token=token,
                        message={
                            'aps': {
                                'alert': alert,
                                'badge': badge,
                                'sound': sound
                            },
                            **custom_data
                        },
                        push_type=PushType.ALERT
                    )
                    response = await apns.send_notification(request)
                    if not response.is_successful:
                        failed_tokens.append({'token': token, 'error': response.description})
                except Exception as e:
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
