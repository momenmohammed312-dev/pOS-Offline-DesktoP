import 'package:drift/drift.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'dart:developer' as developer;

/// أمثلة شاملة لإنشاء وإدارة الفواتير في نظام POS
/// Comprehensive examples for creating and managing invoices in the POS system

class InvoiceExamples {
  /// 🛠️ أولاً: إنشاء فاتورة جديدة (صحيح ومكتمل)
  /// First: Create a new invoice (correct and complete)
  static Future<int> createNewInvoice(AppDatabase db) async {
    final invoiceId = await db.invoiceDao.insertInvoice(
      InvoicesCompanion.insert(
        invoiceNumber: Value('INV-${DateTime.now().millisecondsSinceEpoch}'),
        customerName: Value('أحمد محمد'),
        customerContact: Value('01234567890'),
        paymentMethod: const Value('cash'),
        totalAmount: const Value(1500.50),
        paidAmount: const Value(1500.50),
        date: Value(DateTime.now()),
        status: const Value('paid'),
      ),
    );

    developer.log('✅ تم إنشاء فاتورة جديدة برقم: $invoiceId');
    return invoiceId;
  }

  /// 🖨️ ثانياً: إضافة بنود الفاتورة (منتجات)
  /// Second: Add invoice items (products)
  static Future<void> addInvoiceItems(AppDatabase db, int invoiceId) async {
    final items = [
      // منتج 1 - Product 1
      InvoiceItemsCompanion.insert(
        invoiceId: invoiceId,
        productId: 1,
        quantity: const Value(2),
        price: 500.0,
      ),

      // منتج 2 - Product 2
      InvoiceItemsCompanion.insert(
        invoiceId: invoiceId,
        productId: 2,
        quantity: const Value(5),
        price: 100.10,
      ),
    ];

    for (final item in items) {
      await db.invoiceDao.insertInvoiceItem(item);
    }

    developer.log('✅ تم إضافة ${items.length} بنود للفاتورة رقم: $invoiceId');
  }

  /// 🖨️ ثالثاً: تحديث حالة الفاتورة
  /// Third: Update invoice status
  static Future<void> updateInvoiceStatus(
    AppDatabase db,
    int invoiceId,
    String status,
  ) async {
    await db.invoiceDao.updateInvoice(
      InvoicesCompanion(
        id: Value(invoiceId),
        status: Value(status), // pending, paid, partial
        paidAmount: Value(status == 'paid' ? 1500.50 : 0.0),
      ),
    );

    developer.log('✅ تم تحديث حالة الفاتورة رقم: $invoiceId إلى: $status');
  }

  /// 📊 رابعاً: استعلام عن الفواتير
  /// Fourth: Query invoices
  static Future<void> queryInvoicesExamples(AppDatabase db) async {
    // جميع الفواتير - All invoices
    final allInvoices = await db.invoiceDao.getAllInvoices();
    developer.log('📊 إجمالي الفواتير: ${allInvoices.length}');

    // فواتير اليوم - Today's invoices
    final today = DateTime.now();
    final todayInvoices = await db.invoiceDao.getInvoicesByDate(today);
    developer.log('📅 فواتير اليوم: ${todayInvoices.length}');

    // فواتير العميل - Customer invoices
    final customerInvoices = await db.invoiceDao.getInvoicesByDateRangeAndType(
      DateTime(2024, 1, 1),
      DateTime(2024, 12, 31),
      ['cash', 'credit'],
    );
    developer.log('👤 فواتير العميل (كاش وآجل): ${customerInvoices.length}');
  }

  /// 🖨️ خامساً: الحذف الآمن للفاتورة
  /// Fifth: Safe invoice deletion
  static Future<void> safeDeleteInvoice(AppDatabase db, int invoiceId) async {
    try {
      // التحقق من وجود الفاتورة - Check invoice exists
      final invoices = await db.invoiceDao.getAllInvoices();
      final invoiceExists = invoices.any((inv) => inv.id == invoiceId);

      if (!invoiceExists) {
        developer.log('❌ الفاتورة رقم $invoiceId غير موجودة');
        return;
      }

      // حذف بنود الفاتورة أولاً - Delete invoice items first
      await db.invoiceDao.deleteItemsByInvoiceId(invoiceId);

      // ثم حذف الفاتورة - Then delete invoice
      await db.invoiceDao.deleteInvoice(
        InvoicesCompanion(id: Value(invoiceId)),
      );

      developer.log('✅ تم حذف الفاتورة رقم: $invoiceId وبنودها');
    } catch (e) {
      developer.log('❌ خطأ في حذف الفاتورة: $e');
    }
  }

