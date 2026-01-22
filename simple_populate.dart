import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  developer.log('=== Simple Database Population ===');

  try {
    // Initialize database
    final db = await _initializeDatabase();

    // Test basic connection
    final test = await db.customSelect('SELECT 1 as test').get();
    developer.log('✓ Database connection: ${test.first.read<int>('test')}');

    // Check current data
    developer.log('\n=== Checking Current Data ===');
    final invoiceCount = await db
        .customSelect('SELECT COUNT(*) as count FROM invoices')
        .get();
    developer.log('Current invoices: ${invoiceCount.first.read<int>('count')}');

    final customerCount = await db
        .customSelect('SELECT COUNT(*) as count FROM customers')
        .get();
    developer.log(
      'Current customers: ${customerCount.first.read<int>('count')}',
    );

    final productCount = await db
        .customSelect('SELECT COUNT(*) as count FROM products')
        .get();
    developer.log('Current products: ${productCount.first.read<int>('count')}');

    // Add sample data if needed
    if (invoiceCount.first.read<int>('count') == 0) {
      developer.log('\n=== Adding Sample Data ===');
      await _addSampleCustomers(db);
      await _addSampleProducts(db);
      await _addSampleInvoices(db);

      // Verify data was added
      final newInvoiceCount = await db
          .customSelect('SELECT COUNT(*) as count FROM invoices')
          .get();
      final newCustomerCount = await db
          .customSelect('SELECT COUNT(*) as count FROM customers')
          .get();
      final newProductCount = await db
          .customSelect('SELECT COUNT(*) as count FROM products')
          .get();

      developer.log('\n=== Final Data Count ===');
      developer.log('Invoices: ${newInvoiceCount.first.read<int>('count')}');
      developer.log('Customers: ${newCustomerCount.first.read<int>('count')}');
      developer.log('Products: ${newProductCount.first.read<int>('count')}');

      developer.log('\n✓ Database population completed successfully!');
    } else {
      developer.log('\n⚠ Database already contains data');
      developer.log('Invoices: ${invoiceCount.first.read<int>('count')}');
      developer.log('Customers: ${customerCount.first.read<int>('count')}');
      developer.log('Products: ${productCount.first.read<int>('count')}');
    }

    await db.close();
    developer.log('\n=== Simple Population Complete ===');
  } catch (e, stackTrace) {
    developer.log('❌ Error: $e');
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

Future<void> _addSampleCustomers(AppDatabase db) async {
  developer.log('Adding sample customers...');

  final customers = [
    {
      'id': 'CUST001',
      'name': 'أحمد محمد',
      'phone': '01234567890',
      'address': 'القاهرة - المهندسين',
      'opening_balance': 0.0,
    },
    {
      'id': 'CUST002',
      'name': 'فاطمة علي',
      'phone': '01123456789',
      'address': 'الإسكندرية - سان ستيفانو',
      'opening_balance': 500.0,
    },
    {
      'id': 'CUST003',
      'name': 'محمد خالد',
      'phone': '01098765432',
      'address': 'الجيزة - المهندسين',
      'opening_balance': 0.0,
    },
  ];

  for (final customer in customers) {
    await db
        .into(db.customers)
        .insert(
          CustomersCompanion.insert(
            id: customer['id'] as String,
            name: customer['name'] as String,
            phone: Value(customer['phone'] as String?),
            address: Value(customer['address'] as String?),
            openingBalance: Value(customer['opening_balance'] as double),
            status: const Value(1),
            createdAt: Value(DateTime.now()),
          ),
        );
    developer.log('  Added customer: ${customer['name']}');
  }
}

Future<void> _addSampleProducts(AppDatabase db) async {
  developer.log('Adding sample products...');

  final products = [
    {
      'name': 'لابتوب ديل',
      'description': 'لابتوب ديل Inspiron 15',
      'price': 15000.0,
      'cost': 12000.0,
      'stock': 10,
    },
    {
      'name': 'ماوس لوجيتك',
      'description': 'ماوس لاسلكي من لوجيتك',
      'price': 250.0,
      'cost': 180.0,
      'stock': 50,
    },
    {
      'name': 'كيبورد ميكانيكي',
      'description': 'كيبورد ميكانيكي RGB',
      'price': 450.0,
      'cost': 320.0,
      'stock': 25,
    },
  ];

  for (final product in products) {
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            name: product['name'] as String,
            quantity: product['stock'] as int,
            price: product['price'] as double,
            status: const Value('Active'),
          ),
        );
    developer.log('  Added product: ${product['name']}');
  }
}

