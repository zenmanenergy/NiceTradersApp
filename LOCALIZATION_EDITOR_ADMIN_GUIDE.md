# Localization Editor - Admin Quick Reference

## Access the Localization Editor

1. Open web admin: `http://localhost:5173` or production URL
2. Find the 🌐 icon on home page
3. Click "Localization Editor"
4. Or go directly to: `/localization`

## Main Interface Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Translation Keys by View    │ English Editor │ Other Languages │
│ ─────────────────────────── │ ────────────── │ ─────────────── │
│ • Auth Views (8 keys)       │ Selected Key   │ 🇯🇵 Japanese    │
│ • Profile Views (12 keys)   │ English: [___] │ 🇪🇸 Spanish     │
│ • Trading Views (15 keys)   │ [Save] [Reset] │ 🇫🇷 French      │
│ • Messaging Views (6 keys)  │                │ 🇩🇪 German      │
│                             │ Used in views: │ 🇸🇦 Arabic      │
│ Search: [___________]       │ • Auth         │ 🇮🇳 Hindi       │
│                             │ • Profile      │ 🇵🇹 Portuguese  │
│                             │                │ 🇷🇺 Russian     │
│                             │                │ 🇸🇰 Slovak      │
│                             │                │ 🇨🇳 Chinese     │
│                             │                │ More... [View]  │
└─────────────────────────────────────────────────────────────┘
   Tabs: [Editor] [Status]
```

## Common Tasks

### Task 1: Edit an English Translation (2 min)

1. **Left Panel**: Search or scroll to find the view (e.g., "Auth Views")
2. **Expand**: Click to show all keys in that view
3. **Select**: Click the key name (e.g., "WELCOME_BACK")
4. **Middle Panel**: You'll see:
   - Current English value
   - Views that use it
   - Update strategy selector
5. **Edit**: Click in the English value field
6. **Change text**: Update to new value
7. **Strategy**: Choose one:
   - **Mark for Review** (default): Other translators review changes
   - **Clear All**: Clear other languages if text fundamentally changes
8. **Save**: Click [Save] button
9. **Confirm**: Click [Yes] in confirmation dialog

**Result**: English updated, change recorded in history

### Task 2: Translate to Another Language (2 min)

1. **Right Panel**: Find the language you need (e.g., 🇯🇵 Japanese)
2. **Status**: See color:
   - 🟢 Green: Translation complete
   - 🟡 Yellow: Empty/needs translation
   - 🔴 Red: Marked for review
3. **Click**: [Edit] button on language card
4. **Update**: Enter translation in popup
5. **Save**: Click [Save Translation]

**Result**: Translation updated, timestamp shows when

### Task 3: Find All Untranslated Keys (3 min)

1. **Status Tab**: Click the "Status" tab
2. **Language Coverage**: See chart with percentages
3. **Find gaps**: Look for languages < 100%
4. **List missing**: Scroll down to see specific keys needing translation

**Result**: Know exactly which keys need work

### Task 4: Undo a Recent Change (1 min)

1. **While editing**: Look for change history below translation
2. **View history**: Shows who changed it, when, old vs new value
3. **Click [↶ Rollback]**: Reverts to previous version
4. **Confirm**: Click [Yes]

**Result**: Translation reverted to previous version

### Task 5: Check for Consistency Issues (2 min)

1. **Status Tab**: Click the "Status" tab
2. **Click**: [Validate Keys] button
3. **Review results**:
   - Overall coverage percentage
   - How many languages are complete
   - Orphaned keys (in database, not used in code)
   - Missing keys (in code, not in database)
4. **Fix issues**: Orphaned keys can be deleted, missing keys added

**Result**: Know if database matches iOS app

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+S` | Save current translation |
| `Ctrl+Z` | Undo last edit |
| `Ctrl+F` | Search in left panel |
| `Esc` | Close edit dialog |
| `Enter` | Save in edit dialog |

## Status Indicators

### Colors in Right Panel

- 🟢 **Green**: Complete translation
- 🟡 **Yellow**: Empty (needs translation)
- 🟠 **Orange**: Recently changed (needs review)
- 🔴 **Red**: Marked for review by English editor
- ⚪ **Gray**: Deprecated

### Coverage Colors

- 💚 90-100%: Excellent coverage
- 💛 70-90%: Good coverage, some gaps
- 🧡 50-70%: Fair, many gaps
- ❤️ 0-50%: Poor coverage, needs work

## Troubleshooting

### Problem: Can't see the translation I'm looking for

**Solution**:
1. Use search box in left panel
2. Type key name or partial text
3. Results appear instantly
4. Check Status tab for missing keys

### Problem: Translation didn't save

**Solution**:
1. Check for error message at top
2. Make sure you clicked [Save]
3. Try refreshing page
4. If still failing, check if you're still logged in

### Problem: Another admin changed the same key

**Solution**:
1. Refresh page to see latest version
2. Check history to see who made the change
3. Review and edit if needed
4. Your change won't overwrite if conflict detected

