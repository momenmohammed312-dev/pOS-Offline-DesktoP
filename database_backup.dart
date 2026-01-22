import 'dart:io';
import 'dart:developer' as developer;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:drift/native.dart';

/// Emergency database backup and migration utility
class DatabaseBackup {
  static Future<void> backupDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(
        dbFolder.path,
        'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
      );
      final backupPath = '$dbPath.bak';

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        developer.log('✅ Database backed up to: $backupPath');
      } else {
        developer.log('⚠️ Database file not found at: $dbPath');
      }
    } catch (e) {
      developer.log('❌ Backup failed: $e');
    }
  }

  static Future<void> runEmergencyMigration() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(
        dbFolder.path,
        'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
      );

      // Use existing database connection with proper type
      final db = AppDatabase(DatabaseConnection(NativeDatabase(File(dbPath))));

      // Check if created_at column exists
      final tableInfo = await db
          .customSelect("PRAGMA table_info(customers)")
          .get();
      final hasCreatedAtColumn = tableInfo.any(
        (row) => row.data['name'] == 'created_at',
      );

      if (!hasCreatedAtColumn) {
        developer.log('🔧 Adding created_at column to customers table...');

        // Option A: Integer epoch seconds (recommended)
        await db.customStatement(
          'ALTER TABLE customers ADD COLUMN created_at INTEGER',
        );
        await db.customStatement(
          "UPDATE customers SET created_at = CAST(strftime('%s','now') AS INTEGER) WHERE created_at IS NULL",
        );

        developer.log('✅ created_at column added and populated');
      } else {
        developer.log('✅ created_at column already exists');
      }

      // Also ensure phone column exists
      final hasPhoneColumn = tableInfo.any(
        (row) => row.data['name'] == 'phone',
      );
      if (!hasPhoneColumn) {
        await db.customStatement('ALTER TABLE customers ADD COLUMN phone TEXT');
        developer.log('✅ phone column added');
      }

      await db.close();
      developer.log('✅ Emergency migration completed successfully');
    } catch (e) {
      developer.log('❌ Emergency migration failed: $e');
    }
  }

  static Future<void> checkSchema() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(
        dbFolder.path,
        'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
      );

      final db = AppDatabase(DatabaseConnection(NativeDatabase(File(dbPath))));

      // Get table info
      final tableInfo = await db
          .customSelect("PRAGMA table_info(customers)")
          .get();

      developer.log('📋 Customers table schema:');
      for (final row in tableInfo) {
        developer.log('  - ${row.data['name']} (${row.data['type']})');
      }

      await db.close();
    } catch (e) {
      developer.log('❌ Schema check failed: $e');
    }
  }
}
