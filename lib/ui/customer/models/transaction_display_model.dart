import 'package:pos_offline_desktop/core/database/app_database.dart';

/// Display model for transactions that maps database rows to UI display format
/// This ensures consistent layout between UI and PDF generation
class TransactionDisplayModel {
  final String id;
  final double amount;
  final String type; // 'sale', 'payment', 'refund', etc.
  final String? tag; // Short label like 'سداد', 'مدين'
  final String? description;
  final DateTime date;
  final String? paymentMethod;
  final String? receiptNumber;
  final String? origin; // 'sale', 'purchase', 'payment', 'opening', 'reversal'
  final List<String>? productDetails; // For sales with product lists

  const TransactionDisplayModel({
    required this.id,
    required this.amount,
    required this.type,
    this.tag,
    this.description,
    required this.date,
    this.paymentMethod,
    this.receiptNumber,
    this.origin,
    this.productDetails,
  });

  /// Maps a LedgerTransaction to TransactionDisplayModel
  factory TransactionDisplayModel.fromLedgerTransaction(
    LedgerTransaction transaction,
  ) {
    // Determine tag based on transaction type and amount
    String? tag;
    if (transaction.origin == 'payment') {
      tag = 'سداد';
    } else if (transaction.origin == 'sale' && transaction.debit > 0) {
      tag = 'مدين';
    } else if (transaction.origin == 'sale' && transaction.credit > 0) {
      tag = 'سداد';
    } else if (transaction.origin == 'opening') {
      tag = 'رصيد افتتاحي';
    } else if (transaction.origin == 'reversal') {
      tag = 'تصحيح';
    }

    // Calculate net amount (positive for debit, negative for credit)
    final netAmount = transaction.debit - transaction.credit;

    return TransactionDisplayModel(
      id: transaction.id,
      amount: netAmount,
      type: transaction.origin,
      tag: tag,
      description: transaction.description,
      date: transaction.date,
      paymentMethod: transaction.paymentMethod,
      receiptNumber: transaction.receiptNumber,
      origin: transaction.origin,
    );
  }

  /// Maps an Invoice to TransactionDisplayModel
  factory TransactionDisplayModel.fromInvoice(
    Invoice invoice, {
    List<String>? productDetails,
  }) {
    // Determine tag and amount based on invoice status and amounts
    String? tag;
    double amount = 0.0;

    if (invoice.status == 'posted') {
      if (invoice.totalAmount > 0) {
        amount = invoice.totalAmount;
        tag = 'مدين';
      }
    }

    return TransactionDisplayModel(
      id: invoice.id.toString(),
      amount: amount,
      type: 'sale',
      tag: tag,
      description:
          'فاتورة رقم ${invoice.invoiceNumber ?? invoice.id.toString()}',
      date: invoice.date,
      paymentMethod: invoice.paymentMethod,
      receiptNumber: invoice.invoiceNumber,
      origin: 'sale',
      productDetails: productDetails,
    );
  }

  /// Get amount color (green for positive, red for negative)
  String get amountColor {
    return amount >= 0 ? 'green' : 'red';
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    final absAmount = amount.abs();
    final prefix = amount >= 0 ? '' : '-';
    return '$prefix${absAmount.toStringAsFixed(2)} ج.م';
  }

  /// Get right title (bold description)
  String get rightTitle {
    if (origin == 'payment') {
      return 'سداد قيمة';
    } else if (origin == 'sale') {
      return description ?? 'بيع';
    } else if (origin == 'opening') {
      return 'رصيد افتتاحي';
    } else {
      return description ?? '';
    }
  }

  /// Get formatted date
  String get formattedDate {
    return '${date.year.toString().padLeft(4, '0')}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// Get icon type for display
  String get iconType {
    if (origin == 'sale') {
      return 'shopping_cart';
    } else if (origin == 'payment') {
      return 'receipt';
    } else if (origin == 'opening') {
      return 'account_balance';
    } else {
      return 'description';
    }
  }

  /// Get icon background color
  String get iconBackgroundColor {
    if (origin == 'sale') {
      return 'red';
    } else if (origin == 'payment') {
      return 'green';
    } else {
      return 'blue';
    }
  }
}
