import 'dart:io';
import 'dart:developer' as developer;

Future<void> main() async {
  developer.log('=== Standalone Database Population ===');

  try {
    // Find database file in common locations
    final locations = [
      'pos_offline_desktop_database.sqlite',
      'database/pos_offline_desktop_database.sqlite',
      'data/pos_offline_desktop_database.sqlite',
    ];

    String? dbPath;

    for (final location in locations) {
      final file = File(location);
      if (await file.exists()) {
        dbPath = file.path;
        developer.log('✓ Found database at: ${file.path}');
        break;
      }
    }

    if (dbPath == null) {
      developer.log('❌ Database file not found in any location');
      developer.log('Checked locations:');
      for (final location in locations) {
        developer.log('  - $location');
      }
      return;
    }

    developer.log('Using database: $dbPath');
    developer.log(
      'Note: This is a simplified version that only checks for database files.',
    );
    developer.log(
      'For actual database operations, use the full populate_test_data.dart script.',
    );

    developer.log('\n=== Standalone Population Complete ===');
  } catch (e, stackTrace) {
    developer.log('❌ Error: $e');
    developer.log('Stack trace: $stackTrace');
  }
}
