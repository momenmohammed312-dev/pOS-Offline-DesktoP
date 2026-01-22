import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class TaxInvoiceDialog extends StatefulWidget {
  final AppDatabase db;
  final Function(Invoice) onInvoiceCreated;

  const TaxInvoiceDialog({
    super.key,
    required this.db,
    required this.onInvoiceCreated,
  });

  @override
  State<TaxInvoiceDialog> createState() => _TaxInvoiceDialogState();
}

class _TaxInvoiceDialogState extends State<TaxInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  double _subtotal = 0.0;
  double _taxRate = 0.14;
  double _taxAmount = 0.0;
  double _total = 0.0;
  final double _paidAmount = 0.0;
  double _change = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('فاتورة ضريبية'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

              // Tax Rate Input
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.percent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _taxRate.toStringAsFixed(2),
                        decoration: const InputDecoration(
                          labelText: 'نسبة الضريبة (%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateTaxRate(value),
                      ),
                    ),
                  ],
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
                        const Text('المنتجات'),
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
        ElevatedButton(onPressed: _saveInvoice, child: const Text('حفظ')),
      ],
    );
  }

  Widget _buildItemsList() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.shopping_cart),
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
                    initialValue: (_items[index]['price'] ?? 0).toStringAsFixed(
                      2,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'السعر (ج.م)',
                      border: OutlineInputBorder(),
                      prefixText: 'ج.م ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _items[index]['price'] = double.tryParse(value) ?? 0.0;
                      });
                      _calculateTotals();
                    },
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          _buildTotalRow('الإجمالي:', _subtotal),
          _buildTotalRow('مبلغ الضريبة:', _taxAmount),
          _buildTotalRow('الإجمالي:', _total),
          _buildTotalRow('المدفوع:', _paidAmount),
          _buildTotalRow('الباقي:', _change),
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
      _items.add({'name': 'منتج جديد', 'price': 0.0, 'quantity': 1});
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

    _taxAmount = _subtotal * _taxRate;
    _total = _subtotal + _taxAmount;

    // Calculate change based on paid amount
    _change = _paidAmount - _total;
  }

  void _updateTaxRate(String? value) {
    final rate = double.tryParse(value ?? '14') ?? 14.0;
    setState(() {
      _taxRate = rate / 100.0; // Convert percentage to decimal
    });
    _calculateTotals();
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

  void _saveInvoice() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Create tax invoice record
        final taxInvoice = InvoicesCompanion.insert(
          invoiceNumber: drift.Value(
            'TAX-${DateTime.now().millisecondsSinceEpoch}',
          ),
          customerName: drift.Value(_customerController.text),
          customerContact: drift.Value('N/A'),
          totalAmount: drift.Value(_total),
          paidAmount: drift.Value(_paidAmount),
          date: drift.Value(DateTime.now()),
          status: drift.Value('paid'),
          paymentMethod: drift.Value('tax'),
        );

        // Insert into database and get the ID
        final insertedId = await widget.db
            .into(widget.db.invoices)
            .insert(taxInvoice);

        // Create tax invoice items
        for (final item in _items) {
          final taxItem = InvoiceItemsCompanion.insert(
            invoiceId: insertedId,
            productId: int.parse(item['productId'].toString()),
            quantity: drift.Value(item['quantity'] as int),
            price: item['price'] as double,
          );
          await widget.db.into(widget.db.invoiceItems).insert(taxItem);
        }

        final messengerContext = context;
        if (messengerContext.mounted) {
          Navigator.of(messengerContext).pop();
          ScaffoldMessenger.of(messengerContext).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ الفاتورة الضريبية'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Get the created invoice to pass to callback
        final createdInvoice = await (widget.db.select(
          widget.db.invoices,
        )..where((tbl) => tbl.id.equals(insertedId))).getSingle();

        // Notify parent of new tax invoice
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
}
