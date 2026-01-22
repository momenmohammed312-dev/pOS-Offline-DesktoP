import 'dart:io' show File;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Utility to find the actual database file path used by the app
/// Run this to get the exact path for manual deletion
void main() async {
  debugPrint('=== Finding Actual Database Path ===\n');

  try {
    // Get the same path as used in AppDatabase
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(
      dbFolder.path,
      'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
    );

    debugPrint('App Database Path:');
    debugPrint(dbPath);
    debugPrint('');

    // Check if file exists
    final dbFile = File(dbPath);
    debugPrint('Database exists: ${await dbFile.exists()}');

    if (await dbFile.exists()) {
      debugPrint('\n✅ SOLUTION: Delete this file to fix datatype mismatch:');
      debugPrint('1. Close the Flutter app completely');
      debugPrint('2. Delete: $dbPath');
      debugPrint('3. Restart the app');
      debugPrint('4. App will recreate database with correct schema');
    } else {
      debugPrint('\n❌ Database file not found at expected location');
      debugPrint('Run the app first to create the database');
    }
  } catch (e) {
    debugPrint('❌ Error: $e');
    debugPrint('Make sure path_provider is available');
  }
}
