"""
Unit tests for the Admin blueprint endpoints.
"""
import json


def test_search_users_returns_matching_user(client, test_user):
    """The SearchUsers endpoint should find users by email."""
    response = client.get('/Admin/SearchUsers', query_string={'email': test_user['email']})

    assert response.status_code == 200
    payload = json.loads(response.data)
    assert payload['success'] is True

    users = payload.get('data', [])
    assert any(user['UserId'] == test_user['user_id'] for user in users), "Test user should appear in search results"


def test_search_listings_returns_listing(client, test_listing):
    """The SearchListings endpoint returns listings that match the search text."""
    response = client.get('/Admin/SearchListings', query_string={'search': test_listing['currency']})

    assert response.status_code == 200
    payload = json.loads(response.data)
    assert payload['success'] is True

    listings = payload.get('data', [])
    assert any(listing['listing_id'] == test_listing['listing_id'] for listing in listings)


def test_get_user_by_id_returns_user(client, test_user):
    """The GetUserById endpoint should return the expected user record."""
    response = client.get('/Admin/GetUserById', query_string={'userId': test_user['user_id']})

    assert response.status_code == 200
    payload = json.loads(response.data)
    assert payload['success'] is True
    assert payload['user']['UserId'] == test_user['user_id']


def test_get_listing_by_id_returns_listing(client, test_listing):
    """The GetListingById endpoint should return the correct listing."""
    response = client.get('/Admin/GetListingById', query_string={'listingId': test_listing['listing_id']})

    assert response.status_code == 200
    payload = json.loads(response.data)
    assert payload['success'] is True
    assert payload['listing']['listing_id'] == test_listing['listing_id']


def test_update_user_allows_basic_edits(client, test_user):
    """The UpdateUser endpoint should persist edits to basic fields."""
    response = client.get('/Admin/UpdateUser', query_string={
        'userId': test_user['user_id'],
        'FirstName': 'Updated',
        'LastName': 'Admin',
        'Phone': '555-0101',
        'Location': 'Updated City',
        'IsActive': '0'
    })

    assert response.status_code == 200
    payload = json.loads(response.data)
    assert payload['success'] is True
    updated = payload['user']
    assert updated['FirstName'] == 'Updated'
    assert updated['LastName'] == 'Admin'
    assert updated['Phone'] == '555-0101'
    assert updated['Location'] == 'Updated City'
    assert updated['IsActive'] == 0
