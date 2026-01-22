import 'dart:io';
import 'dart:developer' as developer;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

Future<void> main() async {
  developer.log('=== Database Migration Test ===');

  try {
    // Initialize database
    final db = await _initializeDatabase();

    // Test basic connection
    await db.customSelect('SELECT 1 as test').get();
    developer.log('✓ Database connection test passed');

    // Check database schema version
    developer.log('Current database version: ${db.schemaVersion}');

    // Check if invoices table exists and has correct columns
    developer.log('\n=== Checking Invoices Table ===');
    try {
      final invoiceSchema = await db.customSelect('''
        PRAGMA table_info(invoices)
      ''').get();

      if (invoiceSchema.isNotEmpty) {
        developer.log('✓ Invoices table exists');
        for (final row in invoiceSchema) {
          developer.log('  Column: ${row.read('name')}');
        }
      } else {
        developer.log('❌ Invoices table not found');
      }
    } catch (e) {
      developer.log('❌ Error checking invoices table: $e');
    }

    // Check if customers table exists and has correct columns
    developer.log('\n=== Checking Customers Table ===');
    try {
      final customerSchema = await db.customSelect('''
        PRAGMA table_info(customers)
      ''').get();

      if (customerSchema.isNotEmpty) {
        developer.log('✓ Customers table exists');
        for (final row in customerSchema) {
          developer.log('  Column: ${row.read('name')}');
        }
      } else {
        developer.log('❌ Customers table not found');
      }
    } catch (e) {
      developer.log('❌ Error checking customers table: $e');
    }

    // Check if products table exists
    developer.log('\n=== Checking Products Table ===');
    try {
      final productSchema = await db.customSelect('''
        PRAGMA table_info(products)
      ''').get();

      if (productSchema.isNotEmpty) {
        developer.log('✓ Products table exists');
        for (final row in productSchema) {
          developer.log('  Column: ${row.read('name')}');
        }
      } else {
        developer.log('❌ Products table not found');
      }
    } catch (e) {
      developer.log('❌ Error checking products table: $e');
    }

    // Test a simple query to make sure basic operations work
    developer.log('\n=== Testing Basic Query ===');
    try {
      final result = await db
          .customSelect('SELECT COUNT(*) as count FROM invoices')
          .get();
      developer.log('Invoice count: ${result.first.read<int>('count')}');
    } catch (e) {
      developer.log('❌ Error in basic query: $e');
    }

    await db.close();
    developer.log('\n✓ Database migration test completed');
  } catch (e, stackTrace) {
    developer.log('❌ Fatal error: $e');
    developer.log('Stack trace: $stackTrace');
  }
}

Future<AppDatabase> _initializeDatabase() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbDir = Directory(
    p.join(dbFolder.path, 'pos_offline_desktop_database'),
  );

  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }

  final file = File(p.join(dbDir.path, 'pos_offline_desktop_database.sqlite'));
  developer.log('Database path: ${file.path}');

  return AppDatabase(NativeDatabase(file));
}