Future<void> _addSampleInvoices(AppDatabase db) async {
  developer.log('Adding sample invoices...');

  // Invoice 1
  final invoice1 = await db
      .into(db.invoices)
      .insert(
        InvoicesCompanion.insert(
          invoiceNumber: Value('INV-${DateTime.now().millisecondsSinceEpoch}'),
          customerName: Value('أحمد محمد'),
          customerContact: Value('01234567890'),
          customerId: const Value('CUST001'),
          customerAddress: const Value('القاهرة - المهندسين'),
          paymentMethod: const Value('cash'),
          totalAmount: const Value(1500.50),
          paidAmount: const Value(1500.50),
          date: Value(DateTime.now()),
          status: const Value('paid'),
        ),
      );

  // Add items for invoice 1
  for (final item in [
    InvoiceItemsCompanion.insert(
      invoiceId: invoice1,
      productId: 1,
      quantity: const Value(2),
      price: 500.0,
    ),
    InvoiceItemsCompanion.insert(
      invoiceId: invoice1,
      productId: 2,
      quantity: const Value(5),
      price: 100.10,
    ),
  ]) {
    await db.into(db.invoiceItems).insert(item);
  }

  // Invoice 2
  final invoice2 = await db
      .into(db.invoices)
      .insert(
        InvoicesCompanion.insert(
          invoiceNumber: Value(
            'INV-${DateTime.now().millisecondsSinceEpoch - 1000}',
          ),
          customerName: Value('فاطمة علي'),
          customerContact: Value('01123456789'),
          customerId: const Value('CUST002'),
          customerAddress: const Value('الإسكندرية - سان ستيفانو'),
          paymentMethod: const Value('credit'),
          totalAmount: const Value(2800.75),
          paidAmount: const Value(1500.0),
          date: Value(DateTime.now().subtract(const Duration(days: 5))),
          status: const Value('partial'),
        ),
      );

  // Add items for invoice 2
  for (final item in [
    InvoiceItemsCompanion.insert(
      invoiceId: invoice2,
      productId: 2,
      quantity: const Value(3),
      price: 250.0,
    ),
    InvoiceItemsCompanion.insert(
      invoiceId: invoice2,
      productId: 3,
      quantity: const Value(2),
      price: 450.0,
    ),
  ]) {
    await db.into(db.invoiceItems).insert(item);
  }

  // Invoice 3
  final invoice3 = await db
      .into(db.invoices)
      .insert(
        InvoicesCompanion.insert(
          invoiceNumber: Value(
            'INV-${DateTime.now().millisecondsSinceEpoch - 2000}',
          ),
          customerName: Value('محمد خالد'),
          customerContact: Value('01098765432'),
          customerId: const Value('CUST003'),
          customerAddress: const Value('الجيزة - المهندسين'),
          paymentMethod: const Value('cash'),
          totalAmount: const Value(750.0),
          paidAmount: const Value(750.0),
          date: Value(DateTime.now().subtract(const Duration(days: 10))),
          status: const Value('paid'),
        ),
      );

  // Add items for invoice 3
  await db
      .into(db.invoiceItems)
      .insert(
        InvoiceItemsCompanion.insert(
          invoiceId: invoice3,
          productId: 1,
          quantity: const Value(1),
          price: 750.0,
        ),
      );

  developer.log('  Added 3 sample invoices with items');
}
