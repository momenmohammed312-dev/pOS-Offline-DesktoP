import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/printer_service.dart';

class TransactionExpansionTile extends StatefulWidget {
  final LedgerTransaction transaction;
  final bool isPurchase;
  final bool isSale;
  final AppDatabase db;
  final Customer customer;

  const TransactionExpansionTile({
    super.key,
    required this.transaction,
    required this.isPurchase,
    required this.isSale,
    required this.db,
    required this.customer,
  });

  @override
  State<TransactionExpansionTile> createState() =>
      TransactionExpansionTileState();
}

class TransactionExpansionTileState extends State<TransactionExpansionTile> {
  bool _isExpanded = false;
  List<(InvoiceItem, Product?)> _invoiceItems = [];
  bool _isLoadingItems = false;

  Future<void> _loadInvoiceItems() async {
    if (_isExpanded && widget.isSale && _invoiceItems.isEmpty) {
      setState(() => _isLoadingItems = true);
      try {
        final invoiceId = _extractInvoiceId();
        debugPrint('Loading invoice items for invoice ID: $invoiceId');

        if (invoiceId != null) {
          debugPrint('Fetching items from database...');
          final items = await widget.db.invoiceDao
              .getItemsWithProductsByInvoice(invoiceId);
          debugPrint('Found ${items.length} items for invoice $invoiceId');

          setState(() {
            _invoiceItems = items;
            _isLoadingItems = false;
          });
        } else {
          debugPrint('No invoice ID found, cannot load items');
          setState(() => _isLoadingItems = false);
        }
      } catch (e) {
        debugPrint('Error loading invoice items: $e');
        setState(() => _isLoadingItems = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading invoice items: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  int? _extractInvoiceId() {
    // Debug logging to understand the data structure
    debugPrint('=== Invoice ID Extraction Debug ===');
    debugPrint('Transaction ID: ${widget.transaction.id}');
    debugPrint('Receipt Number: ${widget.transaction.receiptNumber}');
    debugPrint('Description: ${widget.transaction.description}');
    debugPrint('Origin: ${widget.transaction.origin}');

    // Method 1: Try receiptNumber first (most reliable)
    if (widget.transaction.receiptNumber != null &&
        widget.transaction.receiptNumber!.isNotEmpty) {
      final receiptNum = widget.transaction.receiptNumber!;
      debugPrint('Trying receiptNumber: $receiptNum');

      // Try to extract numeric ID from receipt number
      final match = RegExp(r'\d+').firstMatch(receiptNum);
      if (match != null) {
        final extractedId = int.tryParse(match.group(0) ?? '');
        debugPrint('Extracted ID from receiptNumber: $extractedId');
        if (extractedId != null) return extractedId;
      }

      // Try direct parsing if receiptNumber is just the ID
      final directId = int.tryParse(receiptNum);
      debugPrint('Direct parse from receiptNumber: $directId');
      if (directId != null) return directId;

      // Try extracting from patterns like "INV-123" or "فاتورة-123"
      final invMatch = RegExp(
        r'(?:INV|فاتورة|invoice)?[-\s]?(\d+)',
        caseSensitive: false,
      ).firstMatch(receiptNum);
      if (invMatch != null) {
        final extractedId = int.tryParse(invMatch.group(1) ?? '');
        debugPrint('Extracted ID from pattern: $extractedId');
        if (extractedId != null) return extractedId;
      }
    }

    // Method 2: Try description field (fallback)
    final desc = widget.transaction.description;
    debugPrint('Trying description field: $desc');

    if (desc.contains('#')) {
      final parts = desc.split('#');
      if (parts.length > 1) {
        final afterHash = parts[1].split(' ')[0];
        final extractedId = int.tryParse(afterHash);
        debugPrint('Extracted ID from description: $extractedId');
        if (extractedId != null) return extractedId;
      }
    }

    // Method 3: Try extracting from transaction ID itself (if it's actually the invoice ID)
    if (widget.transaction.id.isNotEmpty) {
      // Check if transaction ID itself is a numeric invoice ID
      final idMatch = RegExp(r'^\d+$').firstMatch(widget.transaction.id);
      if (idMatch != null) {
        final extractedId = int.tryParse(widget.transaction.id);
        debugPrint('Transaction ID itself is numeric: $extractedId');
        if (extractedId != null) return extractedId;
      }
    }

    // Method 4: Try extracting from description with different patterns
    if (desc.isNotEmpty) {
      // Look for patterns like "فاتورة مبيعات #123"
      final descMatch = RegExp(r'#(\d+)').firstMatch(desc);
      if (descMatch != null) {
        final extractedId = int.tryParse(descMatch.group(1) ?? '');
        debugPrint('Extracted ID from description pattern: $extractedId');
        if (extractedId != null) return extractedId;
      }

      // Look for any standalone numbers in description
      final numberMatch = RegExp(r'(\d+)').firstMatch(desc);
      if (numberMatch != null) {
        final extractedId = int.tryParse(numberMatch.group(1) ?? '');
        debugPrint('Extracted ID from description numbers: $extractedId');
        if (extractedId != null) return extractedId;
      }
    }

    debugPrint('=== No invoice ID found ===');
    return null;
  }

  Future<void> _printInvoice() async {
    try {
      final invoiceId = _extractInvoiceId();
      if (invoiceId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن العثور على رقم الفاتورة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final invoices = await widget.db.invoiceDao.getInvoicesByDateRange(
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now(),
      );
      final invoice = invoices.firstWhere(
        (inv) =>
            inv.id == invoiceId || inv.invoiceNumber == invoiceId.toString(),
        orElse: () => throw Exception('Invoice not found'),
      );

      final itemsWithProducts = await widget.db.invoiceDao
          .getItemsWithProductsByInvoice(invoice.id);

      final itemsMaps = itemsWithProducts.map((itemWithProduct) {
        final item = itemWithProduct.$1;
        final product = itemWithProduct.$2;
        final unitPrice = item.quantity > 0
            ? item.price / item.quantity
            : item.price;

        return {
          'productName': product?.name ?? 'Product ${item.productId}',
          'name': product?.name ?? 'Product ${item.productId}',
          'quantity': item.quantity,
          'price': unitPrice,
          'total': item.price,
        };
      }).toList();

      await PrinterService.autoPrintInvoice(
        invoice: {
          'id': invoice.id,
          'customerName': invoice.customerName,
          'date': invoice.date,
          'totalAmount': invoice.totalAmount,
          'paymentMethod': invoice.paymentMethod,
        },
        items: itemsMaps,
        paymentMethod: invoice.paymentMethod ?? 'cash',
        ledgerDao: widget.db.ledgerDao,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الفاتورة للطباعة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaymentTransaction = widget.transaction.origin == 'payment';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: widget.isPurchase
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.1),
          child: Icon(
            widget.isPurchase ? Icons.shopping_cart : Icons.payment,
            color: widget.isPurchase ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          widget.transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${widget.transaction.date.day}/${widget.transaction.date.month}/${widget.transaction.date.year}',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(widget.isPurchase ? widget.transaction.debit : widget.transaction.credit).toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    color: widget.isPurchase ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (widget.isPurchase ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaymentTransaction
                        ? 'سداد'
                        : (widget.isPurchase ? 'مدين' : 'مدفوع'),
                    style: TextStyle(
                      color: widget.isPurchase ? Colors.orange : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isSale && !isPaymentTransaction) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                onPressed: _printInvoice,
                tooltip: 'طباعة الفاتورة',
              ),
            ],
          ],
        ),
        onExpansionChanged: isPaymentTransaction
            ? null
            : (expanded) {
                setState(() => _isExpanded = expanded);
                if (expanded) {
                  _loadInvoiceItems();
                }
              },
        children: [
          if (widget.isSale && !isPaymentTransaction)
            _buildProductDetailsSection()
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('لا توجد تفاصيل منتجات لهذه المعاملة'),
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsSection() {
    if (_isLoadingItems) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoiceItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('لا توجد منتجات في هذه الفاتورة'),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل المنتجات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Colors.grey.withValues(alpha: 0.1),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'اسم المنتج',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الكمية',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'سعر الوحدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الإجمالي',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _invoiceItems.map((itemWithProduct) {
                final item = itemWithProduct.$1;
                final product = itemWithProduct.$2;
                final unitPrice = item.quantity > 0
                    ? item.price / item.quantity
                    : item.price; // If quantity is 0 or less, use total price as unit price

                return DataRow(
                  cells: [
                    DataCell(Text(product?.name ?? 'منتج ${item.productId}')),
                    DataCell(Text(item.quantity.toString())),
                    DataCell(Text('${unitPrice.toStringAsFixed(2)} ج.م')),
                    DataCell(
                      Text(
                        '${item.price.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
