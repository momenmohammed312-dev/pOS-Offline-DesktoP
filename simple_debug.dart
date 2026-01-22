import 'dart:io';
import 'package:drift/native.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  developer.log('=== Simple Database Debug ===');

  try {
    // Find database file
    final dbPath = 'pos_database.db';
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      developer.log('Database file not found at: $dbPath');

      // Check common locations
      final locations = [
        'database/pos_database.db',
        'data/pos_database.db',
        '../pos_database.db',
      ];

      for (final location in locations) {
        final file = File(location);
        if (await file.exists()) {
          developer.log('Found database at: $location');
          break;
        }
      }
      return;
    }

    developer.log('Database file found: ${dbFile.path}');
    developer.log('Database size: ${await dbFile.length()} bytes');

    // Initialize database connection
    final db = AppDatabase(NativeDatabase(dbFile));

    // Test basic connection
    final test = await db.customSelect('SELECT 1 as test').get();
    developer.log('Database connection test: ${test.first.read<int>('test')}');

    // Check table structure
    developer.log('\n=== Table Structure ===');
    final tables = await db.customSelect('''
      SELECT name FROM sqlite_master 
      WHERE type='table' 
      ORDER BY name
    ''').get();

    developer.log('Available tables:');
    for (final table in tables) {
      developer.log('  - ${table.read<String>('name')}');
    }

    // Check data in key tables
    developer.log('\n=== Data Count ===');

    final counts = await db.customSelect('''
      SELECT 
        'invoices' as table_name,
        COUNT(*) as count
      FROM invoices
      UNION ALL
      SELECT 
        'customers' as table_name,
        COUNT(*) as count
      FROM customers
      UNION ALL
      SELECT 
        'products' as table_name,
        COUNT(*) as count
      FROM products
      UNION ALL
      SELECT 
        'invoice_items' as table_name,
        COUNT(*) as count
      FROM invoice_items
    ''').get();

    for (final count in counts) {
      developer.log(
        '  ${count.read<String>('table_name')}: ${count.read<int>('count')} records',
      );
    }

    // Sample data
    developer.log('\n=== Sample Invoice Data ===');
    final sampleInvoices = await db.customSelect('''
      SELECT 
        id,
        invoiceNumber,
        customerName,
        customerContact,
        totalAmount,
        paidAmount,
        date,
        paymentMethod
      FROM invoices 
      LIMIT 3
    ''').get();

    if (sampleInvoices.isEmpty) {
      developer.log('No invoices found in database');
    } else {
      for (final invoice in sampleInvoices) {
        developer.log('Invoice ${invoice.read<String>('id')}:');
        developer.log('  Number: ${invoice.read<String>('invoiceNumber')}');
        developer.log('  Customer: ${invoice.read<String>('customerName')}');
        developer.log('  Contact: ${invoice.read<String>('customerContact')}');
        developer.log('  Total: ${invoice.read<double>('totalAmount')}');
        developer.log('  Paid: ${invoice.read<double>('paidAmount')}');
        developer.log('  Date: ${invoice.read<DateTime>('date')}');
        developer.log('  Payment: ${invoice.read<String>('paymentMethod')}');
        developer.log('');
      }
    }

    await db.close();
  } catch (e, stackTrace) {
    developer.log('Error: $e');
    developer.log('Stack trace: $stackTrace');
  }
}
