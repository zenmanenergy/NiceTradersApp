# Dashboard Testing Suite

This folder contains Python test scripts to populate the database with different negotiation states, allowing you to manually test the iOS dashboard view against each scenario.

## Test Data

All scripts use the same hardcoded test data:
- **Listing ID**: `3e7cfcfe-1f30-4662-babe-884b60c9a53a`
- **Seller User ID**: `USR53a3c642-4914-4de8-8217-03ee3da42224`
- **Buyer User ID**: `USR387e9549-3339-4ea1-b0d2-f6a66c25c390`

## How to Use

### Option 1: Run Interactive Menu
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/tests/dashboard
python3 run_all.py
```

### Option 2: Run Individual Situation
```bash
python3 situation_1_buyer_proposes_time.py
python3 situation_2_time_accepted.py
python3 situation_3_both_paid_no_location.py
python3 situation_4_buyer_proposes_location.py
python3 situation_5_seller_proposes_location.py
python3 situation_6_both_accepted_ready_to_meet.py
python3 situation_7_completed_and_rated.py
```

## Workflow

For each situation:

1. **Run the Python script** → populates the database with the specific state
2. **Verify in terminal output** → check what was inserted
3. **Refresh iOS app** → pull down on dashboard to refresh
4. **Verify UI matches expected state** → check status, buttons, colors, messages
5. **Move to next situation** → run next script to test next state

## The 7 Situations

### Situation 1: Buyer Proposes Time
- **State**: Time proposal created, seller hasn't responded
- **Expected Dashboard**:
  - Buyer: "⏳ Waiting for Acceptance" (Orange)
  - Seller: "🎯 Action Required" (Red)

### Situation 2: Seller Accepted Time
- **State**: Time accepted, no payments yet
- **Expected Dashboard**:
  - Both: "✅ Payment Required" (Blue)

### Situation 3: Both Paid (No Location Yet)
- **State**: Time accepted, both paid, no location proposal yet
- **Expected Dashboard**:
  - Both: "✅ Ready to Meet" (Green)

### Situation 4: Buyer Proposed Location
- **State**: Location proposal created, seller hasn't responded
- **Expected Dashboard**:
  - Buyer: "⏳ Waiting for Location Approval" (Orange)
  - Seller: "🎯 Action Required" (Red)

### Situation 5: Seller Proposed Location
- **State**: Location proposal created by seller, buyer hasn't responded
- **Expected Dashboard**:
  - Buyer: "🎯 Action Required" (Red)
  - Seller: "⏳ Waiting for Location Approval" (Orange)

### Situation 6: Both Accepted (Ready to Meet)
- **State**: Time and location both accepted, all terms agreed
- **Expected Dashboard**:
  - Both: "✅ Ready to Meet" (Green) with meeting details
  - Shows "MARK EXCHANGE COMPLETE" button

### Situation 7: Completed & Rated
- **State**: Exchange marked complete, both users have rated
- **Expected Dashboard**:
  - Both: "✅ Completed" (Gray, archived)
  - Shows ratings and reviews

## Database Cleanup

Each script automatically cleans up previous test data before creating the new scenario. This ensures a clean state for testing.

## Debugging

If a situation doesn't display correctly:

1. **Check the terminal output** - it shows exactly what was inserted
2. **Manually query the database** - verify the data is there
3. **Check for UI bugs** - the issue might be in the iOS view logic
4. **Review the expected state** in the comments at the top of each script

## Notes

- All timestamps are UTC
- All currencies use USD→EUR conversion
- Meeting locations use San Francisco coordinates as defaults
- Test users are created automatically with each run
- No real payments are processed (just timestamps)
