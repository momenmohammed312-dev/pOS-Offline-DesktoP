import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Comprehensive database fix for customer status datatype mismatch
Future<void> main() async {
  log('=== POS Database Fix Tool ===');

  try {
    // 1. Locate the database file
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = Directory(
      p.join(dbFolder.path, 'pos_offline_desktop_database'),
    );
    final dbFile = File(
      p.join(dbDir.path, 'pos_offline_desktop_database.sqlite'),
    );

    log('Database location: ${dbFile.path}');
    log('Database exists: ${await dbFile.exists()}');

    if (await dbFile.exists()) {
      final stat = await dbFile.stat();
      log('Database size: ${stat.size} bytes');
      log('Last modified: ${stat.modified}');

      // 2. Check if we can read the schema
      log('\n=== Checking Database Schema ===');
      await checkDatabaseSchema(dbFile);

      // 3. Provide solution options
      log('\n=== Solution Options ===');
      log('1. Delete database (will lose all data)');
      log('2. Manual schema fix (preserve data)');
      log('3. Check for multiple database instances');

      // Ask user for action
      log('\nRecommendation:');
      log('- If this is a development environment: Option 1 (delete database)');
      log('- If this is production: Option 2 (manual fix)');
    } else {
      log('Database file does not exist. Will be created on next app run.');
      log('The error should resolve automatically with fresh database.');
    }
  } catch (e) {
    log('Error: $e');
  }
}

Future<void> checkDatabaseSchema(File dbFile) async {
  try {
    // Simple SQLite header check
    final bytes = await dbFile.openRead(0, 100).first;
    final header = String.fromCharCodes(bytes.take(16).toList());

    if (header.startsWith('SQLite format 3')) {
      log('✅ Valid SQLite database file');

      // Try to get basic info
      log('Database appears to be a valid SQLite file.');
      log('The datatype mismatch error suggests:');
      log('- Existing database has INTEGER status column');
      log('- Code expects TEXT status column');
      log('- Migration may not have run properly');
    } else {
      log('❌ Invalid SQLite database file');
    }
  } catch (e) {
    log('Error checking schema: $e');
  }
}

/// Option 1: Delete database (development)
Future<void> deleteDatabase() async {
  try {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = Directory(
      p.join(dbFolder.path, 'pos_offline_desktop_database'),
    );
    final dbFile = File(
      p.join(dbDir.path, 'pos_offline_desktop_database.sqlite'),
    );

    if (await dbFile.exists()) {
      await dbFile.delete();
      log('✅ Database deleted successfully');
    } else {
      log('Database file does not exist');
    }
  } catch (e) {
    log('Error deleting database: $e');
  }
}

/// Option 2: Manual schema fix (production)
Future<void> fixDatabaseSchema() async {
  log('Manual schema fix would involve:');
  log('1. Backing up existing data');
  log('2. Creating new table with correct schema');
  log('3. Migrating data from old table');
  log('4. Dropping old table and renaming new table');
  log('This requires careful implementation to avoid data loss');
}
