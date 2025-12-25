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
        self.use_sandbox = True  # Development builds use sandbox
    
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
        if not HAS_APNS:
            return {
                'success': False,
                'error': 'aioapns library not available. Check that aioapns is properly installed.'
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
                    "SELECT device_token, device_id, device_name FROM user_devices WHERE user_id = %s AND device_id = %s AND device_type = 'ios'",
                    (user_id, device_id)
                )
            else:
                # Otherwise get all iOS devices
                cursor.execute(
                    "SELECT device_token, device_id, device_name FROM user_devices WHERE user_id = %s AND device_type = 'ios'",
                    (user_id,)
                )
            
            all_devices = cursor.fetchall()
            
            # Filter for devices with tokens
            tokens = [row['device_token'] for row in all_devices if row.get('device_token')]
            
            # Always return debug info
            debug_info = {
                'query_executed': True,
                'user_id': user_id,
                'device_id': device_id,
                'devices_found': len(all_devices),
                'tokens_found': len(tokens),
                'all_devices': [{'id': d.get('device_id'), 'has_token': bool(d.get('device_token'))} for d in all_devices]
            }
            
            if not tokens:
                cursor.close()
                connection.close()
                device_info = []
                for device in all_devices:
                    device_info.append({
                        'device_id': device.get('device_id'),
                        'device_name': device.get('device_name', 'Unknown'),
                        'has_token': 'YES' if device.get('device_token') else 'NO',
                        'token_preview': device.get('device_token', '')[:20] if device.get('device_token') else None
                    })
                return {
                    'success': False,
                    'error': f'No iOS device tokens found for user {user_id}',
                    'requested_device_id': device_id,
                    'query_type': 'specific_device' if device_id else 'all_devices',
                    'devices_found': len(all_devices),
                    'devices_with_tokens': len(tokens),
                    'device_details': device_info,
                    'debug': debug_info
                }
            
            # Create APNs client
            try:
                # Read the key file content instead of passing the path
                with open(self.certificate_path, 'r') as key_file:
                    key_content = key_file.read()
                
                apns = APNs(
                    key=key_content,
                    key_id=self.key_id,
                    team_id=self.team_id,
                    topic=self.topic,
                    use_sandbox=self.use_sandbox
                )
            except Exception as apns_init_error:
                import os as os_module
                cert_exists = os_module.path.exists(self.certificate_path)
                cert_readable = os_module.path.exists(self.certificate_path) and os_module.access(self.certificate_path, os_module.R_OK)
                cert_size = os_module.path.getsize(self.certificate_path) if cert_exists else 0
                
                # Try to read the file content for debugging
                cert_content = None
                try:
                    with open(self.certificate_path, 'r') as f:
                        cert_content = f.read()[:100]  # First 100 chars
                except Exception as read_err:
                    cert_content = f"Error reading: {str(read_err)}"
                
                return {
                    'success': False,
                    'error': f'Failed to initialize APNs: {str(apns_init_error)}',
                    'error_type': type(apns_init_error).__name__,
                    'debug': {
                        'certificate_path': self.certificate_path,
                        'certificate_exists': cert_exists,
                        'certificate_readable': cert_readable,
                        'certificate_size': cert_size,
                        'certificate_content_preview': cert_content,
                        'key_id': self.key_id,
                        'team_id': self.team_id,
                        'topic': self.topic,
                        'use_sandbox': self.use_sandbox
                    }
                }

            
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
                    print(f"📤 [APNService] Sending to token: {token[:20]}...")
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
                        push_type=PushType.ALERT,
	                    priority=10
                    )
                    response = await apns.send_notification(request)
                    print(f"📥 [APNService] APNs response - Success: {response.is_successful}, Status: {response.status}, Description: {response.description}")
                    if not response.is_successful:
                        print(f"❌ [APNService] Failed to send - Status: {response.status}, Reason: {response.description}")
                        failed_tokens.append({'token': token, 'error': response.description, 'status': response.status})
                    else:
                        print(f"✅ [APNService] Successfully sent notification to device")
                except Exception as e:
                    print(f"❌ [APNService] Exception sending notification: {str(e)}")
                    failed_tokens.append({'token': token, 'error': str(e)})
            
            # Log the notification
            notification_metadata = {
                'tokens_sent': len(tokens) - len(failed_tokens),
                'failed_tokens': len(failed_tokens),
                'timestamp': datetime.now().isoformat(),
                'deep_link_type': deep_link_type,
                'deep_link_id': deep_link_id
            }
            
            try:
                cursor.execute(
                    """INSERT INTO apn_logs 
                    (user_id, notification_title, notification_body, device_count, failed_count, metadata) 
                    VALUES (%s, %s, %s, %s, %s, %s)""",
                    (user_id, title, body, len(tokens), len(failed_tokens), json.dumps(notification_metadata))
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
                    'failed': failed_tokens,
                    'debug': {
                        'tokens_count': len(tokens),
                        'failed_count': len(failed_tokens),
                        'user_id': user_id,
                        'device_id': device_id,
                        'devices_found': len(all_devices),
                        'all_devices_info': [{'id': d.get('device_id'), 'has_token': bool(d.get('device_token')), 'token_preview': d.get('device_token', '')[:20] if d.get('device_token') else None} for d in all_devices],
                        'tokens_list_preview': [t[:20] for t in tokens]
                    }
                }
            else:
                return {
                    'success': True,
                    'message': f'Successfully sent to {len(tokens)} device(s)',
                    'tokens_sent': len(tokens),
                    'debug': {
                        'tokens_count': len(tokens),
                        'failed_count': 0,
                        'user_id': user_id,
                        'device_id': device_id,
                        'devices_found': len(all_devices),
                        'all_devices_info': [{'id': d.get('device_id'), 'has_token': bool(d.get('device_token')), 'token_preview': d.get('device_token', '')[:20] if d.get('device_token') else None} for d in all_devices],
                        'tokens_list_preview': [t[:20] for t in tokens]
                    }
                }
        
        except Exception as e:
            return {
                'success': False,
                'error': f'Exception in send_notification: {str(e)}',
                'error_type': type(e).__name__
            }