  /// 🔄 سادساً: التعامل مع العملاء المختلفين
  /// Sixth: Handle different customer types
  static Future<void> handleDifferentCustomerTypes(AppDatabase db) async {
    // عميل كاش - Cash customer
    final cashInvoiceId = await db.invoiceDao.insertInvoice(
      InvoicesCompanion.insert(
        invoiceNumber: Value('INV-CASH-001'),
        customerName: Value('عميل كاش'),
        customerContact: const Value('N/A'),
        customerId: const Value('CUST-CASH-001'),
        paymentMethod: const Value('cash'),
        totalAmount: const Value(300.0),
        paidAmount: const Value(300.0), // مدفوع بالكامل - fully paid
        date: Value(DateTime.now()),
        status: const Value('paid'),
      ),
    );

    // عميل آجل - Credit customer
    final creditInvoiceId = await db.invoiceDao.insertInvoice(
      InvoicesCompanion.insert(
        invoiceNumber: Value('INV-CREDIT-001'),
        customerName: Value('عميل آجل'),
        customerContact: const Value('N/A'),
        customerId: const Value('CUST-CREDIT-001'),
        paymentMethod: const Value('credit'),
        totalAmount: const Value(800.0),
        paidAmount: const Value(200.0), // مدفوع جزئياً - partially paid
        date: Value(DateTime.now()),
        status: const Value('partial'), // حالة جزئية - partial status
      ),
    );

    developer.log('✅ تم إنشاء فاتورة كاش: $cashInvoiceId');
    developer.log('✅ تم إنشاء فاتورة آجل: $creditInvoiceId');
  }

  /// 📈 سابعاً: تقارير وإحصائيات
  /// Seventh: Reports and statistics
  static Future<void> generateReports(AppDatabase db) async {
    final allInvoices = await db.invoiceDao.getAllInvoices();

    // إجمالي المبيعات - Total sales
    final totalSales = allInvoices.fold(
      0.0,
      (sum, inv) => sum + inv.totalAmount,
    );
    developer.log('💰 إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} ج.م');

    // المبالغ المدفوعة - Paid amounts
    final totalPaid = allInvoices.fold(0.0, (sum, inv) => sum + inv.paidAmount);
    developer.log('💵 المبالغ المدفوعة: ${totalPaid.toStringAsFixed(2)} ج.م');

    // المبالغ المتبقية - Remaining amounts
    final totalRemaining = totalSales - totalPaid;
    developer.log(
      '⏳ المبالغ المتبقية: ${totalRemaining.toStringAsFixed(2)} ج.م',
    );

    // حسب طريقة الدفع - By payment method
    final cashSales = allInvoices
        .where((inv) => inv.paymentMethod == 'cash')
        .fold(0.0, (sum, inv) => sum + inv.totalAmount);

    final creditSales = allInvoices
        .where((inv) => inv.paymentMethod == 'credit')
        .fold(0.0, (sum, inv) => sum + inv.totalAmount);

    developer.log('💵 مبيعات كاش: ${cashSales.toStringAsFixed(2)} ج.م');
    developer.log('🏦 مبيعات آجل: ${creditSales.toStringAsFixed(2)} ج.م');
  }

  /// 🎯 مثال متكامل: إنشاء فاتورة كاملة مع بنود
  /// Complete example: Create full invoice with items
  static Future<void> createCompleteInvoiceExample(AppDatabase db) async {
    developer.log('🚀 بدء إنشاء فاتورة كاملة...');

    // 1. إنشاء الفاتورة - Create invoice
    final invoiceId = await createNewInvoice(db);

    // 2. إضافة البنود - Add items
    await addInvoiceItems(db, invoiceId);

    // 3. تحديث الحالة - Update status
    await updateInvoiceStatus(db, invoiceId, 'paid');

    // 4. التحقق - Verify
    final updatedInvoice = (await db.invoiceDao.getAllInvoices()).firstWhere(
      (inv) => inv.id == invoiceId,
    );

    developer.log('✅ تم إنشاء فاتورة كاملة:');
    developer.log('   🔢 الرقم: ${updatedInvoice.invoiceNumber ?? 'N/A'}');
    developer.log('   👤 العميل: ${updatedInvoice.customerName}');
    developer.log('   💰 المبلغ: ${updatedInvoice.totalAmount} ج.م');
    developer.log('   📅 التاريخ: ${updatedInvoice.date}');
    developer.log('   📊 الحالة: ${updatedInvoice.status}');
  }
}
