import 'dart:developer';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'lib/core/database/app_database.dart';

void main() async {
  log('=== Database Schema Analysis ===');

  // Test 1: Check in-memory database schema
  log('\n1. Testing in-memory database schema...');
  try {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));

    // Get table schema
    final result = await db
        .customSelect(
          'SELECT sql FROM sqlite_master WHERE type="table" AND name="customers"',
        )
        .get();

    if (result.isNotEmpty) {
      log('✅ Customers table SQL:');
      log(result.first.data['sql']);
    }

    // Test customer insertion
    log('\n2. Testing customer insertion...');
    final customer = CustomersCompanion.insert(
      id: 'test_123',
      name: 'Test Customer',
      status: const Value(1),
    );

    await db.customerDao.insertCustomer(customer);
    log('✅ Customer insertion SUCCESSFUL');

    await db.close();
  } catch (e) {
    log('❌ Error: $e');
    log('Error type: ${e.runtimeType}');
  }
}
