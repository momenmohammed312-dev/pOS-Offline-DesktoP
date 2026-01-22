import 'dart:io';
import 'dart:developer' as developer;

void main() async {
  developer.log('🔍 Quick Database Check');

  try {
    // Try to find the database in common locations
    final paths = [
      '${Platform.environment['USERPROFILE']}\\Documents\\pos_offline_desktop_database\\pos_offline_desktop_database.sqlite',
      '${Platform.environment['APPDATA']}\\pos_offline_desktop_database\\pos_offline_desktop_database.sqlite',
      'pos_offline_desktop_database.sqlite',
    ];

    String? dbPath;
    for (final path in paths) {
      if (await File(path).exists()) {
        dbPath = path;
        break;
      }
    }

    if (dbPath == null) {
      developer.log('❌ Database not found in common locations');
      return;
    }

    developer.log('✅ Found database at: $dbPath');

    // Check if sqlite3 is available
    final sqliteCheck = await Process.run('sqlite3', ['--version']);
    if (sqliteCheck.exitCode != 0) {
      developer.log('❌ sqlite3 not available');
      return;
    }

    // Check table structure
    final result = await Process.run('sqlite3', [
      dbPath,
      'PRAGMA table_info(customers);',
    ]);

    if (result.exitCode == 0) {
      developer.log('📋 Customers table structure:');
      developer.log(result.stdout.toString());

      final tableInfo = result.stdout.toString();

      // Check for required columns
      final requiredColumns = [
        'id',
        'name',
        'phone',
        'created_at',
        'updated_at',
      ];
      for (final column in requiredColumns) {
        if (tableInfo.contains(column)) {
          developer.log('✅ $column column exists');
        } else {
          developer.log('❌ $column column missing');
        }
      }
    } else {
      developer.log('❌ Failed to check table: ${result.stderr}');
    }
  } catch (e) {
    developer.log('❌ Error: $e');
  }
}
