import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:flutter/foundation.dart';

/// SOP 4.0: Enhanced Database Service for Running Balance Calculations
/// MANDATORY: Handles all balance calculations for Customer & Supplier Ledgers
class BalanceCalculationService {
  final AppDatabase db;

  BalanceCalculationService(this.db);

  /// Fetch running balance for a customer before a specific date
  /// MANDATORY: Used for Previous Balance calculations in invoices
  Future<double> getPreviousBalance(
    String customerId,
    DateTime beforeDate, {
    bool isCustomer = true,
  }) async {
    try {
      final transactions = await db.ledgerDao.getTransactionsByEntity(
        isCustomer ? 'Customer' : 'Supplier',
        customerId,
      );

      double balance = 0.0;

      for (final transaction in transactions) {
        if (transaction.date.isBefore(beforeDate)) {
          // Debit increases balance (customer owes more)
          // Credit decreases balance (customer paid)
          balance += transaction.debit - transaction.credit;
        }
      }

      return balance;
    } catch (e) {
      debugPrint('Error calculating previous balance: $e');
      return 0.0;
    }
  }

  /// Generate customer statement with running balance
  /// MANDATORY: Implements the running balance logic from "الحج اسلام رحيم.pdf"
  Future<List<Map<String, dynamic>>> generateCustomerStatement(
    String customerId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final customer = await db.customerDao.getCustomerById(customerId);
      if (customer == null) return [];

      final transactions = await db.ledgerDao.getTransactionsByEntity(
        'Customer',
        customerId,
      );

      // Filter by date range if provided
      var filteredTransactions = transactions.where((t) {
        if (startDate != null && t.date.isBefore(startDate)) return false;
        if (endDate != null && t.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      // Sort by date
      filteredTransactions.sort((a, b) => a.date.compareTo(b.date));

      // Calculate running balance
      double runningBalance = 0.0;
      final statementData = <Map<String, dynamic>>[];

      for (final transaction in filteredTransactions) {
        runningBalance += transaction.debit - transaction.credit;

        // Build enhanced description with nested transaction details
        String description = transaction.description;

        // Check if this is a sale transaction and fetch details
        if (transaction.receiptNumber != null &&
            description.contains('مبيعات')) {
          final items = await _getInvoiceItems(transaction.receiptNumber!);
          if (items.isNotEmpty) {
            description = _buildDetailedDescription(description, items);
          }
        }

        statementData.add({
          'date': transaction.date,
          'receiptNumber': transaction.receiptNumber ?? '',
          'description': description,
          'debit': transaction.debit,
          'credit': transaction.credit,
          'balance': runningBalance,
          'origin': transaction.origin,
          'hasNestedDetails': transaction.receiptNumber != null,
        });
      }

      return statementData;
    } catch (e) {
      debugPrint('Error generating customer statement: $e');
      return [];
    }
  }

  /// Generate supplier statement with running balance
  /// MANDATORY: Same logic as customer but for suppliers
  Future<List<Map<String, dynamic>>> generateSupplierStatement(
    String supplierId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final supplier = await db.supplierDao.getSupplierById(supplierId);
      if (supplier == null) return [];

      final transactions = await db.ledgerDao.getTransactionsByEntity(
        'Supplier',
        supplierId,
      );

      // Filter by date range if provided
      var filteredTransactions = transactions.where((t) {
        if (startDate != null && t.date.isBefore(startDate)) return false;
        if (endDate != null && t.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      // Sort by date
      filteredTransactions.sort((a, b) => a.date.compareTo(b.date));

      // Calculate running balance
      double runningBalance = 0.0;
      final statementData = <Map<String, dynamic>>[];

      for (final transaction in filteredTransactions) {
        runningBalance += transaction.credit - transaction.debit;

        // Build enhanced description with nested transaction details
        String description = transaction.description;

        // Check if this is a purchase transaction and fetch details
        if (transaction.receiptNumber != null &&
            description.contains('مشتريات')) {
          final items = await _getPurchaseItems(transaction.receiptNumber!);
          if (items.isNotEmpty) {
            description = _buildDetailedDescription(description, items);
          }
        }

        statementData.add({
          'date': transaction.date,
          'receiptNumber': transaction.receiptNumber ?? '',
          'description': description,
          'debit': transaction.debit,
          'credit': transaction.credit,
          'balance': runningBalance,
          'origin': transaction.origin,
          'hasNestedDetails': transaction.receiptNumber != null,
        });
      }

      return statementData;
    } catch (e) {
      debugPrint('Error generating supplier statement: $e');
      return [];
    }
  }

  /// Get invoice items for nested transaction details
  Future<List<Map<String, dynamic>>> _getInvoiceItems(
    String receiptNumber,
  ) async {
    try {
      // Extract invoice ID from receipt number
      final match = RegExp(r'\d+').firstMatch(receiptNumber);
      if (match == null) return [];

      final invoiceId = int.tryParse(match.group(0) ?? '');
      if (invoiceId == null) return [];

      final items = await db.invoiceDao.getItemsWithProductsByInvoice(
        invoiceId,
      );
      return items.map((itemWithProduct) {
        final item = itemWithProduct.$1;
        final product = itemWithProduct.$2;
        final unitPrice = item.quantity > 0 ? item.price / item.quantity : 0.0;

        return {
          'productName': product?.name ?? 'منتج ${item.productId}',
          'unit': product?.unit ?? 'قطعة',
          'quantity': item.quantity,
          'unitPrice': unitPrice,
          'total': item.price,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching invoice items: $e');
      return [];
    }
  }

  /// Get purchase items for nested transaction details
  Future<List<Map<String, dynamic>>> _getPurchaseItems(
    String receiptNumber,
  ) async {
    try {
      // Extract purchase ID from receipt number
      final match = RegExp(r'\d+').firstMatch(receiptNumber);
      if (match == null) return [];

      final purchaseId = int.tryParse(match.group(0) ?? '');
      if (purchaseId == null) return [];

      // Purchase items method needs to be implemented in PurchaseDao
      // This will be available when getItemsWithProductsByPurchase is added
      return [];
    } catch (e) {
      debugPrint('Error fetching purchase items: $e');
      return [];
    }
  }

  /// Build detailed description with product breakdown
  /// MANDATORY: Shows nested transaction details in statements
  String _buildDetailedDescription(
    String baseDescription,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return baseDescription;

    final itemDescriptions = items.map((item) {
      final name = item['productName'] as String;
      final quantity = item['quantity'] as int;
      final unit = item['unit'] as String? ?? 'قطعة';
      final unitPrice = (item['unitPrice'] as double).toStringAsFixed(2);

      return '$name ($quantity $unit × $unitPrice ج.م)';
    }).toList();

    return '$baseDescription\n${itemDescriptions.join('\n')}';
  }

  /// Get current balance for a customer
  Future<double> getCurrentCustomerBalance(String customerId) async {
    return await getPreviousBalance(
      customerId,
      DateTime.now().add(Duration(days: 1)),
      isCustomer: true,
    );
  }

  /// Get current balance for a supplier
  Future<double> getCurrentSupplierBalance(String supplierId) async {
    return await getPreviousBalance(
      supplierId,
      DateTime.now().add(Duration(days: 1)),
      isCustomer: false,
    );
  }

  /// Generate sales report with enhanced data
  Future<List<Map<String, dynamic>>> generateSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
  }) async {
    try {
      final invoices = await db.invoiceDao.getAllInvoices();

      var filteredInvoices = invoices.where((invoice) {
        if (startDate != null && invoice.date.isBefore(startDate)) return false;
        if (endDate != null && invoice.date.isAfter(endDate)) return false;
        if (customerId != null && invoice.customerId != customerId) {
          return false;
        }
        return true;
      }).toList();

      final reportData = <Map<String, dynamic>>[];

      for (final invoice in filteredInvoices) {
        final customer = invoice.customerName;
        final items = await db.invoiceDao.getItemsWithProductsByInvoice(
          invoice.id,
        );

        // Build product names list
        final productNames = items
            .map((itemWithProduct) {
              final product = itemWithProduct.$2;
              return product?.name ?? 'منتج ${itemWithProduct.$1.productId}';
            })
            .join(', ');

        final previousBalance = await getPreviousBalance(
          invoice.customerId ?? '',
          invoice.date,
        );
        final grandTotal =
            invoice.totalAmount +
            (invoice.paymentMethod == 'credit' ? previousBalance : 0.0);
        final paidAmount = invoice.paidAmount;
        final remainingAmount = grandTotal - paidAmount;

        reportData.add({
          'id': invoice.invoiceNumber,
          'date': invoice.date,
          'customerName': customer ?? 'عميل غير محدد',
          'description': 'فاتورة مبيعات رقم ${invoice.invoiceNumber}',
          'productNames': productNames,
          'totalAmount': invoice.totalAmount,
          'previousBalance': previousBalance,
          'grandTotal': grandTotal,
          'paidAmount': paidAmount,
          'remainingAmount': remainingAmount,
          'isCredit': invoice.paymentMethod == 'credit',
          'invoiceId': invoice.id,
        });
      }

      return reportData;
    } catch (e) {
      debugPrint('Error generating sales report: $e');
      return [];
    }
  }

  /// Generate purchase report with enhanced data
  Future<List<Map<String, dynamic>>> generatePurchaseReport({
    DateTime? startDate,
    DateTime? endDate,
    String? supplierId,
  }) async {
    try {
      final purchases = await db.purchaseDao.getAllPurchases();

      var filteredPurchases = purchases.where((purchase) {
        if (startDate != null && purchase.purchaseDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && purchase.purchaseDate.isAfter(endDate)) {
          return false;
        }
        if (supplierId != null && purchase.supplierId != supplierId) {
          return false;
        }
        return true;
      }).toList();

      final reportData = <Map<String, dynamic>>[];

      for (final purchase in filteredPurchases) {
        // Purchase items fetching will be implemented when PurchaseDao is enhanced
        final productNames = 'منتجات المشتريات';

        final previousBalance = await getPreviousBalance(
          purchase.supplierId ?? '',
          purchase.purchaseDate,
          isCustomer: false,
        );
        final grandTotal =
            purchase.totalAmount +
            (purchase.paymentMethod == 'credit' ? previousBalance : 0.0);
        final paidAmount = purchase.paidAmount;
        final remainingAmount = grandTotal - paidAmount;

        reportData.add({
          'id': purchase.invoiceNumber,
          'date': purchase.purchaseDate,
          'supplierName': 'مورد غير محدد',
          'description': 'فاتورة مشتريات رقم ${purchase.invoiceNumber}',
          'productNames': productNames,
          'totalAmount': purchase.totalAmount,
          'previousBalance': previousBalance,
          'grandTotal': grandTotal,
          'paidAmount': paidAmount,
          'remainingAmount': remainingAmount,
          'isCredit': purchase.paymentMethod == 'credit',
          'purchaseId': purchase.id,
        });
      }

      return reportData;
    } catch (e) {
      debugPrint('Error generating purchase report: $e');
      return [];
    }
  }
}

/// Extension for enhanced transaction data
extension TransactionExtension on LedgerTransaction {
  Map<String, dynamic> toStatementRow(double runningBalance) {
    return {
      'date': date,
      'receiptNumber': receiptNumber ?? '',
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance': runningBalance,
      'origin': origin,
    };
  }
}
