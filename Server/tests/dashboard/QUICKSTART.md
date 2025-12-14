# Quick Start Guide

## Running Tests

### Use the interactive menu:
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
venv/bin/python3 tests/dashboard/run_all.py
```

### Or run a specific situation directly:
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
venv/bin/python3 tests/dashboard/situation_1_buyer_proposes_time.py
venv/bin/python3 tests/dashboard/situation_2_time_accepted.py
venv/bin/python3 tests/dashboard/situation_3_both_paid_no_location.py
venv/bin/python3 tests/dashboard/situation_4_buyer_proposes_location.py
venv/bin/python3 tests/dashboard/situation_5_seller_proposes_location.py
venv/bin/python3 tests/dashboard/situation_6_both_accepted_ready_to_meet.py
venv/bin/python3 tests/dashboard/situation_7_completed_and_rated.py
```

## Workflow

1. Run a script → database populated with test data
2. Check terminal output → verify what was inserted
3. Open iOS app → it's already watching the database
4. Pull down to refresh → dashboard view updates automatically
5. Verify UI matches the expected state in the script comments
6. Move to next situation → repeat

## Test Data Reference

All situations use the same hardcoded IDs:

| Field | Value |
|-------|-------|
| Listing ID | `3e7cfcfe-1f30-4662-babe-884b60c9a53a` |
| Seller ID | `USR53a3c642-4914-4de8-8217-03ee3da42224` |
| Buyer ID | `USR387e9549-3339-4ea1-b0d2-f6a66c25c390` |
| Currency | USD → EUR |
| Amount | $100 |
| Location | San Francisco, CA |

## Debugging

If a situation doesn't display correctly, check the terminal output first. Each script shows exactly what was inserted into the database. You can also manually query the database to verify the state.
