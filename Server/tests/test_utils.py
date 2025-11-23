"""
Utility functions for testing
"""
import uuid


def generate_uuid(prefix):
    """
    Generate a UUID with a 3-letter prefix that fits CHAR(39).
    
    Format: XXX-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    Total length: 3 (prefix) + 1 (dash) + 36 (UUID with dashes) = 40 chars
    
    To fit CHAR(39), we remove one character from the UUID.
    We remove the last character to maintain UUID format visibility.
    
    Args:
        prefix: 3-letter table identifier (e.g., 'USR', 'SES', 'LST')
    
    Returns:
        String of exactly 39 characters
    
    Examples:
        USR-550e8400-e29b-41d4-a716-44665544000  (39 chars)
        SES-7c9e6679-7425-40de-944b-e07fc1f9038  (39 chars)
        LST-f47ac10b-58cc-4372-a567-0e02b2c3d47  (39 chars)
    """
    if len(prefix) != 3:
        raise ValueError(f"Prefix must be exactly 3 characters, got: {prefix}")
    
    # Generate UUID and remove the last character to make it 35 chars
    uuid_str = str(uuid.uuid4())[:-1]  # 36 chars -> 35 chars
    
    return f"{prefix}-{uuid_str}"
