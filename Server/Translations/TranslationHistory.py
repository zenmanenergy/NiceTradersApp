"""
Translation history and backup functionality
Tracks all changes to translations for audit trail and rollback
"""

import pymysql
from datetime import datetime
from functools import wraps
from _Lib import Database

def record_translation_change(key, language_code, old_value, new_value, change_reason, changed_by=None):
    """Record a translation change in the history table"""
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders'
        )
        cursor = db.cursor()
        
        cursor.execute("""
            INSERT INTO translation_history
            (translation_key, language_code, old_value, new_value, changed_by, change_reason)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (key, language_code, old_value, new_value, changed_by, change_reason))
        
        db.commit()
        cursor.close()
        db.close()
        return True
    except Exception as e:
        print(f"Error recording translation history: {str(e)}")
        return False


def get_translation_history(key, language_code=None, limit=50):
    """Get history of changes for a translation key"""
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders',
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = db.cursor()
        
        if language_code:
            cursor.execute("""
                SELECT *
                FROM translation_history
                WHERE translation_key = %s AND language_code = %s
                ORDER BY changed_at DESC
                LIMIT %s
            """, (key, language_code, limit))
        else:
            cursor.execute("""
                SELECT *
                FROM translation_history
                WHERE translation_key = %s
                ORDER BY changed_at DESC
                LIMIT %s
            """, (key, limit))
        
        results = cursor.fetchall()
        cursor.close()
        db.close()
        
        return [dict(row) for row in results]
    except Exception as e:
        print(f"Error fetching translation history: {str(e)}")
        return []


def create_backup(backup_name=None):
    """Create a backup of all translations"""
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders',
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = db.cursor()
        
        # Get all translations
        cursor.execute("SELECT * FROM translations ORDER BY translation_key, language_code")
        translations = cursor.fetchall()
        
        # Create backup record
        backup_name = backup_name or f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        import json
        backup_data = json.dumps([dict(t) for t in translations], default=str)
        
        cursor.execute("""
            INSERT INTO translation_backups (backup_name, backup_data)
            VALUES (%s, %s)
        """, (backup_name, backup_data))
        
        backup_id = cursor.lastrowid
        db.commit()
        cursor.close()
        db.close()
        
        return {
            'success': True,
            'backup_id': backup_id,
            'backup_name': backup_name,
            'record_count': len(translations),
            'created_at': datetime.now().isoformat()
        }
    except Exception as e:
        print(f"Error creating backup: {str(e)}")
        return {'success': False, 'error': str(e)}


def rollback_translation(key, language_code, history_id):
    """Rollback a translation to a previous version from history"""
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders',
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = db.cursor()
        
        # Get the historical record
        cursor.execute("""
            SELECT old_value, new_value FROM translation_history
            WHERE id = %s AND translation_key = %s AND language_code = %s
        """, (history_id, key, language_code))
        
        history = cursor.fetchone()
        if not history:
            return {'success': False, 'error': 'History record not found'}
        
        # Rollback to the old value
        old_value = history['old_value']
        current_value = history['new_value']
        
        cursor.execute("""
            UPDATE translations
            SET translation_value = %s, updated_at = NOW()
            WHERE translation_key = %s AND language_code = %s
        """, (old_value, key, language_code))
        
        # Record this rollback in history
        cursor.execute("""
            INSERT INTO translation_history
            (translation_key, language_code, old_value, new_value, change_reason)
            VALUES (%s, %s, %s, %s, %s)
        """, (key, language_code, current_value, old_value, f'Rollback from history ID {history_id}'))
        
        db.commit()
        cursor.close()
        db.close()
        
        return {
            'success': True,
            'message': f'Rolled back {key} ({language_code}) to previous version',
            'new_value': old_value
        }
    except Exception as e:
        return {'success': False, 'error': str(e)}


def ensure_backup_table():
    """Create translation_backups table if it doesn't exist"""
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders'
        )
        cursor = db.cursor()
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS translation_backups (
                id INT AUTO_INCREMENT PRIMARY KEY,
                backup_name VARCHAR(255) NOT NULL UNIQUE,
                backup_data LONGTEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_by INT NULL,
                description TEXT,
                record_count INT,
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """)
        
        db.commit()
        cursor.close()
        db.close()
        return True
    except Exception as e:
        print(f"Error creating backup table: {str(e)}")
        return False
