import 'package:drift/drift.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

/// Fixed invoice service with proper error handling
class InvoiceServiceFixed {
  final AppDatabase db;

  InvoiceServiceFixed(this.db);

  /// Create new invoice with all required fields
  Future<int> createInvoice({
    required String customerName,
    required String customerContact,
    String? customerAddress,
    required String paymentMethod,
    required double totalAmount,
    double? paidAmount = 0.0,
    String? notes,
  }) async {
    try {
      final invoiceId = await db
          .into(db.invoices)
          .insert(
            InvoicesCompanion.insert(
              invoiceNumber: Value(
                'INV-${DateTime.now().millisecondsSinceEpoch}',
              ),
              customerName: Value(customerName),
              customerContact: customerContact.isEmpty
                  ? Value('N/A')
                  : Value(customerContact),
              customerAddress: customerAddress != null
                  ? Value(customerAddress)
                  : const Value.absent(),
              paymentMethod: Value(paymentMethod),
              totalAmount: Value(totalAmount),
              paidAmount: paidAmount != null
                  ? Value(paidAmount)
                  : const Value.absent(),
              date: Value(DateTime.now()),
              status: const Value('pending'),
            ),
          );

      // Create initial payment record if paid amount > 0
      if (paidAmount != null && paidAmount > 0) {
        await db
            .into(db.ledgerTransactions)
            .insert(
              LedgerTransactionsCompanion.insert(
                id: '${DateTime.now().millisecondsSinceEpoch}_payment',
                entityType: 'Customer',
                refId: invoiceId.toString(),
                date: DateTime.now(),
                description: 'فاتورة رقم $invoiceId - دفعة أولية',
                debit: const Value(0.0),
                credit: Value(paidAmount),
                origin: 'payment',
                paymentMethod: Value(paymentMethod),
              ),
            );
      }

      return invoiceId;
    } catch (e) {
      throw Exception('فشل في إنشاء الفاتورة: $e');
    }
  }

  /// Get all invoices with error handling
  Future<List<Invoice>> getAllInvoices() async {
    try {
      return await (db.select(db.invoices).get());
    } catch (e) {
      throw Exception('فشل في جلب الفواتير: $e');
    }
  }

  /// Update invoice status safely
  Future<void> updateInvoiceStatus(int invoiceId, String status) async {
    try {
      await (db.update(db.invoices)..where((tbl) => tbl.id.equals(invoiceId)))
          .write(InvoicesCompanion(status: Value(status)));
    } catch (e) {
      throw Exception('فشل في تحديث حالة الفاتورة: $e');
    }
  }
}
