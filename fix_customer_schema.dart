import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() async {
  developer.log('🔧 Fixing customer database schema...');

  try {
    // Get database path
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(
      appDir.path,
      'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
    );

    if (!await File(dbPath).exists()) {
      developer.log('❌ Database file not found at: $dbPath');
      return;
    }

    developer.log('📍 Database path: $dbPath');

    // Check if sqlite3 is available
    final sqliteCheck = await Process.run('sqlite3', ['--version']);
    if (sqliteCheck.exitCode != 0) {
      developer.log(
        '❌ sqlite3 not available. Please install SQLite3 command line tools.',
      );
      developer.log('Download from: https://sqlite.org/download.html');
      return;
    }

    // Check current schema
    developer.log('\n🔍 Checking current schema...');
    final schemaResult = await Process.run('sqlite3', [
      dbPath,
      'PRAGMA table_info(customers);',
    ]);

    if (schemaResult.exitCode != 0) {
      developer.log('❌ Error checking schema: ${schemaResult.stderr}');
      return;
    }

    developer.log('Current customers table schema:');
    developer.log(schemaResult.stdout);

    // Check if created_at column needs fixing by parsing the output
    final output = schemaResult.stdout as String;
    final lines = output.split('\n');

    bool hasIntegerCreatedAt = false;
    for (final line in lines) {
      if (line.contains('created_at') && line.contains('INTEGER')) {
        hasIntegerCreatedAt = true;
        break;
      }
    }

    if (hasIntegerCreatedAt) {
      developer.log(
        '\n🔧 Fixing created_at column type from INTEGER to TEXT...',
      );

      // Create backup
      final backupResult = await Process.run('sqlite3', [
        dbPath,
        'CREATE TABLE customers_backup AS SELECT * FROM customers;',
      ]);

      if (backupResult.exitCode != 0) {
        developer.log('❌ Error creating backup: ${backupResult.stderr}');
        return;
      }
      developer.log('✅ Created backup table');

      // Drop original table
      final dropResult = await Process.run('sqlite3', [
        dbPath,
        'DROP TABLE customers;',
      ]);

      if (dropResult.exitCode != 0) {
        developer.log('❌ Error dropping table: ${dropResult.stderr}');
        return;
      }
      developer.log('✅ Dropped original table');

      // Recreate table with correct schema
      final createResult = await Process.run('sqlite3', [
        dbPath,
        '''
        CREATE TABLE customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          gstinNumber TEXT,
          email TEXT,
          opening_balance REAL DEFAULT 0.0,
          total_debt REAL DEFAULT 0.0,
          total_paid REAL DEFAULT 0.0,
          created_at TEXT,
          updated_at TEXT,
          notes TEXT,
          is_active INTEGER DEFAULT 1,
          status TEXT DEFAULT 'Active'
        );
        ''',
      ]);

      if (createResult.exitCode != 0) {
        developer.log('❌ Error creating table: ${createResult.stderr}');
        return;
      }
      developer.log('✅ Created table with correct schema');

      // Get backup data and convert timestamps
      final dataResult = await Process.run('sqlite3', [
        dbPath,
        'SELECT * FROM customers_backup;',
      ]);

      if (dataResult.exitCode != 0) {
        developer.log('❌ Error reading backup data: ${dataResult.stderr}');
        return;
      }

      // Parse and restore data with proper DateTime conversion
      final dataLines = (dataResult.stdout as String).split('\n');
      if (dataLines.isNotEmpty) {
        final header = dataLines.first;
        final columns = header.split('|').map((c) => c.trim()).toList();

        for (int i = 1; i < dataLines.length; i++) {
          final line = dataLines[i].trim();
          if (line.isEmpty) continue;

          final values = line.split('|').map((v) => v.trim()).toList();
          final Map<String, String> rowData = {};

          for (int j = 0; j < columns.length && j < values.length; j++) {
            rowData[columns[j]] = values[j];
          }

          // Convert Unix timestamps to ISO strings
          if (rowData.containsKey('created_at') &&
              rowData['created_at'] != null) {
            final createdAt = rowData['created_at']!;
            if (RegExp(r'^\d+$').hasMatch(createdAt)) {
              final timestamp = int.parse(createdAt);
              rowData['created_at'] = DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
              ).toIso8601String();
            }
          }

          if (rowData.containsKey('updated_at') &&
              rowData['updated_at'] != null) {
            final updatedAt = rowData['updated_at']!;
            if (RegExp(r'^\d+$').hasMatch(updatedAt)) {
              final timestamp = int.parse(updatedAt);
              rowData['updated_at'] = DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
              ).toIso8601String();
            }
          }

          // Build INSERT statement
          final insertColumns = rowData.keys.join(', ');
          final insertValues = rowData.values
              .map((v) => "'${v.replaceAll("'", "''")}'")
              .join(', ');

          final insertResult = await Process.run('sqlite3', [
            dbPath,
            "INSERT INTO customers ($insertColumns) VALUES ($insertValues);",
          ]);

          if (insertResult.exitCode != 0) {
            developer.log('❌ Error inserting data: ${insertResult.stderr}');
            continue;
          }
        }
      }

      // Drop backup
      final cleanupResult = await Process.run('sqlite3', [
        dbPath,
        'DROP TABLE customers_backup;',
      ]);

      if (cleanupResult.exitCode != 0) {
        developer.log('❌ Error dropping backup: ${cleanupResult.stderr}');
        return;
      }
      developer.log('✅ Restored data with correct DateTime format');

      developer.log('\n🎉 Customer schema fixed successfully!');
    } else {
      developer.log('\n✅ created_at column already has correct type');
    }

    // Verify final schema
    developer.log('\n🔍 Final schema verification:');
    final finalResult = await Process.run('sqlite3', [
      dbPath,
      'PRAGMA table_info(customers);',
    ]);

    if (finalResult.exitCode == 0) {
      developer.log(finalResult.stdout);
    } else {
      developer.log('❌ Error verifying schema: ${finalResult.stderr}');
    }
  } catch (e) {
    developer.log('❌ Error fixing schema: $e');
    developer.log('Stack trace: ${StackTrace.current}');
  }
}
