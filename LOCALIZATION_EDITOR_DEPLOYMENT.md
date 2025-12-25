# Localization Editor - Deployment Guide

## Production Deployment Checklist

### Phase 1: Pre-Deployment Verification (30 minutes)

- [ ] **Database Migration**
  ```bash
  cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
  venv/bin/python3 migrate_localization_schema.py
  ```
  - Expected: 5709 translation records migrated
  - Expected: 31 iOS views cached
  - Expected: 3 new tables created

- [ ] **Verify Database Changes**
  ```bash
  cd Server && venv/bin/python3 << 'EOF'
  import pymysql
  db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
  cursor = db.cursor()
  
  # Check translations table has new columns
  cursor.execute("DESCRIBE translations")
  cols = [row[0] for row in cursor.fetchall()]
  print("Columns:", cols)
  
  # Check new tables exist
  cursor.execute("SHOW TABLES LIKE 'translation_%'")
  tables = cursor.fetchall()
  print("Tables:", tables)
  
  db.close()
  EOF
  ```

- [ ] **Flask App Import Test**
  ```bash
  cd Server && venv/bin/python3 -c "from flask_app import app; from Translations.AdminTranslations import *; print('✓ OK')"
  ```
  - Expected: No errors, prints "✓ OK"

- [ ] **Inventory File Generated**
  ```bash
  cd /Users/stevenelson/Documents/GitHub/NiceTradersApp
  venv/bin/python3 build_translation_inventory.py
  ls -la translation_inventory.json
  ```
  - Expected: File exists with ~4KB size, contains 519 keys

### Phase 2: Frontend Deployment (15 minutes)

- [ ] **Install Dependencies**
  ```bash
  cd Client/Browser
  npm install
  ```

- [ ] **Development Test**
  ```bash
  npm run dev
  ```
  - Navigate to: `http://localhost:5173/localization`
  - Expected: Page loads, shows 31 views, 519 keys

- [ ] **Production Build**
  ```bash
  npm run build
  npm run preview
  ```
  - Expected: Build succeeds, no errors
  - Navigate to: `http://localhost:4173/localization`
  - Expected: Page loads and functions identically

### Phase 3: Backend Deployment (10 minutes)

- [ ] **Verify Running Server**
  ```bash
  cd Server && ./run.sh
  ```
  - Expected: Flask starts on port 9000
  - Expected: No import errors

- [ ] **Test API Endpoints**
  ```bash
  curl http://localhost:9000/Admin/Translations/GetViewInventory
  ```
  - Expected: Returns JSON with views array (31 items)

- [ ] **Test Authentication** (if implemented)
  - Verify admin endpoints require authentication
  - Test with admin and non-admin users

### Phase 4: Integration Testing (45 minutes)

#### Test Case 1: View Inventory
```
1. Load /localization page
2. Left panel shows 31 views
3. Click a view to expand keys
4. Click a key to load
5. Expected: Middle panel shows English value
```

#### Test Case 2: Edit English Translation
```
1. Select a translation key
2. Edit English value
3. Choose "Mark for Review" strategy
4. Click Save
5. Expected: Value saved, other languages marked for review
6. Check history for change record
```

#### Test Case 3: Edit Other Language
```
1. Select a translation key
2. Scroll to other language
3. Click Edit button
4. Update translation
5. Click Save
6. Expected: Translation updated
7. Check timestamp updated
```

#### Test Case 4: Validate Keys
```
1. Go to Status tab
2. Click Validate Keys
3. Expected: Shows results in seconds
4. Expected: Coverage shows 100% or less
5. Expected: Orphaned keys listed (161 expected)
```

#### Test Case 5: Scan Code for Keys
```
1. Go to Status tab
2. Click ⟳ Scan Code
3. Expected: Scanning message appears
4. Expected: Completes in 1-2 seconds
5. Expected: Results show 477 keys found
```

#### Test Case 6: History & Rollback
```
1. Edit a translation English value
2. View the translation again
3. History viewer shows the change
4. Click Rollback
5. Confirm rollback
6. Expected: Value reverts to previous
7. Expected: Rollback recorded in history
```

