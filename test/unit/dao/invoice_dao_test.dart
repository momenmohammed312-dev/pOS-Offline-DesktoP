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

  group('InvoiceDao Tests', () {
    test('getInvoicesByDateRange returns invoices within range', () async {
      final now = DateTime.now();

      // 1. Insert invoice
      await database.invoiceDao.insertInvoice(
        InvoicesCompanion.insert(
          invoiceNumber: Value('TEST-INV-001'),
          customerName: Value('Customer 1'),
          customerContact: Value('1234567890'),
          customerId: const Value('cust1'),
          date: Value(now),
          totalAmount: const Value(150.0),
          paidAmount: const Value(150.0),
          paymentMethod: const Value('cash'),
          status: const Value('completed'),
        ),
      );

      // 2. Query within range
      final results = await database.invoiceDao.getInvoicesByDateRange(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );

      expect(results.length, 1);
      expect(results.first.id, 1);

      // 3. Query outside range
      final resultsOld = await database.invoiceDao.getInvoicesByDateRange(
        now.subtract(const Duration(days: 2)),
        now.subtract(const Duration(days: 1)),
      );

      expect(resultsOld.length, 0);
    });

    test('getInvoicesByDateRangeAndType filters by payment method', () async {
      final now = DateTime.now();

      await database.invoiceDao.insertInvoice(
        InvoicesCompanion.insert(
          invoiceNumber: Value('TEST-INV-002'),
          customerName: Value('Customer 1'),
          customerContact: Value('1234567890'),
          customerId: const Value('cust1'),
          date: Value(now),
          totalAmount: const Value(100.0),
          paidAmount: const Value(100.0),
          paymentMethod: const Value('cash'),
          status: const Value('completed'),
        ),
      );

      await database.invoiceDao.insertInvoice(
        InvoicesCompanion.insert(
          invoiceNumber: Value('TEST-INV-003'),
          customerName: Value('Customer 1'),
          customerContact: Value('1234567890'),
          customerId: const Value('cust1'),
          date: Value(now),
          totalAmount: const Value(200.0),
          paidAmount: const Value(0.0),
          paymentMethod: const Value('credit'),
          status: const Value('completed'),
        ),
      );

      final cashResults = await database.invoiceDao
          .getInvoicesByDateRangeAndType(
            now.subtract(const Duration(hours: 1)),
            now.add(const Duration(hours: 1)),
            ['cash'],
          );

      expect(cashResults.length, 1);
      expect(cashResults.first.id, 1);

      final creditResults = await database.invoiceDao
          .getInvoicesByDateRangeAndType(
            now.subtract(const Duration(hours: 1)),
            now.add(const Duration(hours: 1)),
            ['credit'],
          );

      expect(creditResults.length, 1);
      expect(creditResults.first.id, 2);
    });
  });
}
