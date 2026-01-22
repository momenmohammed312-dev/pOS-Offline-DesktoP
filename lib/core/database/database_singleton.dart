import 'dart:io';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_database.dart';

class DatabaseSingleton {
  static AppDatabase? _instance;
  static bool _isInitialized = false;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null && _isInitialized) {
      return _instance!;
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final dbDir = Directory(
      p.join(dbFolder.path, 'pos_offline_desktop_database'),
    );

    // Ensure the directory exists
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final file = File(
      p.join(dbDir.path, 'pos_offline_desktop_database.sqlite'),
    );

    _instance = AppDatabase(NativeDatabase(file));
    _isInitialized = true;
    return _instance!;
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
