import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Simple database fix without Flutter dependencies
void main() async {
  developer.log('🚨 SIMPLE DATABASE FIX STARTING...');

  try {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(
      dbFolder.path,
      'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
    );

    // Backup first
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      final backupPath = '$dbPath.bak.${DateTime.now().millisecondsSinceEpoch}';
      await dbFile.copy(backupPath);
      developer.log('✅ Database backed up to: $backupPath');

      // Run SQLite commands directly
      final result = await Process.run('sqlite3', [
        dbPath,
        'ALTER TABLE customers ADD COLUMN created_at INTEGER;',
      ]);

      if (result.exitCode == 0) {
        developer.log('✅ created_at column added successfully');

        // Populate existing records
        final result2 = await Process.run('sqlite3', [
          dbPath,
          'UPDATE customers SET created_at = CAST(strftime("%s","now") AS INTEGER) WHERE created_at IS NULL;',
        ]);

        if (result2.exitCode == 0) {
          developer.log('✅ created_at column populated for existing records');
        } else {
          developer.log('❌ Failed to populate created_at: ${result2.stderr}');
        }
      } else {
        developer.log(
          '⚠️ created_at column might already exist or sqlite3 not available',
        );
        developer.log('Error: ${result.stderr}');
      }

      // Also try to add phone column
      final result3 = await Process.run('sqlite3', [
        dbPath,
        'ALTER TABLE customers ADD COLUMN phone TEXT;',
      ]);

      if (result3.exitCode == 0) {
        developer.log('phone column added successfully');
      } else {
        developer.log('⚠️ phone column might already exist');
      }
    } else {
      developer.log('Database directory: ${dbFolder.path}');
      developer.log('Database path: $dbPath');
    }

    developer.log('\n🎉 DATABASE FIX COMPLETED!');
    developer.log('Please restart the application and test customer editing.');
  } catch (e) {
    developer.log('❌ Fix failed: $e');
  }
}
