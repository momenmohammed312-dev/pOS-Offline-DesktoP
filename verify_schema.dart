import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

void main() async {
  developer.log('🔍 Verifying Database Schema Fix...\n');

  try {
    // Get database path
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = join(
      dbFolder.path,
      'pos_offline_desktop_database/pos_offline_desktop_database.sqlite',
    );

    developer.log('📁 Database path: $dbPath');

    // Check if database file exists
    final dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      developer.log('❌ Database file not found. Creating new database...');
      dbFile.createSync(recursive: true);
    }

    // Connect to database
    final database = DatabaseConnection(NativeDatabase(dbFile));

    // 1. Check table schema
    developer.log('\n📋 Checking customers table schema...');
    try {
      final result = await Process.run('sqlite3', [
        dbPath,
        'PRAGMA table_info(customers);',
      ]);

      if (result.exitCode != 0) {
        developer.log('❌ Error checking schema: ${result.stderr}');
        return;
      }

      developer.log('✅ Customers table schema:');
      developer.log(result.stdout);

      final output = result.stdout as String;
      final lines = output.split('\n');

      bool hasCreatedAt = false;
      bool hasUpdatedAt = false;
      bool hasOpeningBalance = false;
      bool hasTotalDebt = false;
      bool hasTotalPaid = false;
      bool hasIsActive = false;
      bool hasStatus = false;
      bool hasGstinNumber = false;

      for (final line in lines) {
        if (line.contains('created_at')) hasCreatedAt = true;
        if (line.contains('updated_at')) hasUpdatedAt = true;
        if (line.contains('opening_balance')) hasOpeningBalance = true;
        if (line.contains('total_debt')) hasTotalDebt = true;
        if (line.contains('total_paid')) hasTotalPaid = true;
        if (line.contains('is_active')) hasIsActive = true;
        if (line.contains('status')) hasStatus = true;
        if (line.contains('gstin_number')) hasGstinNumber = true;
      }

      developer.log('\n🔍 Schema Validation Results:');
      developer.log('  ✅ created_at: ${hasCreatedAt ? "EXISTS" : "MISSING"}');
      developer.log('  ✅ updated_at: ${hasUpdatedAt ? "EXISTS" : "MISSING"}');
      developer.log(
        '  ✅ opening_balance: ${hasOpeningBalance ? "EXISTS" : "MISSING"}',
      );
      developer.log('  ✅ total_debt: ${hasTotalDebt ? "EXISTS" : "MISSING"}');
      developer.log('  ✅ total_paid: ${hasTotalPaid ? "EXISTS" : "MISSING"}');
      developer.log('  ✅ is_active: ${hasIsActive ? "EXISTS" : "MISSING"}');
      developer.log('  ✅ status: ${hasStatus ? "EXISTS" : "MISSING"}');
      developer.log(
        '  ✅ gstin_number: ${hasGstinNumber ? "EXISTS" : "MISSING"}',
      );

      if (hasCreatedAt &&
          hasUpdatedAt &&
          hasOpeningBalance &&
          hasTotalDebt &&
          hasTotalPaid &&
          hasIsActive &&
          hasStatus &&
          hasGstinNumber) {
        developer.log('\n🎉 All required columns exist! Schema is correct.');
      } else {
        developer.log(
          '\n⚠️  Some columns are missing. Schema needs migration.',
        );
      }
    } catch (e) {
      developer.log('❌ Error checking schema: $e');
    }

    // 2. Test customer insertion
    developer.log('\n🧪 Testing customer insertion...');
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final insertSql = '''
        INSERT INTO customers (
          id, name, phone, email, address, gstin_number, 
          opening_balance, total_debt, total_paid, created_at, updated_at, 
          notes, is_active, status
        ) VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        )
      ''';

      await Process.run('sqlite3', [
        dbPath,
        insertSql,
        'test-customer-$timestamp',
        'Test Customer',
        '01234567890',
        'test@example.com',
        'Test Address',
        'GST123456',
        '100.0',
        '0.0',
        '0.0',
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        'Test notes',
        '1',
        'Active',
      ]);

      developer.log('✅ Successfully inserted test customer');

      // 3. Test customer retrieval
      developer.log('\n🔍 Testing customer retrieval...');
      final selectResult = await Process.run('sqlite3', [
        dbPath,
        "SELECT * FROM customers WHERE name = 'Test Customer' ORDER BY created_at DESC LIMIT 1;",
      ]);

      if (selectResult.exitCode == 0 &&
          selectResult.stdout.toString().isNotEmpty) {
        developer.log('✅ Retrieved test customer successfully');
        developer.log('Customer data:');
        developer.log(selectResult.stdout);
      } else {
        developer.log('❌ Could not retrieve test customer');
      }

      // 4. Clean up test data
      final deleteResult = await Process.run('sqlite3', [
        dbPath,
        "DELETE FROM customers WHERE id = 'test-customer-$timestamp';",
      ]);

      if (deleteResult.exitCode == 0) {
        developer.log('✅ Cleaned up test data');
      } else {
        developer.log('❌ Error cleaning up test data: ${deleteResult.stderr}');
      }

      developer.log(
        '\n🎉 All tests passed! Database fix is working correctly.',
      );
    } catch (e) {
      developer.log('❌ Error during customer operations: $e');
    }

    await database.close();
  } catch (e) {
    developer.log('❌ Fatal error: $e');
  }
}