### Problem: Orphaned keys in Status tab

**Explanation**: Keys exist in database but aren't used in iOS app anymore
- Likely from old features no longer in code
- Safe to ignore or delete (won't affect running app)

### Problem: Missing keys in Status tab

**Explanation**: Keys are in iOS code but not in translation database
- Need to be added for translations to work
- Click [Scan Code] button to auto-add new keys

## Best Practices

✅ **Do This**
- Edit English translation first
- Review history before making changes
- Mark for review when English changes
- Create backup before bulk changes
- Use descriptive change notes
- Check coverage metrics regularly
- Scan code after iOS app updates

❌ **Don't Do This**
- Skip English translation, go straight to other languages
- Make large changes without reviewing history
- Delete keys without verifying they're unused
- Mix multiple concept changes in one key
- Leave translations empty without reason
- Force English changes without notification

## Common Workflows

### Workflow 1: Release Localization Update (15 min)

1. **Status Tab**: Click [Validate Keys]
2. **Check Coverage**: All languages should be 95%+
3. **Review Missing**: Address any obviously missing keys
4. **Run Scan**: Click [Scan Code] to detect new keys
5. **Create Backup**: Use API to create named backup
6. **Notify Team**: Tell translators about new/modified keys
7. **Monitor**: Check history for translation progress

### Workflow 2: Fix Untranslated Language (30 min)

1. **Status Tab**: Identify language with low coverage (e.g., Arabic)
2. **Click [Show Missing]**: See list of untranslated keys
3. **Editor Tab**: Translate each key one by one
4. **Batch Mode**: Use BulkUpdate API for multiple keys
5. **Verify**: Re-run validation to confirm 100%
6. **Notify**: Tell localization team it's complete

### Workflow 3: Update Master Translation (45 min)

1. **Plan Changes**: List all keys that need updates
2. **Edit English**: Update English values one by one
3. **Mark for Review**: Ensure other languages are marked
4. **Notify Translators**: Tell them which keys changed
5. **Set Timeline**: Give deadline for reviews
6. **Follow Up**: Check progress after 1-2 days
7. **Finalize**: Review completed translations

## API Endpoints (for advanced users)

### Get All Keys and Views
```
GET /Admin/Translations/GetViewInventory
```

### Update English (Triggers Review)
```
POST /Admin/Translations/UpdateEnglish
{
    "translation_key": "WELCOME_BACK",
    "english_value": "Welcome back!",
    "strategy": "mark_for_review"
}
```

### Bulk Update Multiple Languages
```
POST /Admin/Translations/BulkUpdate
{
    "updates": [
        {"key": "WELCOME_BACK", "language": "ja", "value": "おかえりなさい"},
        {"key": "WELCOME_BACK", "language": "es", "value": "¡Bienvenido de vuelta!"}
    ]
}
```

### Get Translation History
```
GET /Admin/Translations/GetHistory?key=WELCOME_BACK&language=en
```

### Create Backup
```
POST /Admin/Translations/CreateBackup
{
    "backup_name": "release_v2.0",
    "description": "Backup before v2.0 release"
}
```

### Rollback to Previous Version
```
POST /Admin/Translations/RollbackTranslation
{
    "translation_key": "WELCOME_BACK",
    "language_code": "en",
    "version": 3
}
```

## Statistics You'll See

- **519**: Total translation keys
- **31**: iOS views that have translations
- **11**: Supported languages
- **5709**: Total translation records in database
- **477**: Keys actually used in iOS code
- **161**: Orphaned keys (in DB but not in code)

## Daily Checklist

- [ ] **Morning**: Check Status tab for validation results
- [ ] **Before Release**: Create backup with version number
- [ ] **Throughout Day**: Monitor translation progress
- [ ] **End of Day**: Review any failed translations
- [ ] **Weekly**: Archive old backups, export statistics

## Emergency Procedures

### If translations went wrong:

1. **Go to Status Tab**
2. **Click [⟳ Validate Keys]** to see what's wrong
3. **Review History** for recent changes
4. **Use Rollback** to undo last change
5. **Scan Code** to ensure database matches iOS
6. **Contact Admin** if issue persists

### If can't login:

1. Check you're using admin account
2. Verify database connection working
3. Try refreshing page
4. Clear browser cache
5. Contact administrator

### If data looks corrupted:

1. **DON'T make changes**
2. **Create Backup immediately** using API
3. **Contact Database Admin**
4. **Restore from previous backup** if needed

## Quick Links

| Task | Path |
|------|------|
| Edit translations | `/localization` |
| View statistics | `/localization/status` |
| Admin dashboard | `/admin` |
| Home page | `/` |

## Contact & Support

- **Need Help?** Ask admin team
- **Found Bug?** Report with steps to reproduce
- **Want Feature?** Submit request to dev team
- **Emergency?** Use rollback procedures above

---

**Version**: 1.0  
**Last Updated**: December 25, 2025  
**Help Video**: [Link to be added]
