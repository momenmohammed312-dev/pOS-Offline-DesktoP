import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;

/// Fix status column datatype mismatch
/// Changes status column from INTEGER to TEXT type
void main() async {
  debugPrint('=== Fixing Status Column Datatype ===\n');

  // Find database file
  final dbPaths = [
    p.join(
      'C:\\Users\\${Platform.environment['USERNAME'] ?? ''}\\Documents',
      'pos_offline_desktop_database',
      'pos_offline_desktop_database.sqlite',
    ),
    p.join(
      'g:\\development\\POS-Offline-Desktop-main',
      'pos_offline_desktop_database',
      'pos_offline_desktop_database.sqlite',
    ),
  ];

  String? dbPath;
  for (final path in dbPaths) {
    if (await File(path).exists()) {
      dbPath = path;
      break;
    }
  }

  if (dbPath == null) {
    debugPrint('❌ Database file not found. Run app first.');
    return;
  }

  debugPrint('Database: $dbPath');

  try {
    // Check current schema
    debugPrint('1. Checking current status column type...');
    final schema = await executeSql(dbPath, 'PRAGMA table_info(customers);');
    debugPrint(schema);

    // Fix status column type
    debugPrint('\n2. Fixing status column type...');

    // Step 1: Backup
    await executeSql(
      dbPath,
      'CREATE TABLE customers_backup AS SELECT * FROM customers;',
    );
    debugPrint('✅ Backup created');

    // Step 2: Create new table with TEXT status column
    await executeSql(dbPath, '''
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
        status TEXT NOT NULL DEFAULT 'Active',
        createdAt TEXT,
        updatedAt TEXT
      );
    ''');
    debugPrint('✅ New table created with TEXT status column');

    // Step 3: Migrate data with proper type casting
    await executeSql(dbPath, '''
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
        CASE 
          WHEN status = 1 THEN 'Active'
          WHEN status = 0 THEN 'Inactive'
          ELSE IFNULL(status, 'Active')
        END,
        IFNULL(createdAt, ''),
        IFNULL(updatedAt, '')
      FROM customers;
    ''');
    debugPrint('✅ Data migrated with status type conversion');

    // Step 4: Replace table
    await executeSql(dbPath, 'DROP TABLE customers;');
    await executeSql(dbPath, 'ALTER TABLE customers_new RENAME TO customers;');
    debugPrint('✅ Table replacement completed');

    // Step 5: Verify
    debugPrint('\n3. Verifying fix...');
    final newSchema = await executeSql(dbPath, 'PRAGMA table_info(customers);');
    debugPrint(newSchema);

    // Test insertion
    await executeSql(dbPath, '''
      INSERT INTO customers (id, name, phone, status, openingBalance, totalDebt, totalPaid, isActive)
      VALUES ('test_status_fix', 'Test Customer', '1234567890', 'Active', 0, 0, 0, 1);
    ''');
    debugPrint('✅ Test insertion with TEXT status successful');

    // Cleanup
    await executeSql(
      dbPath,
      'DELETE FROM customers WHERE id = \'test_status_fix\';',
    );
    await executeSql(dbPath, 'DROP TABLE customers_backup;');
    debugPrint('✅ Cleanup completed');

    debugPrint('\n🎉 Status column fix completed!');
    debugPrint('✅ Status column is now TEXT type');
    debugPrint('✅ Can insert "Active", "Inactive" values');
    debugPrint('\nRestart app to apply changes.');
  } catch (e) {
    debugPrint('❌ Fix failed: $e');
  }
}

Future<String> executeSql(String dbPath, String sql) async {
  final result = await Process.run('sqlite3', [dbPath, sql]);

  if (result.exitCode != 0) {
    throw Exception('SQLite command failed: ${result.stderr}\nSQL: $sql');
  }

  return result.stdout.toString();
}
