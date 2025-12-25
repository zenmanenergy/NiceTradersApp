"""
Admin API endpoints for managing translations
Includes endpoints for the web admin localization editor
"""

from flask import Blueprint, request, jsonify
import json
import os
import subprocess
from datetime import datetime
from _Lib import Database
from Translations.TranslationHistory import record_translation_change

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


# ============================================================================
# NEW ENDPOINTS FOR LOCALIZATION EDITOR
# ============================================================================

@admin_translations_bp.route('/GetViewInventory', methods=['GET'])
def get_view_inventory():
    """
    Get complete inventory of all views and their translation keys
    Returns: iOS views with keys they use
    """
    try:
        # Load the inventory file generated by build_translation_inventory.py
        server_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(server_dir))
        inventory_file = os.path.join(project_root, 'translation_inventory.json')
        
        print(f"[DEBUG] GetViewInventory called")
        print(f"[DEBUG] server_dir: {server_dir}")
        print(f"[DEBUG] project_root: {project_root}")
        print(f"[DEBUG] inventory_file: {inventory_file}")
        print(f"[DEBUG] file exists: {os.path.exists(inventory_file)}")
        
        if not os.path.exists(inventory_file):
            error_msg = f'Inventory file not found at {inventory_file}'
            print(f"[ERROR] {error_msg}")
            return jsonify({
                'success': False,
                'message': error_msg
            }), 404
        
        print(f"[DEBUG] Loading inventory file...")
        with open(inventory_file, 'r', encoding='utf-8') as f:
            inventory = json.load(f)
        
        print(f"[DEBUG] Inventory loaded, building response...")
        # Build response with views data
        views = []
        for view_id, view_data in inventory['iosViews'].items():
            views.append({
                'viewId': view_data['viewId'],
                'viewType': view_data['viewType'],
                'viewPath': view_data['viewPath'],
                'translationKeys': view_data['translationKeys'],
                'keyCount': view_data['keyCount']
            })
        
        response = jsonify({
            'success': True,
            'views': sorted(views, key=lambda x: x['viewId']),
            'totalViews': len(views),
            'totalKeys': inventory['statistics']['totalKeys'],
            'languages': inventory['languages']
        })
        print(f"[DEBUG] ✅ Returning inventory with {len(views)} views")
        return response
        
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        print(f"[ERROR] GetViewInventory exception: {str(e)}")
        print(f"[ERROR] Traceback:\n{error_trace}")
        return jsonify({
            'success': False,
            'message': f'Error fetching view inventory: {str(e)}',
            'debug': error_trace
        }), 500


@admin_translations_bp.route('/CheckInventoryStatus', methods=['GET'])
def check_inventory_status():
    """
    Check if inventory file exists and debug info
    """
    server_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(server_dir))
    inventory_file = os.path.join(project_root, 'translation_inventory.json')
    
    exists = os.path.exists(inventory_file)
    file_info = {}
    
    if exists:
        stat = os.stat(inventory_file)
        file_info = {
            'size': stat.st_size,
            'modified': str(stat.st_mtime),
            'readable': os.access(inventory_file, os.R_OK)
        }
    
    return jsonify({
        'inventory_file_path': inventory_file,
        'exists': exists,
        'project_root': project_root,
        'server_dir': server_dir,
        'file_info': file_info
    })