#### Test Case 7: Mobile Responsiveness
```
1. Open /localization on mobile device
2. Expected: Layout adapts (single column on mobile)
3. Expected: All buttons are touch-friendly
4. Expected: Panels collapse properly
```

#### Test Case 8: Database Audit Trail
```
1. Edit multiple translations
2. Query translation_history table:
   SELECT * FROM translation_history ORDER BY changed_at DESC LIMIT 10;
3. Expected: All changes recorded with old_value, new_value
```

### Phase 5: Performance Testing (30 minutes)

- [ ] **Load Test** (500 keys)
  ```
  Time to load ViewInventory: < 1 second
  Time to validate 519 keys: < 2 seconds
  Time to edit translation: < 500ms
  Time to scan iOS code: < 2 seconds
  ```

- [ ] **Concurrent Users** (if applicable)
  ```
  Open admin in 3 browser windows
  Each user edits different keys simultaneously
  Expected: No conflicts or data loss
  ```

- [ ] **Large Translation Update**
  ```
  BulkUpdate 100 translations
  Expected: Completes in < 10 seconds
  Expected: All 100 records in history table
  ```

### Phase 6: Security Audit (20 minutes)

- [ ] **Input Validation**
  - Try SQL injection in translation value: `'; DROP TABLE translations;--`
  - Expected: Treated as literal string, not executed

- [ ] **Permission Checks**
  - Test anonymous user can't access `/localization`
  - Test non-admin user can't access APIs
  - Expected: 401 or 403 responses

- [ ] **Database Security**
  - Verify user 'stevenelson' has limited privileges
  - Confirm backups are encrypted
  - Check audit logs are write-only

- [ ] **HTTPS** (if in production)
  - Verify connection is encrypted
  - Check certificate is valid
  - Test HSTS headers

### Phase 7: Backup & Recovery (15 minutes)

- [ ] **Create Backup**
  ```
  POST /Admin/Translations/CreateBackup
  {
      "backup_name": "pre_deployment_backup_v1.0"
  }
  ```
  - Expected: Backup created in `translation_backups` table

- [ ] **Verify Backup Data**
  ```bash
  cd Server && venv/bin/python3 << 'EOF'
  import pymysql
  db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
  cursor = db.cursor()
  cursor.execute("SELECT COUNT(*) FROM translation_backups")
  print("Backups:", cursor.fetchone()[0])
  cursor.execute("SELECT * FROM translation_backups ORDER BY created_at DESC LIMIT 1")
  print(cursor.fetchone())
  db.close()
  EOF
  ```

- [ ] **Test Rollback**
  - Make test change
  - Wait 10 seconds
  - Make another change
  - Rollback to first version
  - Verify success

### Phase 8: Documentation & Handoff (20 minutes)

- [ ] **User Documentation**
  - [ ] Share LOCALIZATION_EDITOR_IMPLEMENTATION.md with admins
  - [ ] Demonstrate editor workflow
  - [ ] Show how to create backups
  - [ ] Explain validation/scanning features

- [ ] **System Documentation**
  - [ ] Archive this deployment guide
  - [ ] Document any custom modifications
  - [ ] Update emergency contacts
  - [ ] Create runbook for common issues

- [ ] **Training** (if applicable)
  - [ ] Demo editor to translation team
  - [ ] Explain history/rollback features
  - [ ] Review best practices
  - [ ] Q&A session

### Final Verification Checklist

Before going live:

```
✓ Database schema fully migrated
✓ All tables created (3 new + 1 auto-create)
✓ 5709 translation records present
✓ 31 iOS views cached
✓ Flask app imports without errors
✓ All API endpoints accessible
✓ Frontend builds without errors
✓ Editor loads and displays data
✓ All 8 integration tests pass
✓ Performance targets met
✓ No SQL injection vulnerabilities
✓ Permissions properly enforced
✓ Backup created and verified
✓ Rollback tested successfully
✓ Documentation complete
✓ Admin team trained
```

## Rollback Plan (if issues occur)

### Scenario 1: Database Migration Failed
```bash
# Restore from backup (before migration)
cd Server && venv/bin/python3 << 'EOF'
# Contact database admin to restore from previous snapshot
# Or manually delete new columns/tables if migration was partial
import pymysql
db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
cursor = db.cursor()
# Run database restore commands here
EOF
```

