import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show debugPrint;

/// Database Schema Fix Utility
///
/// This utility fixes the SQLite schema mismatch issue by implementing
/// the production-safe migration approach described in the problem statement.
///
/// Root Cause: SQLite table was created with wrong column types
/// Solution: Create new table with correct schema and migrate data
void main() async {
  debugPrint('=== Database Schema Fix Utility ===');

  // Get database path
  final dbPath = p.join(
    'C:\\Users\\${Platform.environment['USERNAME']}\\Documents',
    'pos_offline_desktop_database',
    'pos_offline_desktop_database.sqlite',
  );

  debugPrint('Target database: $dbPath');
  debugPrint('Database exists: ${await File(dbPath).exists()}');

  if (!await File(dbPath).exists()) {
    debugPrint('❌ Database not found. Run the app first to create it.');
    return;
  }

  try {
    await fixCustomerTableSchema(dbPath);
    debugPrint('\n✅ Schema fix completed successfully!');
    debugPrint('Please restart the application to apply changes.');
  } catch (e) {
    debugPrint('\n❌ Schema fix failed: $e');
  }
}

Future<void> fixCustomerTableSchema(String dbPath) async {
  debugPrint('\n=== Fixing Customers Table Schema ===');

  // Step 1: Check current schema
  debugPrint('1. Checking current schema...');
  final currentSchema = await runSqliteCommand(
    dbPath,
    'PRAGMA table_info(customers);',
  );
  debugPrint('Current schema:\n$currentSchema');

  // Step 2: Create backup
  debugPrint('\n2. Creating backup...');
  await runSqliteCommand(
    dbPath,
    'CREATE TABLE customers_backup AS SELECT * FROM customers;',
  );
  debugPrint('✅ Backup created');

  // Step 3: Create new table with correct schema
  debugPrint('\n3. Creating new table with correct schema...');
  final createTableSql = '''
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
  ''';

  await runSqliteCommand(dbPath, createTableSql);
  debugPrint('✅ New table created with correct schema');

  // Step 4: Copy data safely with type casting
  debugPrint('\n4. Migrating data with type casting...');
  final migrateSql = '''
    INSERT INTO customers_new (
      id, name, phone, address, gstinNumber, email,
      openingBalance, totalDebt, totalPaid, notes, isActive, status,
      createdAt, updatedAt
    )
    SELECT
      id,
      name,
      CAST(phone AS TEXT),
      address,
      gstinNumber,
      email,
      CAST(openingBalance AS REAL),
      CAST(totalDebt AS REAL),
      CAST(totalPaid AS REAL),
      notes,
      CAST(isActive AS INTEGER),
      CAST(status AS TEXT),
      createdAt,
      updatedAt
    FROM customers;
  ''';

  await runSqliteCommand(dbPath, migrateSql);
  debugPrint('✅ Data migrated successfully');

  // Step 5: Verify data migration
  debugPrint('\n5. Verifying migration...');
  final oldCount = await runSqliteCommand(
    dbPath,
    'SELECT COUNT(*) FROM customers;',
  );
  final newCount = await runSqliteCommand(
    dbPath,
    'SELECT COUNT(*) FROM customers_new;',
  );

  debugPrint('Old table records: $oldCount');
  debugPrint('New table records: $newCount');

  if (oldCount.trim() == newCount.trim()) {
    debugPrint('✅ Migration verification passed');
  } else {
    throw Exception('Migration verification failed: record count mismatch');
  }

  // Step 6: Replace old table
  debugPrint('\n6. Replacing old table...');
  await runSqliteCommand(dbPath, 'DROP TABLE customers;');
  await runSqliteCommand(
    dbPath,
    'ALTER TABLE customers_new RENAME TO customers;',
  );
  debugPrint('✅ Table replacement completed');

  // Step 7: Verify new schema
  debugPrint('\n7. Verifying new schema...');
  final newSchema = await runSqliteCommand(
    dbPath,
    'PRAGMA table_info(customers);',
  );
  debugPrint('New schema:\n$newSchema');

  // Step 8: Test insertion
  debugPrint('\n8. Testing customer insertion...');
  final testInsert = '''
    INSERT INTO customers (id, name, phone, status, openingBalance, totalDebt, totalPaid, isActive)
    VALUES ('test_fix_123', 'Test Customer', '1234567890', 'Active', 0.0, 0.0, 0.0, 1);
  ''';

  await runSqliteCommand(dbPath, testInsert);
  debugPrint('✅ Test insertion successful');

  // Clean up test data
  await runSqliteCommand(
    dbPath,
    'DELETE FROM customers WHERE id = \'test_fix_123\';',
  );

  // Step 9: Clean up backup
  debugPrint('\n9. Cleaning up backup...');
  await runSqliteCommand(dbPath, 'DROP TABLE customers_backup;');
  debugPrint('✅ Backup cleaned up');
}

Future<String> runSqliteCommand(String dbPath, String sql) async {
  final result = await Process.run('sqlite3', [dbPath, sql]);

  if (result.exitCode != 0) {
    throw Exception('SQLite command failed: ${result.stderr}\nSQL: $sql');
  }

  return result.stdout.toString();
}
