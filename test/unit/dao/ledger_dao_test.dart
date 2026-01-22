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

  group('LedgerDao Tests', () {
    test('initial balance should be zero', () async {
      final balance = await database.ledgerDao.getRunningBalance(
        'Customer',
        'cust1',
      );
      expect(balance, 0.0);
    });

    test('inserting transactions updates running balance correctly', () async {
      // 1. Sale transaction (Debit increases customer debt)
      await database.ledgerDao.insertTransaction(
        LedgerTransactionsCompanion.insert(
          id: 'tx1',
          entityType: 'Customer',
          refId: 'cust1',
          date: DateTime.now(),
          description: 'Sale',
          debit: const Value(100.0),
          credit: const Value(0.0),
          origin: 'sale',
          paymentMethod: const Value('credit'),
        ),
      );

      var balance = await database.ledgerDao.getRunningBalance(
        'Customer',
        'cust1',
      );
      expect(balance, 100.0);

      // 2. Payment transaction (Credit decreases customer debt)
      await database.ledgerDao.insertTransaction(
        LedgerTransactionsCompanion.insert(
          id: 'tx2',
          entityType: 'Customer',
          refId: 'cust1',
          date: DateTime.now(),
          description: 'Payment',
          debit: const Value(0.0),
          credit: const Value(40.0),
          origin: 'payment',
          paymentMethod: const Value('cash'),
        ),
      );

      balance = await database.ledgerDao.getRunningBalance('Customer', 'cust1');
      expect(balance, 60.0);
    });

    test(
      'getCustomerBalance calculates debit minus credit correctly',
      () async {
        await database.ledgerDao.insertTransaction(
          LedgerTransactionsCompanion.insert(
            id: 'tx1',
            entityType: 'Customer',
            refId: 'cust2',
            date: DateTime.now(),
            description: 'Sale',
            debit: const Value(200.0),
            credit: const Value(0.0),
            origin: 'sale',
            paymentMethod: const Value('credit'),
          ),
        );

        await database.ledgerDao.insertTransaction(
          LedgerTransactionsCompanion.insert(
            id: 'tx2',
            entityType: 'Customer',
            refId: 'cust2',
            date: DateTime.now(),
            description: 'Payment',
            debit: const Value(0.0),
            credit: const Value(50.0),
            origin: 'payment',
            paymentMethod: const Value('cash'),
          ),
        );

        final balance = await database.ledgerDao.getCustomerBalance('cust2');
        expect(balance, 150.0);
      },
    );

    test('getTransactionsByDateRange filters correctly', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      await database.ledgerDao.insertTransaction(
        LedgerTransactionsCompanion.insert(
          id: 'tx_old',
          entityType: 'Customer',
          refId: 'cust3',
          date: yesterday,
          description: 'Old',
          debit: const Value(10.0),
          credit: const Value(0.0),
          origin: 'sale',
        ),
      );

      await database.ledgerDao.insertTransaction(
        LedgerTransactionsCompanion.insert(
          id: 'tx_now',
          entityType: 'Customer',
          refId: 'cust3',
          date: now,
          description: 'Now',
          debit: const Value(20.0),
          credit: const Value(0.0),
          origin: 'sale',
        ),
      );

      final transactions = await database.ledgerDao.getTransactionsByDateRange(
        'Customer',
        'cust3',
        now.subtract(const Duration(minutes: 1)),
        tomorrow,
      );

      expect(transactions.length, 1);
      expect(transactions.first.id, 'tx_now');
    });
  });
}
