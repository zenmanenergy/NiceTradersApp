"""
Get All Translations
Returns all translations for all languages in a single call
"""

from flask import Blueprint, jsonify, request
import sys
sys.path.append('..')
from _Lib.Database import ConnectToDatabase

get_all_translations_bp = Blueprint('get_all_translations', __name__)

@get_all_translations_bp.route('/GetAllTranslations', methods=['GET'])
def get_all_translations():
    """
    Get all translations for all languages
    Returns: {
        "success": true,
        "translations": {
            "en": {"KEY": "value", ...},
            "ja": {"KEY": "value", ...},
            ...
        },
        "last_updated": "2024-11-25 12:00:00",
        "total_count": 4444
    }
    """
    try:
        cursor, db = ConnectToDatabase()
        
        # Get all translations grouped by language
        query = """
            SELECT language_code, translation_key, translation_value
            FROM translations
            ORDER BY language_code, translation_key
        """
        
        cursor.execute(query)
        results = cursor.fetchall()
        
        # Group translations by language
        translations_by_language = {}
        for row in results:
            lang = row['language_code']
            key = row['translation_key']
            value = row['translation_value']
            
            if lang not in translations_by_language:
                translations_by_language[lang] = {}
            
            translations_by_language[lang][key] = value
        
        # Get the most recent update timestamp across all translations
        cursor.execute("""
            SELECT MAX(updated_at) as last_updated
            FROM translations
        """)
        
        timestamp_result = cursor.fetchone()
        last_updated = str(timestamp_result['last_updated']) if timestamp_result and timestamp_result['last_updated'] else None
        
        # Count total translations
        total_count = len(results)
        
        cursor.close()
        db.close()
        
        return jsonify({
            'success': True,
            'translations': translations_by_language,
            'last_updated': last_updated,
            'total_count': total_count
        })
        
    except Exception as e:
        print(f"Error in GetAllTranslations: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