### Scenario 2: Critical Bug in Frontend
```bash
# Revert to previous build
cd Client/Browser
git revert HEAD  # If using git
npm run build
npm run preview
```

### Scenario 3: API Endpoint Broken
```bash
# Restore from backup
POST /Admin/Translations/RollbackTranslation
{
    "key": "affected_key",
    "language": "all",
    "version": 1  // Restore to version 1
}
```

### Scenario 4: Complete Restore
```bash
# Restore all translations from backup
cd Server && venv/bin/python3 << 'EOF'
import pymysql
import json
db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
cursor = db.cursor()

# Get latest backup
cursor.execute("SELECT backup_data FROM translation_backups ORDER BY created_at DESC LIMIT 1")
backup_data = json.loads(cursor.fetchone()[0])

# Restore each translation
for key, languages in backup_data.items():
    for lang, value in languages.items():
        cursor.execute("""
            UPDATE translations 
            SET translation_value = %s, updated_by = 0, status = 'active'
            WHERE translation_key = %s AND language_code = %s
        """, (value, key, lang))

db.commit()
cursor.close()
db.close()
print("Restore complete")
EOF
```

## Post-Deployment Monitoring

### Daily Checks
- [ ] Check for any errors in Flask logs
- [ ] Verify translation_history table is growing (changes being recorded)
- [ ] Test editor loads without latency
- [ ] Confirm backup runs successfully

### Weekly Checks
- [ ] Review translation coverage metrics
- [ ] Check for any orphaned keys
- [ ] Verify rollback functionality still works
- [ ] Review translation edit statistics

### Monthly Checks
- [ ] Archive old backups (keep last 12)
- [ ] Review translation quality
- [ ] Update inventory if iOS app changed
- [ ] Check database size growth

## Support Contacts

| Issue | Contact | Action |
|-------|---------|--------|
| Database Questions | Database Admin | Schema, backups, migration issues |
| Flask Errors | Backend Team | API endpoints, server logs |
| Frontend Bugs | Frontend Team | Svelte components, UI issues |
| Translation Issues | Content Team | Translation accuracy, new languages |
| Emergency Rollback | All teams | Use procedures in "Rollback Plan" |

## Success Metrics

After deployment, these metrics indicate success:

- **Availability**: 99.9% uptime
- **Response Time**: API < 200ms, UI < 1s
- **Data Integrity**: Zero lost translations
- **Audit Trail**: 100% of changes recorded
- **Backup Success**: Daily automated backups
- **User Adoption**: All translators using editor

---

**Deployment Date**: [To be filled]
**Deployed By**: [To be filled]
**Environment**: [Development/Staging/Production]
**Database Backup Location**: [To be filled]
**Emergency Contact**: [To be filled]

## Appendix A: Database Recovery Query

If needed, restore translations from `translation_history`:

```sql
-- Show last 10 changes
SELECT * FROM translation_history ORDER BY changed_at DESC LIMIT 10;

-- Restore specific translation to previous version
SELECT * FROM translation_history 
WHERE translation_key = 'KEY_NAME' AND language_code = 'en'
ORDER BY changed_at DESC;

-- Count changes per key
SELECT translation_key, COUNT(*) as change_count
FROM translation_history
GROUP BY translation_key
ORDER BY change_count DESC;

-- Show all changes in last 24 hours
SELECT * FROM translation_history
WHERE changed_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY changed_at DESC;
```

## Appendix B: API Testing Script

```bash
#!/bin/bash
# Test all localization endpoints

BASE_URL="http://localhost:9000/Admin/Translations"

echo "Testing GetViewInventory..."
curl -s "$BASE_URL/GetViewInventory" | jq '.statistics'

echo "\nTesting ValidateKeys..."
curl -s -X POST "$BASE_URL/ValidateKeys" | jq '.validation_results'

echo "\nTesting GetHistory (sample key)..."
curl -s "$BASE_URL/GetHistory?key=WELCOME_BACK&language=en" | jq '.[0]'

echo "\nAll tests complete!"
```

---

**Version**: 1.0  
**Last Updated**: December 25, 2025  
**Status**: Ready for Deployment
