import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'dart:developer';
import 'lib/core/database/app_database.dart';

void main() async {
  log('Checking database schema...');

  // Use in-memory database to check schema
  final database = AppDatabase(DatabaseConnection(NativeDatabase.memory()));

  try {
    // Get the actual SQL schema
    final result = await database
        .customSelect(
          'SELECT sql FROM sqlite_master WHERE type="table" AND name="customers"',
        )
        .get();

    if (result.isNotEmpty) {
      log('Customers table schema:');
      log(result.first.data['sql']);
    } else {
      log('No customers table found');
    }

    // Try to insert a test customer to reproduce the error
    log('\nTesting customer insertion...');
    final testCustomer = CustomersCompanion.insert(
      id: 'test_customer_123',
      name: 'Test Customer',
      status: const Value(1),
    );

    await database.customerDao.insertCustomer(testCustomer);
    log('✅ Customer insertion successful!');
  } catch (e) {
    log('❌ Error: $e');
    log('Error type: ${e.runtimeType}');
  } finally {
    await database.close();
  }
}
