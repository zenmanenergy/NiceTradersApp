# NiceTradersApp Server Unit Tests

Comprehensive unit tests for all server API endpoints.

## Test Coverage

### Authentication & User Management
- **Login Tests** (`test_login.py`)
  - Login with valid/invalid credentials
  - Session verification
  - Missing parameters handling

- **Signup Tests** (`test_signup.py`)
  - Account creation
  - Duplicate email detection
  - Email existence checking
  - Missing fields validation

- **Profile Tests** (`test_profile.py`)
  - Get user profile
  - Update profile information
  - Exchange history retrieval
  - Settings management
  - Account deletion

### Listings Management
- **Listings Tests** (`test_listings.py`)
  - Create new listing
  - Get all listings with filters
  - Get listing by ID
  - Update listing (owner only)
  - Delete listing
  - Unauthorized access prevention

### Dashboard & Statistics
- **Dashboard Tests** (`test_dashboard.py`)
  - User dashboard data retrieval
  - User statistics
  - Session validation

### Search Functionality
- **Search Tests** (`test_search.py`)
  - Basic listing search
  - Multi-filter search
  - Location-based search
  - Search filters retrieval
  - Popular searches

### Contact & Messaging
- **Contact Tests** (`test_contact.py`)
  - Get contact details
  - Check contact access
  - Purchase contact access
  - Send interest messages
  - Report listings
  - Get purchased contacts
  - Get listing purchases
  - Contact messaging
  - Locked exchange rates

### Exchange Rates
- **Exchange Rates Tests** (`test_exchange_rates.py`)
  - Download exchange rates
  - Get all rates
  - Get specific rate between currencies
  - Currency amount conversion
  - Parameter validation

### Meeting Coordination
- **Meeting Tests** (`test_meeting.py`)
  - Propose meeting
  - Get meeting proposals
  - Respond to meeting (accept/reject)
  - Authorization checks

## Setup

### 1. Install Test Dependencies

```bash
cd Server
source venv/bin/activate
pip install -r tests/requirements-test.txt
```

### 2. Configure Database

Ensure the test database is configured with the same credentials as in `_Lib/Database.py`:
- Database: `nicetraders`
- User: `stevenelson`
- Password: `mwitcitw711`

### 3. Run Tests

Run all tests:
```bash
pytest tests/
```

Run specific test file:
```bash
pytest tests/test_login.py
```

Run with coverage report:
```bash
pytest --cov=. --cov-report=html tests/
```

Run with verbose output:
```bash
pytest -v tests/
```

Run specific test:
```bash
pytest tests/test_login.py::TestLoginEndpoints::test_login_success -v
```

## Test Structure

```
tests/
├── __init__.py              # Package initialization
├── conftest.py              # Pytest fixtures and configuration
├── requirements-test.txt    # Test dependencies
├── test_login.py           # Login endpoint tests
├── test_signup.py          # Signup endpoint tests
├── test_profile.py         # Profile endpoint tests
├── test_listings.py        # Listings endpoint tests
├── test_dashboard.py       # Dashboard endpoint tests
├── test_search.py          # Search endpoint tests
├── test_contact.py         # Contact endpoint tests
├── test_exchange_rates.py  # Exchange rates endpoint tests
└── test_meeting.py         # Meeting endpoint tests
```

## Fixtures

### `client`
Flask test client for making requests to the API.

### `db_connection`
Database connection for test data setup and cleanup.

### `test_user`
Creates a test user with session. Automatically cleaned up after test.
Returns:
```python
{
    'user_id': 'TEST-...',
    'session_id': 'SESSION-...',
    'email': 'test_...@example.com',
    'password': 'TestPassword123'
}
```

### `test_listing`
Creates a test listing. Automatically cleaned up after test.
Returns:
```python
{
    'listing_id': 'LISTING-...',
    'user_id': 'TEST-...',
    'currency': 'USD',
    'amount': 1000.00,
    'accept_currency': 'EUR'
}
```

## Best Practices

1. **Isolation**: Each test is independent and cleans up after itself
2. **Fixtures**: Use fixtures for common test data setup
3. **Assertions**: Clear, specific assertions for each test case
4. **Cleanup**: All test data is automatically removed after tests
5. **Coverage**: Tests cover success cases, error cases, and edge cases

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run tests
  run: |
    cd Server
    source venv/bin/activate
    pytest tests/ --cov --cov-report=xml
```

## Notes

- Tests use the actual database (not mocked)
- All test users/listings are prefixed with `TEST-`, `LISTING-`, etc.
- Automatic cleanup ensures no test data persists
- bcrypt is used for password hashing (matches production)
- Tests verify both success and failure scenarios
