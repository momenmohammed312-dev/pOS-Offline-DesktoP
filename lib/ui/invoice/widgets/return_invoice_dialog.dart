import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class ReturnInvoiceDialog extends StatefulWidget {
  final AppDatabase db;
  final Function(Invoice) onInvoiceCreated;

  const ReturnInvoiceDialog({
    super.key,
    required this.db,
    required this.onInvoiceCreated,
  });

  @override
  State<ReturnInvoiceDialog> createState() => _ReturnInvoiceDialogState();
}

class _ReturnInvoiceDialogState extends State<ReturnInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _originalInvoiceController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  double _subtotal = 0.0;
  double _refundAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('فاتورة مرتجع'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Original Invoice Selection
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _originalInvoiceController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الفاتورة الأصلية',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchOriginalInvoice,
                      tooltip: 'البحث عن الفاتورة',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Customer Selection
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _customerController,
                        decoration: const InputDecoration(
                          labelText: 'العميل',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showCustomerSelection,
                      tooltip: 'إضافة عميل جديد',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Return Reason
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'سبب المرتجع',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),

              // Items Section
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المنتجات المرتجعة'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addItem,
                          tooltip: 'إضافة منتج',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildItemsList()),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Totals Section
              _buildTotalsSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _saveReturnInvoice, child: const Text('حفظ')),
      ],
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'لا توجد منتجات. أضف منتجاً باستخدام الزر +',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(4),
            child: ListTile(
              leading: const Icon(
                Icons.assignment_return,
                color: Colors.orange,
              ),
              title: TextFormField(
                initialValue: _items[index]['name'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _items[index]['name'] = value;
                  });
                },
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: (_items[index]['price'] ?? 0)
                          .toStringAsFixed(2),
                      decoration: const InputDecoration(
                        labelText: 'السعر (ج.م)',
                        border: OutlineInputBorder(),
                        prefixText: 'ج.م ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _items[index]['price'] =
                              double.tryParse(value) ?? 0.0;
                        });
                        _calculateTotals();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: (_items[index]['quantity'] ?? 1).toString(),
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _updateItemQuantity(index, value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeItem(index),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTotalRow('الإجمالي المرتجع:', _subtotal),
          const Divider(),
          _buildTotalRow('المبلغ المسترد:', _refundAmount),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            '${amount.toStringAsFixed(2)} ج.م',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    setState(() {
      _items.add({'name': 'منتج مرتجع', 'price': 0.0, 'quantity': 1});
    });
    _calculateTotals();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotals();
  }

  void _updateItemQuantity(int index, String? value) {
    final quantity = int.tryParse(value ?? '1') ?? 1;
    setState(() {
      _items[index]['quantity'] = quantity;
    });
    _calculateTotals();
  }

  void _calculateTotals() {
    _subtotal = _items.fold(0.0, (sum, item) {
      final price =
          (item['price'] as double? ?? 0.0) * (item['quantity'] as int? ?? 1);
      return sum + price;
    });

    _refundAmount = _subtotal;
  }

  void _searchOriginalInvoice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث عن الفاتورة الأصلية'),
        content: const Text('وظيفة البحث غير مفعلة حالياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelection() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار عميل'),
        content: const Text('وظيفة اختيار العميل غير مفعلة حالياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _saveReturnInvoice() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Create return invoice record
        final returnInvoice = InvoicesCompanion.insert(
          invoiceNumber: drift.Value(
            'RET-${DateTime.now().millisecondsSinceEpoch}',
          ),
          customerName: drift.Value(_customerController.text),
          customerContact: drift.Value('N/A'),
          totalAmount: drift.Value(_refundAmount),
          paidAmount: drift.Value(_refundAmount),
          date: drift.Value(DateTime.now()),
          status: drift.Value('returned'),
          paymentMethod: drift.Value('return'),
        );

        // Insert into database and get the ID
        final insertedId = await widget.db
            .into(widget.db.invoices)
            .insert(returnInvoice);

        // Create return invoice items
        for (final item in _items) {
          final returnItem = InvoiceItemsCompanion.insert(
            invoiceId: insertedId,
            productId: int.parse(item['productId'].toString()),
            quantity: drift.Value(item['quantity'] as int),
            price: item['price'] as double,
          );
          await widget.db.into(widget.db.invoiceItems).insert(returnItem);
        }

        // Update original invoice quantities if needed
        // This would require:
        // 1. Getting the original invoice items
        // 2. Finding the corresponding products
        // 3. Updating product quantities based on returned items
        // 4. Maintaining audit trail for returns
        // For now, this is a placeholder for future implementation

        final messengerContext = context;
        if (messengerContext.mounted) {
          Navigator.of(messengerContext).pop();
          ScaffoldMessenger.of(messengerContext).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ فاتورة المرتجع'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Get the created invoice to pass to callback
        final createdInvoice = await (widget.db.select(
          widget.db.invoices,
        )..where((tbl) => tbl.id.equals(insertedId))).getSingle();

        // Notify parent of new return invoice
        widget.onInvoiceCreated(createdInvoice);
      } catch (e) {
        final messengerContext = context;
        if (messengerContext.mounted) {
          ScaffoldMessenger.of(messengerContext).showSnackBar(
            SnackBar(
              content: Text('خطأ في حفظ الفاتورة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _originalInvoiceController.dispose();
    super.dispose();
  }
}