@admin_translations_bp.route('/UpdateEnglish', methods=['POST'])
def update_english():
    """
    Update English translation with options to cascade to other languages
    
    Request body:
    {
        "translationKey": "WELCOME_BACK",
        "newEnglishValue": "Welcome Back to NiceTraders",
        "strategy": "auto_translate" | "manual_review" | "clear_others"
    }
    
    Strategies:
    - manual_review: Mark all other languages for review
    - clear_others: Clear other translations, require manual entry
    """
    try:
        data = request.get_json()
        translation_key = data.get('translationKey')
        new_english = data.get('newEnglishValue')
        strategy = data.get('strategy', 'manual_review')
        
        if not translation_key or not new_english:
            return jsonify({
                'success': False,
                'message': 'translationKey and newEnglishValue are required'
            }), 400
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get old English value for comparison
        cursor.execute(
            "SELECT translation_value FROM translations WHERE translation_key = %s AND language_code = 'en'",
            (translation_key,)
        )
        old_result = cursor.fetchone()
        old_english = old_result['translation_value'] if old_result else None
        
        # Update English translation
        now = datetime.now()
        cursor.execute("""
            INSERT INTO translations (translation_key, language_code, translation_value, updated_at)
            VALUES (%s, 'en', %s, %s)
            ON DUPLICATE KEY UPDATE translation_value = %s, updated_at = %s
        """, (translation_key, new_english, now, new_english, now))
        
        # Record history for English change
        record_translation_change(translation_key, 'en', old_english, new_english, 'English updated')
        
        # Get all languages except English
        cursor.execute("SELECT DISTINCT language_code FROM translations WHERE language_code != 'en' ORDER BY language_code")
        languages = [row['language_code'] for row in cursor.fetchall()]
        
        affected_translations = []
        
        if strategy == 'manual_review':
            # Clear other languages to mark as needing review
            for lang in languages:
                cursor.execute("""
                    UPDATE translations
                    SET translation_value = '', updated_at = %s
                    WHERE translation_key = %s AND language_code = %s
                """, (now, translation_key, lang))
                affected_translations.append({
                    'languageCode': lang,
                    'action': 'marked_for_review',
                    'status': 'needs_translation'
                })
        
        elif strategy == 'clear_others':
            # Clear other translations
            for lang in languages:
                cursor.execute("""
                    UPDATE translations
                    SET translation_value = '', updated_at = %s
                    WHERE translation_key = %s AND language_code = %s
                """, (now, translation_key, lang))
                affected_translations.append({
                    'languageCode': lang,
                    'action': 'cleared',
                    'status': 'requires_translation'
                })
        
        connection.commit()
        connection.close()
        
        return jsonify({
            'success': True,
            'translationKey': translation_key,
            'oldValue': old_english,
            'newValue': new_english,
            'strategy': strategy,
            'affectedTranslations': len(affected_translations),
            'details': affected_translations,
            'message': f'Updated English translation for {translation_key}'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error updating translation: {str(e)}'
        }), 500


@admin_translations_bp.route('/BulkUpdate', methods=['POST'])
def bulk_update():
    """
    Update multiple translations in a single request
    
    Request body:
    {
        "updates": [
            {
                "translationKey": "WELCOME_BACK",
                "languageCode": "es",
                "translationValue": "Bienvenido de Vuelta"
            },
            ...
        ]
    }
    """
    try:
        data = request.get_json()
        updates = data.get('updates', [])
        
        if not updates:
            return jsonify({
                'success': False,
                'message': 'updates array is required'
            }), 400
        
        cursor, connection = Database.ConnectToDatabase()
        now = datetime.now()
        
        successful = 0
        failed = 0
        results = []
        
        for update in updates:
            try:
                key = update.get('translationKey')
                lang = update.get('languageCode')
                value = update.get('translationValue')
                
                if not key or not lang or value is None:
                    results.append({
                        'translationKey': key,
                        'languageCode': lang,
                        'success': False,
                        'error': 'Missing required fields'
                    })
                    failed += 1
                    continue
                
                # Get old value for history
                cursor.execute(
                    "SELECT translation_value FROM translations WHERE translation_key = %s AND language_code = %s",
                    (key, lang)
                )
                old_result = cursor.fetchone()
                old_value = old_result['translation_value'] if old_result else None
                
                cursor.execute("""
                    INSERT INTO translations (translation_key, language_code, translation_value, updated_at)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE translation_value = %s, updated_at = %s
                """, (key, lang, value, now, value, now))
                
                # Record history
                record_translation_change(key, lang, old_value, value, 'Manual translation update')
                
                results.append({
                    'translationKey': key,
                    'languageCode': lang,
                    'success': True
                })
                successful += 1
                
            except Exception as e:
                results.append({
                    'translationKey': update.get('translationKey'),
                    'languageCode': update.get('languageCode'),
                    'success': False,
                    'error': str(e)
                })
                failed += 1
        
        connection.commit()
        connection.close()
        
        return jsonify({
            'success': True,
            'totalUpdates': len(updates),
            'successful': successful,
            'failed': failed,
            'results': results
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error in bulk update: {str(e)}'
        }), 500


