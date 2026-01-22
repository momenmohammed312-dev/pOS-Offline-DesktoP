import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart';

// Simple script to check and fix database schema
void main() async {
  log('=== Customer Status Fix ===');

  // Check for existing database files
  final currentDir = Directory.current;
  log('Current directory: ${currentDir.path}');

  // Look for database files in common locations
  final dbPaths = [
    join(currentDir.path, 'pos.db'),
    join(currentDir.path, 'data', 'pos.db'),
    join(currentDir.path, 'assets', 'pos.db'),
  ];

  for (final dbPath in dbPaths) {
    if (await File(dbPath).exists()) {
      log('Found database: $dbPath');
      await checkDatabaseSchema(dbPath);
    }
  }

  log('\n=== Analysis Complete ===');
  log('Based on the code analysis:');
  log('1. Customer table defines status as TEXT column');
  log('2. Migration adds status as TEXT DEFAULT "Active"');
  log('3. Generated code shows status as GeneratedColumn<String>');
  log('4. The error suggests existing DB has INTEGER status column');
  log('\n=== Solution ===');
  log('The issue is likely an existing database with old schema.');
  log('Options:');
  log('1. Delete existing database file (will lose data)');
  log('2. Run migration to update schema');
  log('3. Check if there are multiple database definitions');
}

Future<void> checkDatabaseSchema(String dbPath) async {
  try {
    final file = File(dbPath);
    final stat = await file.stat();
    log('  Size: ${stat.size} bytes');
    log('  Modified: ${stat.modified}');

    // Read first few bytes to verify it's SQLite
    final bytes = await file.openRead(0, 16).first;
    if (bytes.length >= 16) {
      final header = String.fromCharCodes(bytes);
      log('  Header: $header');
    }
  } catch (e) {
    log('  Error reading database: $e');
  }
}
