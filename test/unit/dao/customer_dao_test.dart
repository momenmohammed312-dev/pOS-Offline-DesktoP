import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async {
          return '.';
        },
      );

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('CustomerDao Tests', () {
    test(
      'getCustomersWithBalance should return only customers with balance',
      () async {
        // 1. Add customers
        await database.customerDao.insertCustomer(
          CustomersCompanion.insert(
            id: 'c1',
            name: 'Customer 1',
            openingBalance: const Value(100.0),
          ),
        );
        await database.customerDao.insertCustomer(
          CustomersCompanion.insert(
            id: 'c2',
            name: 'Customer 2',
            openingBalance: const Value(200.0),
          ),
        );

        // 2. Initial check
        var customersWithBalance = await database.customerDao
            .getCustomersWithBalance();
        expect(customersWithBalance.length, 2);
        expect(customersWithBalance.first.id, 'c1');
        expect(customersWithBalance.first.openingBalance, 100.0);

        // 3. Add transaction for c2
        await database.ledgerDao.insertTransaction(
          LedgerTransactionsCompanion.insert(
            id: 'tx1',
            entityType: 'Customer',
            refId: 'c2',
            date: DateTime.now(),
            description: 'Debit',
            debit: const Value(50.0),
            credit: const Value(0.0),
            origin: 'sale',
          ),
        );

        customersWithBalance = await database.customerDao
            .getCustomersWithBalance();
        expect(customersWithBalance.length, 2);

        final c2Data = customersWithBalance.firstWhere((c) => c.id == 'c2');
        expect(c2Data.openingBalance, 200.0);
      },
    );
  });
}