@admin_translations_bp.route('/GetDetails', methods=['GET'])
def get_details():
    """
    Get detailed information about a specific translation key
    
    Query params:
    - key: translation key to get details for
    
    Returns: All translations in all languages, views using it, edit history
    """
    try:
        key = request.args.get('key')
        
        if not key:
            return jsonify({
                'success': False,
                'message': 'key parameter is required'
            }), 400
        
        # Load inventory to find views using this key
        server_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(server_dir))
        inventory_file = os.path.join(project_root, 'translation_inventory.json')
        
        if not os.path.exists(inventory_file):
            return jsonify({
                'success': False,
                'message': 'Inventory file not found'
            }), 404
        
        with open(inventory_file, 'r', encoding='utf-8') as f:
            inventory = json.load(f)
        
        # Find which views use this key
        used_in_views = []
        for key_data in inventory['keys']:
            if key_data['key'] == key:
                used_in_views = key_data['usedInViews']
                break
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get all translations for this key
        cursor.execute("""
            SELECT translation_key, language_code, translation_value, updated_at
            FROM translations
            WHERE translation_key = %s
            ORDER BY language_code
        """, (key,))
        
        rows = cursor.fetchall()
        connection.close()
        
        if not rows:
            return jsonify({
                'success': False,
                'message': f'Translation key not found: {key}'
            }), 404
        
        # Organize by language
        translations = {}
        english_value = None
        
        for row in rows:
            lang = row['language_code']
            translations[lang] = {
                'value': row['translation_value'],
                'lastModified': row['updated_at'].isoformat() if row['updated_at'] else None
            }
            if lang == 'en':
                english_value = row['translation_value']
        
        return jsonify({
            'success': True,
            'translationKey': key,
            'englishValue': english_value,
            'usageCount': len(used_in_views),
            'usedInViews': used_in_views,
            'translations': translations,
            'supportedLanguages': inventory['languages']
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching translation details: {str(e)}'
        }), 500


@admin_translations_bp.route('/ValidateKeys', methods=['POST'])
def validate_keys():
    """
    Validate that all translation keys in database exist in code
    and vice versa
    
    Returns:
    - Orphaned keys (in DB, not in code)
    - Missing keys (in code, not in DB)
    - Coverage percentage
    """
    try:
        # Load inventory
        server_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(server_dir))
        inventory_file = os.path.join(project_root, 'translation_inventory.json')
        
        if not os.path.exists(inventory_file):
            return jsonify({
                'success': False,
                'message': 'Inventory file not found'
            }), 404
        
        with open(inventory_file, 'r', encoding='utf-8') as f:
            inventory = json.load(f)
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get all keys in database
        cursor.execute("SELECT DISTINCT translation_key FROM translations ORDER BY translation_key")
        db_keys = set(row['translation_key'] for row in cursor.fetchall())
        
        connection.close()
        
        # Get all keys used in code
        code_keys = set()
        for key_data in inventory['keys']:
            code_keys.add(key_data['key'])
        
        # Find orphaned and missing
        orphaned = db_keys - code_keys
        missing = code_keys - db_keys
        coverage = (len(db_keys & code_keys) / len(db_keys)) * 100 if db_keys else 100
        
        return jsonify({
            'success': True,
            'validation': {
                'totalKeysInDB': len(db_keys),
                'totalKeysInCode': len(code_keys),
                'matchedKeys': len(db_keys & code_keys),
                'orphanedKeys': len(orphaned),
                'missingKeys': len(missing),
                'coverage': f'{coverage:.1f}%'
            },
            'orphanedKeys': sorted(list(orphaned)),
            'missingKeys': sorted(list(missing))
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error validating keys: {str(e)}'
        }), 500


@admin_translations_bp.route('/ScanCodeForKeys', methods=['POST'])
def scan_code_for_keys():
    """
    Re-scan iOS and web code for translation keys
    Updates the inventory cache
    Detects new/removed/orphaned keys
    """
    try:
        # Run the inventory builder script
        server_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(os.path.dirname(server_dir))
        script_path = os.path.join(project_root, 'build_translation_inventory.py')
        
        result = subprocess.run(
            ['python3', script_path],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if result.returncode != 0:
            return jsonify({
                'success': False,
                'message': f'Scan failed: {result.stderr}'
            }), 500
        
        # Load the updated inventory
        inventory_file = os.path.join(project_root, 'translation_inventory.json')
        
        with open(inventory_file, 'r', encoding='utf-8') as f:
            inventory = json.load(f)
        
        return jsonify({
            'success': True,
            'message': 'Code scan completed successfully',
            'inventory': {
                'totalKeys': inventory['statistics']['totalKeys'],
                'iosViews': inventory['statistics']['iosViews'],
                'orphanedKeys': inventory['statistics']['orphanedKeys'],
                'missingTranslations': inventory['statistics']['missingTranslations']
            }
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error scanning code: {str(e)}'
        }), 500


# ============================================================================
# HISTORY AND BACKUP ENDPOINTS
# ============================================================================

@admin_translations_bp.route('/GetHistory', methods=['GET'])
def get_history():
    """Get change history for a specific translation"""
    try:
        from Translations.TranslationHistory import get_translation_history
        
        key = request.args.get('key')
        language = request.args.get('language')
        limit = request.args.get('limit', 50, type=int)
        
        if not key:
            return jsonify({
                'success': False,
                'message': 'key parameter is required'
            }), 400
        
        history = get_translation_history(key, language, limit)
        
        # Convert datetime objects to ISO format
        for record in history:
            if 'changed_at' in record and record['changed_at']:
                record['changed_at'] = record['changed_at'].isoformat()
            if 'created_at' in record and record['created_at']:
                record['created_at'] = record['created_at'].isoformat()
        
        return jsonify({
            'success': True,
            'translationKey': key,
            'language': language,
            'history': history,
            'total': len(history)
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching history: {str(e)}'
        }), 500


@admin_translations_bp.route('/CreateBackup', methods=['POST'])
def create_backup():
    """Create a backup of all translations"""
    try:
        from Translations.TranslationHistory import create_backup as do_backup, ensure_backup_table
        
        # Ensure backup table exists
        ensure_backup_table()
        
        data = request.get_json() or {}
        backup_name = data.get('backup_name')
        
        result = do_backup(backup_name)
        
        if result['success']:
            return jsonify(result), 201
        else:
            return jsonify(result), 500
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error creating backup: {str(e)}'
        }), 500


