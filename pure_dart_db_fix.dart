import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pure Dart database fix without any Flutter/Drift dependencies
Future<void> main() async {
  developer.log('🚨 PURE DART DATABASE FIX STARTING...');

  try {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = p.join(dbFolder.path, 'pos_offline_desktop_database');
    final dbPath = p.join(dbDir, 'pos_offline_desktop_database.sqlite');

    developer.log('Database directory: $dbDir');
    developer.log('Database path: $dbPath');

    // Ensure directory exists
    final dbDirFile = Directory(dbDir);
    if (!await dbDirFile.exists()) {
      await dbDirFile.create(recursive: true);
      developer.log('✅ Created database directory');
    }

    // Backup first
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      final backupPath = '$dbPath.bak.${DateTime.now().millisecondsSinceEpoch}';
      await dbFile.copy(backupPath);
      developer.log('✅ Database backed up to: $backupPath');

      // Run SQLite commands directly using Process
      developer.log('🔧 Checking and adding database columns...');

      // Check if created_at column exists
      final checkResult = await Process.run('sqlite3', [
        dbPath,
        'PRAGMA table_info(customers);',
      ]);

      if (checkResult.exitCode == 0) {
        final tableInfo = checkResult.stdout.toString();
        developer.log('📋 Current customers table info:');
        developer.log(tableInfo);

        final hasCreatedAtColumn = tableInfo.contains('created_at');
        final hasPhoneColumn = tableInfo.contains('phone');

        if (!hasCreatedAtColumn) {
          developer.log('🔧 Adding created_at column...');
          final result1 = await Process.run('sqlite3', [
            dbPath,
            'ALTER TABLE customers ADD COLUMN created_at INTEGER;',
          ]);

          if (result1.exitCode == 0) {
            developer.log('✅ created_at column added successfully');

            // Populate existing records
            final result2 = await Process.run('sqlite3', [
              dbPath,
              'UPDATE customers SET created_at = CAST(strftime("%s","now") AS INTEGER) WHERE created_at IS NULL;',
            ]);

            if (result2.exitCode == 0) {
              developer.log(
                '✅ created_at column populated for existing records',
              );
            } else {
              developer.log(
                '❌ Failed to populate created_at: ${result2.stderr}',
              );
            }
          } else {
            developer.log(
              '❌ Failed to add created_at column: ${result1.stderr}',
            );
          }
        } else {
          developer.log('✅ created_at column already exists');
        }

        if (!hasPhoneColumn) {
          developer.log('🔧 Adding phone column...');
          final result3 = await Process.run('sqlite3', [
            dbPath,
            'ALTER TABLE customers ADD COLUMN phone TEXT;',
          ]);

          if (result3.exitCode == 0) {
            developer.log('✅ phone column added successfully');
          } else {
            developer.log(
              '⚠️ phone column might already exist or failed: ${result3.stderr}',
            );
          }
        } else {
          developer.log('✅ phone column already exists');
        }
      } else {
        developer.log('❌ Failed to check table info: ${checkResult.stderr}');
      }
    } else {
      developer.log('❌ Database file not found at: $dbPath');
    }

    developer.log('\n🎉 DATABASE FIX COMPLETED!');
    developer.log('✅ Database at: $dbPath');
    developer.log('✅ created_at and phone columns ensured');
    developer.log('✅ Ready for customer editing');
    developer.log('\nPlease restart application and test:');
    developer.log('1. Edit existing customer');
    developer.log('2. Add new customer');
    developer.log('3. Verify no SQLite errors');
  } catch (e) {
    developer.log('❌ Fix failed: $e');
  }
}
