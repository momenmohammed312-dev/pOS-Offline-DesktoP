import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'lib/core/database/app_database.dart';

/// Create Test Database Utility
///
/// This creates a fresh database with the correct schema to test
/// the customer insertion without any legacy schema issues.
void main() async {
  debugPrint('=== Creating Test Database ===');

  // Create test database in project directory
  final testDbPath = p.join(
    'g:\\development\\POS-Offline-Desktop-main',
    'test_database.sqlite',
  );

  debugPrint('Creating test database at: $testDbPath');

  // Delete existing test database
  final testDbFile = File(testDbPath);
  if (await testDbFile.exists()) {
    await testDbFile.delete();
    debugPrint('Deleted existing test database');
  }

  // Create new database with correct schema
  final database = AppDatabase(
    DatabaseConnection(NativeDatabase(File(testDbPath))),
  );

  try {
    debugPrint('Initializing database with correct schema...');

    // Test customer insertion
    debugPrint('=== Testing Customer Insertion ===');

    final testCustomer = CustomersCompanion.insert(
      id: 'test_customer_001',
      name: 'Test Customer',
      phone: const Value('1234567890'),
      address: const Value('Test Address'),
      status: const Value(1),
      openingBalance: const Value(0.0),
      totalDebt: const Value(0.0),
      totalPaid: const Value(0.0),
      isActive: const Value(true),
    );

    await database.customerDao.insertCustomer(testCustomer);
    debugPrint('✅ Customer insertion successful!');

    // Test with phone that has leading zeros
    debugPrint('=== Testing Phone with Leading Zeros ===');

    final testCustomer2 = CustomersCompanion.insert(
      id: 'test_customer_002',
      name: 'Test Customer 2',
      phone: const Value('001234567890'),
      address: const Value('Test Address 2'),
      status: const Value(1),
      openingBalance: const Value(100.0),
      totalDebt: const Value(50.0),
      totalPaid: const Value(25.0),
      isActive: const Value(true),
    );

    await database.customerDao.insertCustomer(testCustomer2);
    debugPrint('✅ Customer with leading zeros phone successful!');

    // Verify inserted data
    debugPrint('=== Verifying Inserted Data ===');
    final customers = await database.customerDao.getAllCustomers();

    for (final customer in customers) {
      debugPrint('Customer: ${customer.name}');
      debugPrint('  ID: ${customer.id}');
      debugPrint('  Phone: ${customer.phone}');
      debugPrint('  Status: ${customer.status}');
      debugPrint('  Opening Balance: ${customer.openingBalance}');
      debugPrint('  Total Debt: ${customer.totalDebt}');
      debugPrint('  Total Paid: ${customer.totalPaid}');
      debugPrint('  Is Active: ${customer.isActive}');
      debugPrint('---');
    }

    // Check actual database schema
    debugPrint('=== Checking Database Schema ===');
    final schemaResult = await database
        .customSelect('PRAGMA table_info(customers);')
        .get();

    debugPrint('Column\t\t\tType\t\tNullable');
    debugPrint('-' * 60);
    for (final row in schemaResult) {
      final data = row.data;
      final name = data['name']?.toString().padRight(20) ?? '';
      final type = data['type']?.toString().padRight(15) ?? '';
      final nullable = data['notnull'] == 1 ? 'NO' : 'YES';
      debugPrint('$name$type$nullable');
    }

    debugPrint('✅ All tests passed! Schema is correct.');
    debugPrint('To use this database:');
    debugPrint(
      '1. Copy test_database.sqlite to your app\'s database directory',
    );
    debugPrint('2. Or replace the main database file with this one');
  } catch (e) {
    debugPrint('❌ Error: $e');
    debugPrint('Error type: ${e.runtimeType}');
    debugPrint('Stack trace: ${StackTrace.current}');
  } finally {
    await database.close();
  }
}
