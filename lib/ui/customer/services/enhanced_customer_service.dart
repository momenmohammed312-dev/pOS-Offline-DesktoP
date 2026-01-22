import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/ui/customer/services/enhanced_customer_statement_generator.dart';

class EnhancedCustomerService {
  final AppDatabase db;

  EnhancedCustomerService(this.db);

  Future<List<Map<String, dynamic>>> getCustomerTransactions({
    required String customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      // Get invoices for the customer in date range
      final allInvoices = await db.invoiceDao.getInvoicesByDateRange(
        fromDate,
        toDate,
      );
      final invoices = allInvoices
          .where((invoice) => invoice.customerId == customerId)
          .toList();

      // Get payments for the customer in date range
      final payments = await db.ledgerDao.getTransactionsByDateRange(
        'Customer',
        customerId,
        fromDate,
        toDate,
      );

      // Combine and format transactions
      final transactions = <Map<String, dynamic>>[];

      // Add invoices as debit transactions
      for (final invoice in invoices) {
        transactions.add({
          'date': invoice.date.toString().substring(0, 10),
          'description': 'Invoice #${invoice.invoiceNumber ?? 'N/A'}',
          'debit': invoice.totalAmount,
          'credit': 0.0,
          'balance': invoice.totalAmount,
        });
      }

      // Add payments as credit transactions
      for (final payment in payments) {
        transactions.add({
          'date': payment.date.toString().substring(0, 10),
          'description': 'Payment - ${payment.description}',
          'debit': 0.0,
          'credit': payment.credit,
          'balance': -payment.credit,
        });
      }

      // Sort by date
      transactions.sort(
        (a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])),
      );

      return transactions;
    } catch (e) {
      throw Exception('Failed to get customer transactions: $e');
    }
  }

  Future<void> exportCustomerPdf({
    required String customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final customer = await (db.select(
        db.customers,
      )..where((c) => c.id.equals(customerId))).getSingle();

      // Calculate opening and current balances
      final openingBalance = await _calculateOpeningBalance(
        customerId,
        fromDate,
      );
      final currentBalance = await db.ledgerDao.getRunningBalance(
        'Customer',
        customerId,
      );

      await EnhancedCustomerStatementGenerator.generateStatement(
        db: db,
        customerId: customerId,
        customerName: customer.name,
        fromDate: fromDate,
        toDate: toDate,
        openingBalance: openingBalance,
        currentBalance: currentBalance,
      );
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  Future<void> printCustomerStatement({
    required String customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final customer = await (db.select(
        db.customers,
      )..where((c) => c.id.equals(customerId))).getSingle();

      // Calculate opening and current balances
      final openingBalance = await _calculateOpeningBalance(
        customerId,
        fromDate,
      );
      final currentBalance = await db.ledgerDao.getRunningBalance(
        'Customer',
        customerId,
      );

      await EnhancedCustomerStatementGenerator.generateStatement(
        db: db,
        customerId: customerId,
        customerName: customer.name,
        fromDate: fromDate,
        toDate: toDate,
        openingBalance: openingBalance,
        currentBalance: currentBalance,
      );
    } catch (e) {
      throw Exception('Failed to print statement: $e');
    }
  }

  // Helper method to calculate opening balance before the date range
  Future<double> _calculateOpeningBalance(
    String customerId,
    DateTime fromDate,
  ) async {
    try {
      // Get all transactions before the from date
      final previousTransactions = await db.ledgerDao
          .getTransactionsByDateRange(
            'Customer',
            customerId,
            DateTime(2000), // Very early date
            fromDate.subtract(const Duration(days: 1)),
          );

      // Calculate balance from previous transactions
      double balance = 0.0;
      for (final transaction in previousTransactions) {
        balance += transaction.debit - transaction.credit;
      }

      return balance;
    } catch (e) {
      debugPrint('Error calculating opening balance: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> createPaymentRecord({
    required String customerId,
    required double amount,
    required String note,
    required String paymentMethod,
  }) async {
    try {
      final customer = await (db.select(
        db.customers,
      )..where((c) => c.id.equals(customerId))).getSingle();
      final currentBalance = await db.ledgerDao.getRunningBalance(
        'Customer',
        customerId,
      );

      // Create payment record
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';

      await db.ledgerDao.insertTransaction(
        LedgerTransactionsCompanion.insert(
          id: paymentId,
          entityType: 'Customer',
          refId: customerId,
          date: DateTime.now(),
          description: 'Payment - $note',
          debit: const drift.Value(0.0),
          credit: drift.Value(amount),
          origin: 'payment',
          paymentMethod: drift.Value(paymentMethod),
          receiptNumber: drift.Value(paymentId),
        ),
      );

      // Update customer balance
      final newBalance = currentBalance - amount;

      // Update customer record if needed (for audit trail)
      await db.customerDao.updateCustomerByData(
        customer.copyWith(openingBalance: newBalance),
      );

      return {
        'payment_id': paymentId,
        'customer_id': customerId,
        'amount': amount,
        'note': note,
        'date': DateTime.now().toIso8601String(),
        'created_by': 'system',
        'new_balance': newBalance,
        'previous_balance': currentBalance,
      };
    } catch (e) {
      throw Exception('Failed to create payment record: $e');
    }
  }
}
