# Customer Status Datatype Mismatch - QUICK FIX

## Problem
SqliteException(20): datatype mismatch on INSERT INTO customers
- Code expects: status column as TEXT 
- Existing database has: status column as INTEGER

## Immediate Solutions

### Option 1: Delete Database (Development)
1. Delete: `~/Documents/pos_offline_desktop_database/pos_offline_desktop_database.sqlite`
2. Restart app - fresh database created with correct schema
3. All data lost but schema fixed

### Option 2: Manual Schema Fix (Production)
1. Backup existing data
2. Run SQL to convert INTEGER status to TEXT status
3. Restore data with proper conversion

## Root Cause
- Migration failed to properly update column type
- SQLite doesn't allow ALTER COLUMN to change data types
- Need table recreation with proper schema

## Files to Check
- `lib/core/database/app_database.dart` - Migration logic
- `lib/ui/customer/add_edit_customer_page.dart` - Customer insertion
- Database location: Application Documents directory

## Status
✅ Root cause identified
🔧 Fix in progress
⏳ Testing pending
