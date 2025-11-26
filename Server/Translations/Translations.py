"""
Translations API endpoints
"""

from flask import Blueprint, request, jsonify
from datetime import datetime
import json
from _Lib import Database

translations_bp = Blueprint('translations', __name__, url_prefix='/Translations')

@translations_bp.route('/GetTranslations', methods=['GET'])
def get_translations():
    """Get all translations for a specific language"""
    try:
        language = request.args.get('language', 'en')
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get all translations for the language
        query = """
            SELECT translation_key, translation_value, updated_at
            FROM translations
            WHERE language_code = %s
            ORDER BY translation_key
        """
        cursor.execute(query, (language,))
        results = cursor.fetchall()
        
        connection.close()
        
        if not results:
            return json.dumps({
                'success': False,
                'message': f'No translations found for language: {language}'
            }), 404
        
        # Convert to dictionary format
        translations = {}
        latest_updated = None
        
        for row in results:
            translations[row['translation_key']] = row['translation_value']
            # Track the latest update timestamp
            if latest_updated is None or row['updated_at'] > latest_updated:
                latest_updated = row['updated_at']
        
        return json.dumps({
            'success': True,
            'language': language,
            'translations': translations,
            'last_updated': latest_updated.isoformat() if latest_updated else None,
            'count': len(translations)
        }), 200
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Error fetching translations: {str(e)}'
        }), 500


@translations_bp.route('/GetLastUpdated', methods=['GET'])
def get_last_updated():
    """Get the last update timestamp for all languages"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        # Get latest update for each language
        query = """
            SELECT language_code, MAX(updated_at) as last_updated
            FROM translations
            GROUP BY language_code
            ORDER BY language_code
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        connection.close()
        
        last_updated_map = {}
        for row in results:
            last_updated_map[row['language_code']] = row['last_updated'].isoformat() if row['last_updated'] else None
        
        return json.dumps({
            'success': True,
            'last_updated': last_updated_map
        }), 200
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Error fetching last updated: {str(e)}'
        }), 500


@translations_bp.route('/GetAllTranslations', methods=['GET'])
def get_all_translations():
    """Get all translations for all languages in a single call"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        # Get all translations
        query = """
            SELECT language_code, translation_key, translation_value
            FROM translations
            ORDER BY language_code, translation_key
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Get the most recent update timestamp
        cursor.execute("SELECT MAX(updated_at) as last_updated FROM translations")
        timestamp_result = cursor.fetchone()
        last_updated = timestamp_result['last_updated'].isoformat() if timestamp_result and timestamp_result['last_updated'] else None
        
        connection.close()
        
        # Group translations by language
        translations_by_language = {}
        for row in results:
            lang = row['language_code']
            key = row['translation_key']
            value = row['translation_value']
            
            if lang not in translations_by_language:
                translations_by_language[lang] = {}
            
            translations_by_language[lang][key] = value
        
        return json.dumps({
            'success': True,
            'translations': translations_by_language,
            'last_updated': last_updated,
            'total_count': len(results)
        }), 200
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Error fetching all translations: {str(e)}'
        }), 500
