import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:pos_offline_desktop/core/database/app_database.dart';

class SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;
  final Function(SuppliersCompanion) onSave;

  const SupplierFormDialog({super.key, this.supplier, required this.onSave});

  @override
  SupplierFormDialogState createState() => SupplierFormDialogState();
}

class SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _openingBalanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.supplier?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.supplier?.address ?? '',
    );
    _openingBalanceController = TextEditingController(
      text: (widget.supplier?.openingBalance ?? 0.0).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  void _saveSupplier() {
    if (_formKey.currentState?.validate() ?? false) {
      final supplier = SuppliersCompanion(
        id: Value(
          widget.supplier?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
        ),
        name: Value(_nameController.text.trim()),
        phone: _phoneController.text.trim().isNotEmpty
            ? Value(_phoneController.text.trim())
            : const Value.absent(),
        address: _addressController.text.trim().isNotEmpty
            ? Value(_addressController.text.trim())
            : const Value.absent(),
        openingBalance: Value(
          double.tryParse(_openingBalanceController.text) ?? 0.0,
        ),
        status: const Value('Active'),
        createdAt: Value(widget.supplier?.createdAt ?? DateTime.now()),
      );

      widget.onSave(supplier);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supplier == null ? 'إضافة مورد جديد' : 'تعديل المورد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المورد *',
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يجب إدخال اسم المورد';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _openingBalanceController,
                decoration: const InputDecoration(
                  labelText: 'الرصيد الافتتاحي',
                  border: OutlineInputBorder(),
                  prefixText: 'ج.م ',
                ),
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'يجب إدخال مبلغ صحيح';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _saveSupplier, child: const Text('حفظ')),
      ],
    );
  }
}
