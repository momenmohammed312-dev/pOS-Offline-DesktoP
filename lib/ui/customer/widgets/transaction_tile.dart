import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/transaction_display_model.dart';
import '../../../core/database/app_database.dart';

/// Individual transaction tile widget that matches the exact layout from the image
/// Shows amount, tag, description, date, and icon in the specified positions
/// Now includes nested table for transaction details
class TransactionTile extends ConsumerWidget {
  final TransactionDisplayModel transaction;
  final VoidCallback? onTap;
  final AppDatabase? db;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.db,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final amountColor = transaction.amount >= 0 ? Colors.green : Colors.red;
    final tagBgColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final tagTextColor = isDarkMode ? Colors.white : Colors.black87;

    // Icon background color based on transaction type
    Color iconBgColor;
    IconData iconData;
    if (transaction.origin == 'sale') {
      iconBgColor = Colors.red.shade100;
      iconData = Icons.shopping_cart;
    } else if (transaction.origin == 'payment') {
      iconBgColor = Colors.green.shade100;
      iconData = Icons.receipt;
    } else if (transaction.origin == 'opening') {
      iconBgColor = Colors.blue.shade100;
      iconData = Icons.account_balance;
    } else {
      iconBgColor = Colors.grey.shade100;
      iconData = Icons.description;
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
        child: Icon(
          iconData,
          size: 16,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Left column: Amount and tag
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    fontSize: 16,
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(6),
                if (transaction.tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.tag!,
                      style: TextStyle(
                        fontSize: 12,
                        color: tagTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const Gap(16),

            // Center area: Description or product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transaction.productDetails != null &&
                      transaction.productDetails!.isNotEmpty) ...[
                    // Show product details for sales
                    ...transaction.productDetails!
                        .take(3)
                        .map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              product,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    if (transaction.productDetails!.length > 3)
                      Text(
                        '... و ${transaction.productDetails!.length - 3} منتجات أخرى',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ] else if (transaction.description != null) ...[
                    // Show description for other transactions
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade200
                            : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    // Fallback
                    Text(
                      transaction.rightTitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade200
                            : Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Gap(16),

            // Right area: Bold title and date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.rightTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Gap(4),
                Text(
                  transaction.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // NESTED TABLE FOR TRANSACTION DETAILS
      children: [
        if (transaction.origin == 'sale' && db != null)
          FutureBuilder<List<InvoiceItem>>(
            future: _getTransactionDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'خطأ في تحميل التفاصيل: ${snapshot.error}',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'لا توجد منتجات لهذه المعاملة',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                child: Column(
                  children: [
                    // NESTED TABLE DESIGN
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {
                        0: FlexColumnWidth(4), // Product Name
                        1: FlexColumnWidth(1), // Qty
                        2: FlexColumnWidth(1), // Price
                        3: FlexColumnWidth(1), // Total
                      },
                      children: [
                        // Table Header
                        TableRow(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.blueGrey.shade800
                                : Colors.blueGrey.shade100,
                          ),
                          children: [
                            _cell(
                              "المنتج",
                              isHeader: true,
                              isDarkMode: isDarkMode,
                            ),
                            _cell(
                              "الكمية",
                              isHeader: true,
                              isDarkMode: isDarkMode,
                            ),
                            _cell(
                              "السعر",
                              isHeader: true,
                              isDarkMode: isDarkMode,
                            ),
                            _cell(
                              "الإجمالي",
                              isHeader: true,
                              isDarkMode: isDarkMode,
                            ),
                          ],
                        ),
                        // Dynamic Rows from DB
                        ...items.map(
                          (item) => TableRow(
                            children: [
                              _cell(
                                "منتج #${item.productId}",
                                isHeader: false,
                                isDarkMode: isDarkMode,
                              ),
                              _cell(
                                item.quantity.toString(),
                                isHeader: false,
                                isDarkMode: isDarkMode,
                              ),
                              _cell(
                                item.price.toStringAsFixed(2),
                                isHeader: false,
                                isDarkMode: isDarkMode,
                              ),
                              _cell(
                                (item.quantity * item.price).toStringAsFixed(2),
                                isHeader: false,
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    // PRINT ACTION BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.print),
                          label: const Text("طباعة التفاصيل"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              transaction.origin == 'sale'
                  ? 'لا توجد تفاصيل منتجات لهذه المعاملة'
                  : 'هذه المعاملة لا تحتوي على تفاصيل منتجات',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Future<List<InvoiceItem>> _getTransactionDetails() async {
    if (db == null) return [];

    try {
      // Try to find invoice by receipt number or date
      final invoices = await db!.invoiceDao.getInvoicesByDateRange(
        transaction.date.subtract(const Duration(days: 1)),
        transaction.date.add(const Duration(days: 1)),
      );

      // Try to find matching invoice by date and amount
      final matchingInvoice = invoices.firstWhere(
        (inv) =>
            inv.date.year == transaction.date.year &&
            inv.date.month == transaction.date.month &&
            inv.date.day == transaction.date.day &&
            inv.totalAmount.abs() == transaction.amount.abs(),
        orElse: () => throw Exception('No matching invoice found'),
      );

      return await db!.invoiceDao.getInvoiceItems(matchingInvoice.id);
    } catch (e) {
      return [];
    }
  }

  Widget _cell(
    String text, {
    required bool isHeader,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHeader
              ? (isDarkMode ? Colors.orange.shade300 : Colors.orange.shade800)
              : (isDarkMode ? Colors.white : Colors.black87),
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
