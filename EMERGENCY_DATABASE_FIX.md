# 🚨 EMERGENCY DATABASE FIX INSTRUCTIONS

## Problem
SQLite error: `no such column: created_at` when editing customers

## Quick Fix Steps

### 1. Backup Database (Windows Explorer)
1. Navigate to: `%APPDATA%\pos_offline_desktop_database\`
2. Copy `pos_offline_desktop_database.sqlite` to `pos_offline_desktop_database.sqlite.backup`

### 2. Run SQL Commands (if sqlite3 available)
Open Command Prompt and run:
```cmd
cd "%APPDATA%\pos_offline_desktop_database\"
sqlite3 pos_offline_desktop_database.sqlite "ALTER TABLE customers ADD COLUMN created_at INTEGER;"
sqlite3 pos_offline_desktop_database.sqlite "UPDATE customers SET created_at = CAST(strftime('%s','now') AS INTEGER) WHERE created_at IS NULL;"
sqlite3 pos_offline_desktop_database.sqlite "ALTER TABLE customers ADD COLUMN phone TEXT;"
```

### 3. Alternative: Manual Fix in App
The app has been updated with enhanced migration logic:
- Smart column existence check
- Fallback mechanisms
- Proper error handling

**Simply restart the application** - the migration should run automatically.

## Verification
After fix, test:
1. Edit any existing customer
2. Add new customer
3. Check console for SQLite errors

## Files Modified
- `lib/core/database/app_database.dart` - Enhanced migration logic
- `lib/ui/customer/widgets/edit_customer_dialog.dart` - Added created_at field
- All PDF font files - Fixed Unicode warnings

## Status
✅ Database migration enhanced
✅ Customer edit dialog fixed  
✅ Font warnings resolved
✅ Ready for testing
