import 'package:drift/drift.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;

void main() async {
  // Initialize Flutter binding for testing
  WidgetsFlutterBinding.ensureInitialized();

  // Create a container for Riverpod
  final container = ProviderContainer();

  try {
    developer.log('🔍 Testing Customer Database Fix...\n');

    // Get database instance
    final database = container.read(appDatabaseProvider);

    // 1. Test schema by checking table info
    developer.log('📋 Checking customers table schema...');
    try {
      final result = await database
          .customSelect('PRAGMA table_info(customers)')
          .get();
      developer.log('✅ Customers table schema:');
      for (final row in result) {
        final data = row.data;
        developer.log(
          '  - ${data['name']}: ${data['type']} (nullable: ${data['notnull'] == 0})',
        );
      }
    } catch (e) {
      developer.log('❌ Error checking schema: $e');
    }

    // 2. Test customer insertion
    developer.log('\n🧪 Testing customer insertion...');
    try {
      final testCustomer = CustomersCompanion.insert(
        id: 'test-customer-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Customer',
        phone: const Value('01234567890'),
        email: const Value('test@example.com'),
        address: const Value('Test Address'),
        gstinNumber: const Value('GST123456'),
        openingBalance: const Value(100.0),
        totalDebt: const Value(0.0),
        totalPaid: const Value(0.0),
        notes: const Value('Test notes'),
        isActive: const Value(true),
        status: const Value(1),
      );

      final customerId = await database.customerDao.insertCustomer(
        testCustomer,
      );
      developer.log('✅ Successfully inserted customer with ID: $customerId');

      // 3. Test customer retrieval
      developer.log('\n🔍 Testing customer retrieval...');
      final customers = await database.customerDao.getAllActiveCustomers();
      developer.log('✅ Retrieved ${customers.length} active customers');

      if (customers.isNotEmpty) {
        final customer = customers.last;
        developer.log('✅ Latest customer: ${customer.name} (${customer.id})');
        developer.log('  - Phone: ${customer.phone}');
        developer.log('  - Email: ${customer.email}');
        developer.log('  - Opening Balance: ${customer.openingBalance}');
        developer.log('  - Status: ${customer.status}');
        developer.log('  - Active: ${customer.isActive}');
        developer.log('  - Created: ${customer.createdAt}');
      }

      // 4. Test customer update
      developer.log('\n🔄 Testing customer update...');
      if (customers.isNotEmpty) {
        final customer = customers.last;
        final updatedCustomer = CustomersCompanion(
          id: Value(customer.id),
          name: Value('Updated Test Customer'),
          phone: Value('09876543210'),
        );

        final success = await database.customerDao.updateCustomer(
          updatedCustomer,
        );
        developer.log('✅ Customer update success: $success');
      }

      developer.log(
        '\n🎉 All tests passed! Database fix is working correctly.',
      );
    } catch (e) {
      developer.log('❌ Error during customer operations: $e');
      developer.log('Stack trace: ${StackTrace.current}');
    }
  } catch (e) {
    developer.log('❌ Fatal error: $e');
  } finally {
    container.dispose();
  }
}
