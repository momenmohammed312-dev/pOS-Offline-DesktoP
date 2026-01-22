import 'dart:io';
import 'dart:developer' as developer;

Future<void> main() async {
  developer.log('=== Simple Database Test ===');

  try {
    // Check database file exists
    final dbPath = 'pos_offline_desktop_database.sqlite';
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      developer.log('✓ Database file exists at: ${dbFile.path}');
      developer.log('File size: ${await dbFile.length()} bytes');

      // Try to open as raw bytes to check if it's a valid SQLite database
      final bytes = await dbFile.readAsBytes();
      developer.log(
        'Database header bytes: ${bytes.take(16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      // Check if it starts with SQLite header
      final header = String.fromCharCodes(bytes);
      developer.log(
        'SQLite header check: ${header.startsWith('SQLite format 3') ? 'Valid SQLite' : 'Not SQLite'}',
      );
    } else {
      developer.log('❌ Database file not found at: $dbPath');

      // Check common locations
      final locations = [
        'pos_offline_desktop_database.sqlite',
        'database/pos_offline_desktop_database.sqlite',
        'data/pos_offline_desktop_database.sqlite',
      ];

      for (final location in locations) {
        final file = File(location);
        if (await file.exists()) {
          developer.log('✓ Found database at: ${file.path}');
          break;
        }
      }
    }
  } catch (e, stackTrace) {
    developer.log('❌ Error: $e');
    developer.log('Stack trace: $stackTrace');
  }
}
