import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/database/dao/supplier_dao.dart';

class SupplierFormDialog extends StatefulWidget {
  final AppDatabase database;
  final Supplier? supplier;

  const SupplierFormDialog({super.key, required this.database, this.supplier});

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _openingBalanceController;
  bool _isLoading = false;
  late final SupplierDao _supplierDao;

  @override
  void initState() {
    super.initState();
    _supplierDao = SupplierDao(widget.database);
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

  Future<void> _saveSupplier() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        if (widget.supplier == null) {
          // Add new supplier
          await _supplierDao.insertSupplier(
            SuppliersCompanion(
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
              createdAt: Value(DateTime.now()),
            ),
          );
        } else {
          // Update existing supplier
          await _supplierDao.updateSupplier(
            SuppliersCompanion(
              id: Value(widget.supplier!.id),
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
              status: Value(widget.supplier!.status),
              createdAt: Value(widget.supplier!.createdAt),
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حفظ المورد: $e'),
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSupplier,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
