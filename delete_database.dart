import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Development fix: Delete existing database to resolve schema mismatch
/// This will create a fresh database with correct TEXT status column
Future<void> deleteDevelopmentDatabase() async {
  try {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = Directory(
      p.join(dbFolder.path, 'pos_offline_desktop_database'),
    );
    final dbFile = File(
      p.join(dbDir.path, 'pos_offline_desktop_database.sqlite'),
    );

    if (await dbFile.exists()) {
      log('Deleting existing database: ${dbFile.path}');
      await dbFile.delete();
      log('✅ Database deleted successfully');
    } else {
      log('Database file does not exist');
    }
  } catch (e) {
    log('Error deleting database: $e');
  }
}

void main() {
  log('=== POS Database Deletion Tool ===');
  log(
    'This will delete the existing database to fix the customer status datatype mismatch.',
  );
  log(
    'A fresh database will be created on next app start with correct schema.',
  );
  log('');

  deleteDevelopmentDatabase();
}
