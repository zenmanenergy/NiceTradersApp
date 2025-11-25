"""
Admin API endpoints for managing translations
"""

from flask import Blueprint, request
import json
from _Lib import Database

admin_translations_bp = Blueprint('admin_translations', __name__, url_prefix='/Admin/Translations')


@admin_translations_bp.route('/UpdateTranslation', methods=['POST'])
def update_translation():
    """Update a translation value"""
    try:
        data = request.get_json()
        
        if not data:
            return json.dumps({
                'success': False,
                'message': 'No JSON data provided'
            }), 400
        
        translation_key = data.get('translation_key')
        language_code = data.get('language_code')
        translation_value = data.get('translation_value')
        
        if not all([translation_key, language_code, translation_value]):
            return json.dumps({
                'success': False,
                'message': 'Missing required fields: translation_key, language_code, translation_value'
            }), 400
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Update or insert translation
        query = """
            INSERT INTO translations (translation_key, language_code, translation_value, updated_at, created_at)
            VALUES (%s, %s, %s, NOW(), NOW())
            ON DUPLICATE KEY UPDATE
            translation_value = VALUES(translation_value),
            updated_at = NOW()
        """
        cursor.execute(query, (translation_key, language_code, translation_value))
        connection.commit()
        connection.close()
        
        return json.dumps({
            'success': True,
            'message': 'Translation updated successfully',
            'translation_key': translation_key,
            'language_code': language_code
        }), 200
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        return json.dumps({
            'success': False,
            'message': f'Error updating translation: {str(e)}'
        }), 500


@admin_translations_bp.route('/GetLanguages', methods=['GET'])
def get_languages():
    """Get all supported languages"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        query = """
            SELECT DISTINCT language_code
            FROM translations
            ORDER BY language_code
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        connection.close()
        
        languages = [row['language_code'] for row in results]
        
        return json.dumps({
            'success': True,
            'languages': languages,
            'count': len(languages)
        }), 200
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Error fetching languages: {str(e)}'
        }), 500


@admin_translations_bp.route('/GetTranslationKeys', methods=['GET'])
def get_translation_keys():
    """Get all translation keys"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        query = """
            SELECT DISTINCT translation_key
            FROM translations
            ORDER BY translation_key
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        connection.close()
        
        keys = [row['translation_key'] for row in results]
        
        return json.dumps({
            'success': True,
            'keys': keys,
            'count': len(keys)
        }), 200
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Error fetching translation keys: {str(e)}'
        }), 500


@admin_translations_bp.route('/GetTranslationsByKey', methods=['GET'])
def get_translations_by_key():
    """Get translations for a specific key across all languages"""
    try:
        translation_key = request.args.get('key')
        
        if not translation_key:
            return json.dumps({
                'success': False,
                'message': 'Missing required parameter: key'
            }), 400
        
        cursor, connection = Database.ConnectToDatabase()
        
        query = """
            SELECT language_code, translation_value, updated_at
            FROM translations
            WHERE translation_key = %s
            ORDER BY language_code
        """
        cursor.execute(query, (translation_key,))
        results = cursor.fetchall()
        
        connection.close()
        
        if not results:
            return json.dumps({
                'success': False,
                'message': f'No translations found for key: {translation_key}'
            }), 404
        
        translations = {}
        for row in results:
            translations[row['language_code']] = {
                'value': row['translation_value'],
                'updated_at': row['updated_at'].isoformat() if row['updated_at'] else None
            }
        
        return json.dumps({
            'success': True,
            'translation_key': translation_key,
            'translations': translations
        }), 200
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Error fetching translations: {str(e)}'
        }), 500


@admin_translations_bp.route('/BulkUpdateTranslations', methods=['POST'])
def bulk_update_translations():
    """Bulk update translations for a language"""
    try:
        data = request.get_json()
        
        if not data:
            return json.dumps({
                'success': False,
                'message': 'No JSON data provided'
            }), 400
        
        language_code = data.get('language_code')
        translations = data.get('translations')  # dict of {key: value}
        
        if not language_code or not translations:
            return json.dumps({
                'success': False,
                'message': 'Missing required fields: language_code, translations'
            }), 400
        
        cursor, connection = Database.ConnectToDatabase()
        
        updated_count = 0
        for translation_key, translation_value in translations.items():
            query = """
                INSERT INTO translations (translation_key, language_code, translation_value, updated_at, created_at)
                VALUES (%s, %s, %s, NOW(), NOW())
                ON DUPLICATE KEY UPDATE
                translation_value = VALUES(translation_value),
                updated_at = NOW()
            """
            cursor.execute(query, (translation_key, language_code, translation_value))
            updated_count += 1
        
        connection.commit()
        connection.close()
        
        return json.dumps({
            'success': True,
            'message': f'Updated {updated_count} translations',
            'language_code': language_code,
            'updated_count': updated_count
        }), 200
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        return json.dumps({
            'success': False,
            'message': f'Error updating translations: {str(e)}'
        }), 500


@admin_translations_bp.route('/DeleteTranslation', methods=['DELETE'])
def delete_translation():
    """Delete a translation"""
    try:
        translation_key = request.args.get('key')
        language_code = request.args.get('language')
        
        if not translation_key or not language_code:
            return json.dumps({
                'success': False,
                'message': 'Missing required parameters: key, language'
            }), 400
        
        cursor, connection = Database.ConnectToDatabase()
        
        query = """
            DELETE FROM translations
            WHERE translation_key = %s AND language_code = %s
        """
        cursor.execute(query, (translation_key, language_code))
        connection.commit()
        
        rows_affected = cursor.rowcount
        connection.close()
        
        if rows_affected == 0:
            return json.dumps({
                'success': False,
                'message': 'Translation not found'
            }), 404
        
        return json.dumps({
            'success': True,
            'message': 'Translation deleted successfully'
        }), 200
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        return json.dumps({
            'success': False,
            'message': f'Error deleting translation: {str(e)}'
        }), 500
