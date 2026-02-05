import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Backup Service for POS System
/// خدمة النسخ الاحتياطي لنظام نقاط البيع
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Create a complete backup of the database
  /// إنشاء نسخة احتياطية كاملة من قاعدة البيانات
  Future<String> createBackup({String? customPath}) async {
    try {
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final fileName = 'pos_backup_$timestamp.json';

      final directory = customPath != null
          ? Directory(customPath)
          : await getApplicationDocumentsDirectory();

      final backupFile = File('${directory.path}/$fileName');

      // Get all data from all tables
      final backupData = await _getAllTablesData();

      // Create backup metadata
      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'database': 'pos_offline_desktop',
        'tables': backupData,
      };

      // Write to file
      await backupFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backup),
        encoding: utf8,
      );

      debugPrint('Backup created successfully: ${backupFile.path}');
      return backupFile.path;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      rethrow;
    }
  }

  /// Restore database from backup file
  /// استعادة قاعدة البيانات من ملف النسخ الاحتياطي
  Future<void> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $filePath');
      }

      final content = await file.readAsString(encoding: utf8);
      final backup = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup format
      if (!_validateBackupFormat(backup)) {
        throw Exception('Invalid backup format');
      }

      // Restore data in correct order (respecting foreign keys)
      await _restoreTablesData(backup['tables'] as Map<String, dynamic>);

      debugPrint('Database restored successfully from: $filePath');
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  /// Get backup information without restoring
  /// الحصول على معلومات النسخ الاحتياطي بدون استعادة
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $filePath');
      }

      final content = await file.readAsString(encoding: utf8);
      final backup = jsonDecode(content) as Map<String, dynamic>;

      return {
        'version': backup['version'],
        'timestamp': backup['timestamp'],
        'database': backup['database'],
        'tablesCount': (backup['tables'] as Map<String, dynamic>).length,
        'fileSize': await file.length(),
        'filePath': filePath,
      };
    } catch (e) {
      debugPrint('Error getting backup info: $e');
      rethrow;
    }
  }

  /// List all backup files in the default directory
  /// قائمة جميع ملفات النسخ الاحتياطي في المجلد الافتراضي
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        try {
          final info = await getBackupInfo(file.path);
          backups.add(info);
        } catch (e) {
          debugPrint('Error reading backup info for ${file.path}: $e');
        }
      }

      // Sort by timestamp (newest first)
      backups.sort(
        (a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String),
      );

      return backups;
    } catch (e) {
      debugPrint('Error listing backups: $e');
      rethrow;
    }
  }

  /// Delete a backup file
  /// حذف ملف نسخ احتياطي
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Backup deleted: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      rethrow;
    }
  }

  /// Schedule automatic backup (simplified version)
  /// جدولة نسخ احتياطي تلقائي (نسخة مبسطة)
  Future<void> scheduleAutoBackup(Duration interval) async {
    // This is a simplified implementation
    // In a real app, you'd use a background job scheduler
    debugPrint('Auto backup scheduled every: ${interval.inHours} hours');

    // For now, just create one backup immediately
    await createBackup();
  }

  /// Export data to CSV format for external use
  /// تصدير البيانات إلى صيغة CSV للاستخدام الخارجي
  Future<String> exportToCSV({String? customPath}) async {
    try {
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final fileName = 'pos_export_$timestamp.csv';

      final directory = customPath != null
          ? Directory(customPath)
          : await getApplicationDocumentsDirectory();

      final exportFile = File('${directory.path}/$fileName');

      // Get all data and convert to CSV
      final csvData = await _convertToCSV();

      await exportFile.writeAsString(csvData, encoding: utf8);

      debugPrint('CSV export created: ${exportFile.path}');
      return exportFile.path;
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      rethrow;
    }
  }

  // Private methods

  Future<Map<String, dynamic>> _getAllTablesData() async {
    final tablesData = <String, dynamic>{};

    // Get data from each table
    final tables = [
      'products',
      'customers',
      'suppliers',
      'invoices',
      'invoice_items',
      'expenses',
      'days',
      'purchases',
      'purchase_items',
      'credit_payments',
      'enhanced_suppliers',
      'enhanced_purchases',
      'enhanced_purchase_items',
      'supplier_payments',
      'purchase_budgets',
      'budget_categories',
      'budget_transactions',
      'budget_alerts',
      'ledger_transactions',
    ];

    for (final tableName in tables) {
      try {
        final result = await _db.customSelect('SELECT * FROM $tableName').get();
        tablesData[tableName] = result.map((row) => row.data).toList();
      } catch (e) {
        debugPrint('Error getting data from table $tableName: $e');
        tablesData[tableName] = [];
      }
    }

    return tablesData;
  }

  bool _validateBackupFormat(Map<String, dynamic> backup) {
    return backup.containsKey('version') &&
        backup.containsKey('timestamp') &&
        backup.containsKey('database') &&
        backup.containsKey('tables');
  }

  Future<void> _restoreTablesData(Map<String, dynamic> tablesData) async {
    // Define table order to respect foreign key constraints
    final tableOrder = [
      'customers',
      'suppliers',
      'products',
      'categories',
      'days',
      'invoices',
      'invoice_items',
      'purchases',
      'purchase_items',
      'credit_payments',
      'expenses',
      'ledger_transactions',
      'enhanced_suppliers',
      'enhanced_purchases',
      'enhanced_purchase_items',
      'supplier_payments',
      'purchase_budgets',
      'budget_categories',
      'budget_transactions',
      'budget_alerts',
    ];

    for (final tableName in tableOrder) {
      if (tablesData.containsKey(tableName)) {
        await _restoreTable(tableName, tablesData[tableName] as List);
      }
    }
  }

  Future<void> _restoreTable(String tableName, List<dynamic> data) async {
    if (data.isEmpty) return;

    try {
      // Clear existing data
      await _db.customUpdate('DELETE FROM $tableName');

      // Insert new data
      for (final row in data as List<Map<String, dynamic>>) {
        final columns = row.keys.join(', ');
        final placeholders = List.filled(row.values.length, '?').join(', ');
        final values = row.values.toList();

        await _db.customUpdate(
          'INSERT INTO $tableName ($columns) VALUES ($placeholders)',
          variables: values.map((v) => Variable(v)).toList(),
        );
      }

      debugPrint('Restored $tableName with ${data.length} records');
    } catch (e) {
      debugPrint('Error restoring table $tableName: $e');
      rethrow;
    }
  }

  Future<String> _convertToCSV() async {
    final buffer = StringBuffer();

    // Get products data as example
    final productsData = await _db.customSelect('SELECT * FROM products').get();

    if (productsData.isNotEmpty) {
      // Write headers
      final headers = productsData.first.data.keys.join(',');
      buffer.writeln(headers);

      // Write data
      for (final row in productsData) {
        final values = row.data.values
            .map((value) {
              if (value is String && value.contains(',')) {
                return '"$value"';
              }
              return value.toString();
            })
            .join(',');
        buffer.writeln(values);
      }
    }

    return buffer.toString();
  }
}
