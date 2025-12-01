#!/usr/bin/env python3
"""
Utility functions for geocoding with database caching
"""

import requests
import time
import uuid
from datetime import datetime
from _Lib.Database import ConnectToDatabase

class GeocodingService:
    """Handle reverse geocoding with database persistence and rate limiting"""
    
    # Nominatim API endpoint (free, no API key required)
    NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse"
    
    # Simple in-memory cache for this session (for hot data)
    _cache = {}
    
    @classmethod
    def reverse_geocode(cls, latitude, longitude, timeout=5):
        """
        Reverse geocode coordinates to city/state using Nominatim API
        Caches results both in-memory and in the database for efficiency.
        
        Args:
            latitude: float
            longitude: float
            timeout: request timeout in seconds
            
        Returns:
            str: "City, State" format (e.g., "San Francisco, California")
            None: if geocoding fails
        """
        
        if not latitude or not longitude:
            return None
        
        try:
            # Check in-memory cache first
            cache_key = f"{latitude:.4f},{longitude:.4f}"
            if cache_key in cls._cache:
                return cls._cache[cache_key]
            
            # Check database cache second
            cached_result = cls._get_cached_from_db(latitude, longitude)
            if cached_result:
                cls._cache[cache_key] = cached_result
                return cached_result
            
            # Make API request if not cached
            result = cls._call_nominatim(latitude, longitude, timeout)
            
            if result:
                # Store in both caches
                cls._cache[cache_key] = result
                cls._store_in_db_cache(latitude, longitude, result)
                return result
            
            return None
            
        except Exception as e:
            print(f"[Geocoding] Error reverse geocoding {latitude}, {longitude}: {str(e)}")
            return None
    
    @classmethod
    def _call_nominatim(cls, latitude, longitude, timeout):
        """Make the actual API call to Nominatim"""
        try:
            params = {
                'lat': latitude,
                'lon': longitude,
                'format': 'json',
                'zoom': 10  # City-level detail
            }
            
            headers = {
                'User-Agent': 'NiceTraders/1.0'  # Nominatim requires User-Agent
            }
            
            response = requests.get(
                cls.NOMINATIM_URL, 
                params=params, 
                timeout=timeout,
                headers=headers
            )
            response.raise_for_status()
            
            data = response.json()
            address = data.get('address', {})
            
            # Try to get city-level information
            city = (
                address.get('city') or 
                address.get('town') or 
                address.get('village') or
                address.get('county')
            )
            
            # Get state/province
            state = (
                address.get('state') or 
                address.get('province')
            )
            
            # Format result
            if city and state:
                return f"{city}, {state}"
            elif city:
                return city
            elif state:
                return state
            else:
                # Fallback to country if no city/state
                return address.get('country', f"{latitude:.4f}, {longitude:.4f}")
            
        except requests.exceptions.Timeout:
            print(f"[Geocoding] Timeout: Could not geocode {latitude}, {longitude}")
            return None
        except requests.exceptions.RequestException as e:
            print(f"[Geocoding] Request error: {str(e)}")
            return None
    
    @classmethod
    def _get_cached_from_db(cls, latitude, longitude):
        """
        Retrieve cached geocoding result from database
        
        Returns:
            str: Cached geocoding result or None if not found
        """
        try:
            cursor, connection = ConnectToDatabase()
            
            query = """
                SELECT geocoded_location, access_count 
                FROM geocoding_cache 
                WHERE ABS(latitude - %s) < 0.0001 
                  AND ABS(longitude - %s) < 0.0001
                LIMIT 1
            """
            
            cursor.execute(query, (latitude, longitude))
            result = cursor.fetchone()
            
            if result:
                # Handle DictCursor result
                if isinstance(result, dict):
                    geocoded_location = result['geocoded_location']
                    access_count = result['access_count']
                else:
                    geocoded_location, access_count = result
                
                # Update access count for analytics
                update_query = """
                    UPDATE geocoding_cache 
                    SET access_count = %s, accessed_at = NOW()
                    WHERE ABS(latitude - %s) < 0.0001 
                      AND ABS(longitude - %s) < 0.0001
                """
                cursor.execute(update_query, (access_count + 1, latitude, longitude))
                connection.commit()
                
                cursor.close()
                connection.close()
                return geocoded_location
            
            cursor.close()
            connection.close()
            return None
            
        except Exception as e:
            print(f"[Geocoding] Database cache lookup error: {str(e)}")
            return None
    
    @classmethod
    def _store_in_db_cache(cls, latitude, longitude, geocoded_location):
        """
        Store geocoding result in database cache
        
        Args:
            latitude: float
            longitude: float
            geocoded_location: str - The geocoded result (e.g., "San Francisco, California")
        """
        try:
            cursor, connection = ConnectToDatabase()
            
            # Use UPSERT to handle duplicate coordinates
            query = """
                INSERT INTO geocoding_cache 
                (cache_id, latitude, longitude, geocoded_location, created_at, accessed_at, access_count)
                VALUES (%s, %s, %s, %s, NOW(), NOW(), 1)
                ON DUPLICATE KEY UPDATE
                    geocoded_location = VALUES(geocoded_location),
                    accessed_at = NOW(),
                    access_count = access_count + 1
            """
            
            cache_id = str(uuid.uuid4())
            cursor.execute(query, (cache_id, latitude, longitude, geocoded_location))
            connection.commit()
            cursor.close()
            connection.close()
            
        except Exception as e:
            print(f"[Geocoding] Error storing cache in database: {str(e)}")
    
    @classmethod
    def get_cache_stats(cls):
        """Get statistics about the geocoding cache"""
        try:
            cursor, connection = ConnectToDatabase()
            
            # Execute a single query with all aggregations
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_cached,
                    COALESCE(SUM(access_count), 0) as total_hits,
                    COALESCE(AVG(access_count), 0) as avg_hits,
                    MAX(accessed_at) as last_accessed
                FROM geocoding_cache
            """)
            result = cursor.fetchone()
            
            cursor.close()
            connection.close()
            
            if result:
                # Handle DictCursor result
                if isinstance(result, dict):
                    return {
                        'total_cached': result['total_cached'],
                        'total_hits': result['total_hits'],
                        'avg_hits_per_location': float(result['avg_hits']),
                        'last_accessed': str(result['last_accessed']) if result['last_accessed'] else None
                    }
                else:
                    return {
                        'total_cached': result[0],
                        'total_hits': result[1],
                        'avg_hits_per_location': float(result[2]),
                        'last_accessed': str(result[3]) if result[3] else None
                    }
            return None
            
        except Exception as e:
            print(f"[Geocoding] Error getting cache stats: {str(e)}")
            import traceback
            traceback.print_exc()
            return None
    
    @classmethod
    def clear_cache(cls):
        """Clear the in-memory cache"""
        cls._cache = {}
    
    @classmethod
    def clear_db_cache(cls):
        """Clear the entire database cache (use with caution)"""
        try:
            cursor, connection = ConnectToDatabase()
            cursor.execute("TRUNCATE TABLE geocoding_cache")
            connection.commit()
            cursor.close()
            connection.close()
            print("[Geocoding] Database cache cleared")
        except Exception as e:
            print(f"[Geocoding] Error clearing database cache: {str(e)}")
