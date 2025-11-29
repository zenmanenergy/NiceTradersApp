import json
import uuid
import string
import random
from datetime import datetime, timedelta
from _Lib import Database
from flask_cors import cross_origin

def generate_reset_token():
    """Generate a secure random reset token"""
    return ''.join(random.choices(string.ascii_letters + string.digits, k=32))

def forgot_password(email):
    """
    Handle forgot password request.
    Creates a password reset token and stores it in the database.
    Returns a success message and token (for development/email simulation).
    """
    try:
        connection = Database.getConnection()
        cursor = connection.cursor()
        
        # Check if user exists
        cursor.execute("""
            SELECT UserId, Email FROM users WHERE Email = %s
        """, (email,))
        
        user = cursor.fetchone()
        
        if not user:
            # Don't reveal if email exists (security best practice)
            return json.dumps({
                'success': True,
                'message': 'If an account exists with this email, a reset link has been sent.'
            })
        
        user_id, user_email = user
        token_id = str(uuid.uuid4())
        
        # Generate reset token
        reset_token = generate_reset_token()
        token_expires = datetime.now() + timedelta(hours=24)  # Token valid for 24 hours
        
        # Store reset token in database
        cursor.execute("""
            INSERT INTO password_reset_tokens (TokenId, UserId, ResetToken, TokenExpires, CreatedAt)
            VALUES (%s, %s, %s, %s, NOW())
            ON DUPLICATE KEY UPDATE
            ResetToken = VALUES(ResetToken),
            TokenExpires = VALUES(TokenExpires),
            CreatedAt = NOW()
        """, (token_id, user_id, reset_token, token_expires))
        
        connection.commit()
        
        # In a production app, you would send an email here with the reset link
        # For now, we return the token for testing purposes
        reset_link = f"https://yourdomain.com/reset-password?token={reset_token}"
        
        return json.dumps({
            'success': True,
            'message': 'If an account exists with this email, a reset link has been sent.',
            # Remove this in production - only for development
            'resetToken': reset_token,
            'resetLink': reset_link
        })
    
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e)
        })
    
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


def reset_password(reset_token, new_password):
    """
    Reset user password using a valid reset token.
    """
    try:
        connection = Database.getConnection()
        cursor = connection.cursor()
        
        # Check if token is valid and not expired
        cursor.execute("""
            SELECT UserId FROM password_reset_tokens
            WHERE ResetToken = %s AND TokenExpires > NOW()
        """, (reset_token,))
        
        result = cursor.fetchone()
        
        if not result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired reset token'
            })
        
        user_id = result[0]
        
        # Update user password
        cursor.execute("""
            UPDATE users SET Password = SHA2(%s, 256)
            WHERE UserId = %s
        """, (new_password, user_id))
        
        # Delete the used reset token
        cursor.execute("""
            DELETE FROM password_reset_tokens
            WHERE ResetToken = %s
        """, (reset_token,))
        
        connection.commit()
        
        return json.dumps({
            'success': True,
            'message': 'Password has been reset successfully.'
        })
    
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e)
        })
    
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