@admin_translations_bp.route('/RollbackTranslation', methods=['POST'])
def rollback():
    """Rollback a translation to a previous version"""
    try:
        from Translations.TranslationHistory import rollback_translation
        
        data = request.get_json()
        key = data.get('translationKey')
        language = data.get('languageCode')
        history_id = data.get('historyId')
        
        if not all([key, language, history_id]):
            return jsonify({
                'success': False,
                'message': 'translationKey, languageCode, and historyId are required'
            }), 400
        
        result = rollback_translation(key, language, history_id)
        
        if result['success']:
            return jsonify(result)
        else:
            return jsonify(result), 400
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error rolling back: {str(e)}'
        }), 500


@admin_translations_bp.route('/AutoTranslate', methods=['POST'])
def auto_translate():
    """Auto-translate English text to multiple languages using Google Cloud Translate"""
    try:
        import os
        from google.cloud import translate_v3
        
        data = request.get_json()
        english_text = data.get('englishText')
        translation_key = data.get('translationKey')
        target_languages = data.get('targetLanguages', ['ja', 'es', 'fr', 'de', 'ar', 'hi', 'pt', 'ru', 'sk', 'zh'])
        
        if not english_text or not translation_key:
            return jsonify({
                'success': False,
                'message': 'englishText and translationKey are required'
            }), 400
        
        # Use Google Cloud Translate v3
        translations = {}
        translate_client = translate_v3.TranslationServiceClient()
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT', 'nicetraders')
        parent = f"projects/{project_id}/locations/global"
        
        # Translate to each target language
        for lang_code in target_languages:
            try:
                if lang_code == 'en':
                    translations[lang_code] = english_text
                    continue
                
                response = translate_client.translate_text(
                    request={
                        "parent": parent,
                        "contents": [english_text],
                        "mime_type": "text/plain",
                        "source_language_code": "en",
                        "target_language_code": lang_code,
                    }
                )
                
                translated_text = response.translations[0].translated_text
                translations[lang_code] = translated_text
                print(f"[DEBUG] Auto-translated to {lang_code}: {translated_text}")
                
            except Exception as e:
                print(f"[ERROR] Failed to translate to {lang_code}: {str(e)}")
                translations[lang_code] = None
        
        # Save all translations to database
        cursor, connection = Database.ConnectToDatabase()
        
        saved_count = 0
        failed_count = 0
        
        for lang_code, translated_text in translations.items():
            if translated_text is None:
                failed_count += 1
                continue
            
            try:
                query = """
                    INSERT INTO translations (translation_key, language_code, translation_value, updated_at, created_at)
                    VALUES (%s, %s, %s, NOW(), NOW())
                    ON DUPLICATE KEY UPDATE
                    translation_value = VALUES(translation_value),
                    updated_at = NOW()
                """
                cursor.execute(query, (translation_key, lang_code, translated_text))
                saved_count += 1
                
                # Record in history
                if lang_code != 'en':  # Don't double-record English
                    record_translation_change(
                        translation_key,
                        lang_code,
                        None,  # old value doesn't matter for auto-translate
                        translated_text,
                        'AUTO_TRANSLATE',
                        cursor
                    )
                
            except Exception as e:
                print(f"[ERROR] Failed to save {lang_code} translation: {str(e)}")
                failed_count += 1
        
        connection.commit()
        connection.close()
        
        return jsonify({
            'success': True,
            'message': f'Auto-translated {saved_count} languages successfully',
            'translations': translations,
            'savedCount': saved_count,
            'failedCount': failed_count,
            'translationKey': translation_key
        }), 201
        
    except Exception as e:
        import traceback
        print(f"[ERROR] Auto-translate error: {str(e)}")
        print(traceback.format_exc())
        return jsonify({
            'success': False,
            'message': f'Error auto-translating: {str(e)}'
        }), 500
