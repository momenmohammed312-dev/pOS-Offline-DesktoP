import 'dart:io';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_database.dart';
import '../../config/database_config.dart';
import '../../services/database_migration_service.dart';

class DatabaseSingleton {
  static AppDatabase? _instance;
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  static Future<AppDatabase> getInstance() async {
    // Return existing instance if already initialized
    if (_instance != null && _isInitialized) {
      return _instance!;
    }

    // Wait if another thread is initializing
    while (_isInitializing) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    // Double-check after waiting
    if (_instance != null && _isInitialized) {
      return _instance!;
    }

    // Start initialization
    _isInitializing = true;
    try {
      // Run migration first if needed
      await DatabaseMigrationService.migrateToEncrypted();

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbDir = Directory(
        p.join(dbFolder.path, 'pos_offline_desktop_database'),
      );

      // Ensure the directory exists
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }

      final file = File(p.join(dbDir.path, DatabaseConfig.databaseName));

      // For now, use NativeDatabase - will be updated to SQLCipher after package install
      _instance = AppDatabase(NativeDatabase(file));
      _isInitialized = true;
      return _instance!;
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
      _isInitialized = false;
    }
  }

  static bool get isInitialized => _isInitialized;
}
