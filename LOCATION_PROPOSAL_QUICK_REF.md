# Meeting Location Proposal Feature - Quick Reference

## Feature Overview
Users can now propose, accept, reject, and counter-propose meeting locations. The system works like the existing date/time negotiation, going back-and-forth until both parties agree.

## How to Use

### Propose a Location
1. In Contact Detail → Location tab
2. Search for a location
3. Tap to select it
4. "Propose Location" button appears
5. Tap button to open confirmation
6. Review location on map
7. Add optional message (optional)
8. Tap "Send Proposal"
9. Other user gets APN notification

### Respond to Location Proposal
1. Receive APN notification
2. Open Contact Detail → Location tab
3. See location proposal as expandable card
4. Tap to expand and see details
5. Choose one:
   - **Accept Location** ✓ - Finalizes location
   - **Reject Location** ✗ - Clear for new proposals
   - **Counter Propose** ↔️ - Search and propose alternative

## Database

### New Table Columns
- `proposed_latitude` - GPS latitude (-90 to 90)
- `proposed_longitude` - GPS longitude (-180 to 180)

Added to: `meeting_proposals` table

### Migration
File: `Server/migrations/004_add_location_coordinates_to_meeting_proposals.sql`
Run: `./venv/bin/python3 run_migrations.py`

## Backend APIs

### Send Proposal
```
POST /Meeting/ProposeMeeting
?sessionId=XXX
&listingId=XXX
&proposedLocation=Central+Park
&proposedLatitude=40.785091
&proposedLongitude=-73.968285
&proposedTime=2025-12-06T14:00:00
&message=Optional+message
```

Response:
```json
{
  "success": true,
  "proposal_id": "MPR-xxxxxxxx-xxxx",
  "message": "Meeting proposal sent successfully"
}
```

### Accept/Reject Proposal
```
POST /Meeting/RespondToMeeting
?sessionId=XXX
&proposalId=MPR-XXX
&response=accepted
```

Options: `accepted` or `rejected`

### Get All Proposals
```
GET /Meeting/GetMeetingProposals
?sessionId=XXX
&listingId=XXX
```

Response includes:
- All pending proposals
- proposed_latitude and proposed_longitude
- Status of each proposal
- Proposer and recipient info

## iOS Components

### LocationProposalConfirmView
Modal that shows before sending proposal
- Location preview on map
- Name and address
- Meeting time
- Optional message field

### LocationProposalCard
Displays proposal in list
- Expandable/collapsible
- Status indicator (color-coded)
- Proposer name
- Optional message
- Action buttons (accept/reject/counter)

### ContactLocationView
Main location management view
- Location search
- Proposal confirmation
- Proposal list with cards
- Response handling

## Translations

### Keys Added
- PROPOSE_LOCATION
- CONFIRM_LOCATION_PROPOSAL
- PROPOSED_LOCATION
- ACCEPT_LOCATION
- REJECT_LOCATION
- COUNTER_PROPOSE_LOCATION
- LOCATION_PROPOSED
- AWAITING_LOCATION_RESPONSE
- LOCATION_ACCEPTED
- PROPOSED_BY
- MESSAGE

### Languages
All 11 languages supported:
en, ja, es, fr, de, ar, hi, pt, ru, sk, zh

### Database Table
`translations` table
- Already inserted: 121 new rows
- Script: `add_location_proposal_translations.py`

## State Management

### ContactLocationView State
```swift
@State private var showLocationProposalConfirm: Bool
@State private var selectedLocationForProposal: MapSearchResult?
@State private var currentMeetingTime: String?
```

### ContactDetailView Bindings
```swift
@State private var currentMeeting: CurrentMeeting?
@State private var meetingProposals: [MeetingProposal]
```

## APN Notification
Automatically sent when location is proposed
- Triggers existing notification system
- Includes proposer name and location
- Links to correct listing

## Response Models

### LocationProposalResponse
```swift
struct LocationProposalResponse: Codable {
    let success: Bool
    let proposal_id: String?
    let message: String?
    let error: String?
}
```

### RespondToProposalResponse
```swift
struct RespondToProposalResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}
```

## Testing Scenarios

### Scenario 1: Basic Proposal
1. User A searches and proposes location
2. User B receives notification
3. User B accepts
4. Location finalized ✓

### Scenario 2: Rejection
1. User A proposes location
2. User B rejects
3. User A can propose again
4. Repeat until agreement ✓

### Scenario 3: Counter-Proposal
1. User A proposes location
2. User B counter-proposes different location
3. User A sees new proposal
4. User A accepts or counter-proposes
5. Continue until agreement ✓

## Files Changed

### Backend (Python)
- `ProposeMeeting.py` - Added lat/lon params
- `Meeting.py` - Added param parsing
- `GetMeetingProposals.py` - Return coords
- Migration file - Add columns to DB

### iOS (Swift)
- `ContactLocationView.swift` - Main implementation
- `LocationProposalConfirmView.swift` - New file
- `LocationProposalCard.swift` - New file
- `LocalizationManager.swift` - Translations

## Troubleshooting

**Proposal not sent?**
- Check session ID is valid
- Verify listing ID is correct
- Ensure other user has active contact access

**Coordinates not stored?**
- Run migration first
- Check database connection
- Verify coordinates are valid numbers

**Translations not showing?**
- Reload app cache
- Check LocalizationManager fallback
- Verify key matches exactly (case-sensitive)

**APN not received?**
- Check notification permission
- Verify device token registered
- Check network connection

## Performance Notes

- Location search limited to listing radius
- Coordinates indexed for fast queries
- Coordinates are nullable (backward compatible)
- Proposals expire after 7 days

## Security Considerations

- Only users with active contact access can propose
- Only recipients can accept/reject own proposals
- All API calls require valid session
- Proposer identification automatic from session

## Future Enhancements

Possible improvements:
- Saved favorite locations
- Map radius visualization
- Real-time location sharing
- Google Maps integration
- Navigation to proposed location
- Location approval via link
