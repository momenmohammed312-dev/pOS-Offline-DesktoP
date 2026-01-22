# Database Schema Fix - Manual Instructions

## Problem Summary
The application throws `SqliteException(20): datatype mismatch` during `INSERT INTO customers` because the SQLite table was created with wrong column types that don't match the Drift schema definition.

## Root Cause
- **Drift Schema**: `phone` is defined as `TextColumn` (TEXT)
- **Actual SQLite**: `phone` column exists as `INTEGER` 
- SQLite allows flexible typing but Drift enforces strict binding
- Result: datatype mismatch (code 20)

## Solution Options

### OPTION A: Development Fix (Recommended)
**Delete and recreate the database completely**

1. **Close the Flutter application completely**
2. **Delete the database file manually**:
   ```
   Location: C:\Users\{YOUR_USERNAME}\Documents\pos_offline_desktop_database\
   File: pos_offline_desktop_database.sqlite
   ```
3. **Restart the application**
4. **Drift will recreate the schema with correct types**

### OPTION B: Production Safe Fix
**Use SQLite tools to migrate data**

1. **Install SQLite3 command line tools**:
   - Download from: https://sqlite.org/download.html
   - Add sqlite3.exe to your PATH

2. **Run the migration script**:
   ```bash
   cd "g:\development\POS-Offline-Desktop-main"
   dart standalone_db_fix.dart
   ```

3. **If sqlite3 is not available**, manually execute these SQL commands:

   ```sql
   -- Step 1: Create backup
   CREATE TABLE customers_backup AS SELECT * FROM customers;

   -- Step 2: Create new table with correct schema
   CREATE TABLE customers_new (
     id TEXT PRIMARY KEY,
     name TEXT NOT NULL,
     phone TEXT,
     address TEXT,
     gstinNumber TEXT,
     email TEXT,
     openingBalance REAL NOT NULL DEFAULT 0,
     totalDebt REAL NOT NULL DEFAULT 0,
     totalPaid REAL NOT NULL DEFAULT 0,
     notes TEXT,
     isActive INTEGER NOT NULL DEFAULT 1,
     status TEXT NOT NULL,
     createdAt TEXT,
     updatedAt TEXT
   );

   -- Step 3: Migrate data with type casting
   INSERT INTO customers_new (
     id, name, phone, address, gstinNumber, email,
     openingBalance, totalDebt, totalPaid, notes, isActive, status,
     createdAt, updatedAt
   )
   SELECT
     id,
     name,
     CAST(IFNULL(phone, '') AS TEXT),
     IFNULL(address, ''),
     IFNULL(gstinNumber, ''),
     IFNULL(email, ''),
     CAST(IFNULL(openingBalance, 0) AS REAL),
     CAST(IFNULL(totalDebt, 0) AS REAL),
     CAST(IFNULL(totalPaid, 0) AS REAL),
     IFNULL(notes, ''),
     CAST(IFNULL(isActive, 1) AS INTEGER),
     IFNULL(status, 'Active'),
     IFNULL(createdAt, ''),
     IFNULL(updatedAt, '')
   FROM customers;

   -- Step 4: Replace old table
   DROP TABLE customers;
   ALTER TABLE customers_new RENAME TO customers;

   -- Step 5: Cleanup
   DROP TABLE customers_backup;
   ```

## Drift Schema Reference (Expected Types)
From `lib/core/database/tables/customer_table.dart`:

```dart
TextColumn get phone => text().nullable();                    // TEXT
RealColumn get openingBalance => real().withDefault(...);     // REAL  
RealColumn get totalDebt => real().withDefault(...);         // REAL
RealColumn get totalPaid => real().withDefault(...);          // REAL
BoolColumn get isActive => boolean().withDefault(...);         // INTEGER
TextColumn get status => text().nullable().withDefault(...);   // TEXT
DateTimeColumn get createdAt => dateTime().nullable();         // TEXT/INTEGER
DateTimeColumn get updatedAt => dateTime().nullable();         // TEXT/INTEGER
```

## Verification Checklist
After applying the fix:

- [ ] Database file recreated OR migrated
- [ ] `PRAGMA table_info(customers);` shows correct types
- [ ] `phone` column is TEXT type
- [ ] `openingBalance`, `totalDebt`, `totalPaid` are REAL type  
- [ ] `isActive` column is INTEGER type
- [ ] `status` column is TEXT type
- [ ] Customer insertion works without errors
- [ ] Phone numbers with leading zeros are preserved

## Expected Result
After schema fix:
- ✅ No datatype mismatch errors
- ✅ Phone stored with leading zeros (e.g., "001234567890")
- ✅ Drift inserts succeed
- ✅ Hot restart works without errors
- ✅ No runtime hacks needed

## One-Line Truth
The bug was caused by an old SQLite schema with incorrect column types; deleting or rebuilding the table is the only real fix.

---

**Note**: The automated fix utilities (`standalone_db_fix.dart`, `pure_dart_db_fix.dart`) are provided but require sqlite3 command line tools to be installed and accessible in PATH.
