import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import 'package:pos_offline_desktop/core/database/dao/ledger_dao.dart';

class SupplierPaymentDialog extends StatefulWidget {
  final AppDatabase database;
  final Supplier supplier;

  const SupplierPaymentDialog({
    super.key,
    required this.database,
    required this.supplier,
  });

  @override
  State<SupplierPaymentDialog> createState() => _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState extends State<SupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  bool _isLoading = false;
  late final LedgerDao _ledgerDao;
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _ledgerDao = LedgerDao(widget.database);
    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _makePayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final amount = double.tryParse(_amountController.text) ?? 0.0;
        final paymentId = DateTime.now().millisecondsSinceEpoch.toString();

        // Add payment transaction to ledger
        await _ledgerDao.insertTransaction(
          LedgerTransactionsCompanion.insert(
            id: '${paymentId}_ledger',
            entityType: 'Supplier',
            refId: widget.supplier.id,
            date: DateTime.now(),
            description:
                'سداد قيمة للمورد (${_paymentMethod == 'cash'
                    ? 'نقدي'
                    : _paymentMethod == 'bank_transfer'
                    ? 'تحويل بنكي'
                    : 'شيك'}): ${_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'دفعة'}',
            debit: drift.Value(amount), // Debit reduces supplier balance
            credit: const drift.Value(0.0),
            origin: 'payment',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل الدفعة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تسجيل الدفعة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('سداد قيمة للمورد: ${widget.supplier.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الرصيد الحالي: ${widget.supplier.openingBalance.toStringAsFixed(2)} ج.م',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.supplier.openingBalance > 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'مبلغ الدفعة *',
                  border: OutlineInputBorder(),
                  prefixText: 'ج.م ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يجب إدخال مبلغ الدفعة';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'يجب إدخال مبلغ صحيح أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('تحويل بنكي'),
                  ),
                  DropdownMenuItem(value: 'check', child: Text('شيك')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _makePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('سداد'),
        ),
      ],
    );
  }
}
