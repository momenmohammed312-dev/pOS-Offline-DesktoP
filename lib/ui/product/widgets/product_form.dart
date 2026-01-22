import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/l10n/l10n.dart';

class ProductForm extends StatefulWidget {
  final Product? product; // لو null → إضافة، لو مش null → تعديل
  final AppDatabase db;

  const ProductForm({super.key, this.product, required this.db});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController quantityCtrl;
  String selectedStatus = 'Active';

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    priceCtrl = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    quantityCtrl = TextEditingController(
      text: widget.product?.quantity.toString() ?? '',
    );
    selectedStatus = widget.product?.status ?? 'Active';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.product == null) {
          // إضافة
          await widget.db.productDao.insertProduct(
            ProductsCompanion.insert(
              name: nameCtrl.text,
              price: double.parse(priceCtrl.text),
              quantity: int.parse(quantityCtrl.text),
              status: Value(selectedStatus),
            ),
          );
        } else {
          // تعديل
          await widget.db.productDao.updateProduct(
            widget.product!.copyWith(
              name: nameCtrl.text,
              price: double.parse(priceCtrl.text),
              quantity: int.parse(quantityCtrl.text),
              status: Value(selectedStatus),
            ),
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.product == null
                    ? context.l10n.save_product
                    : context.l10n.product_updated_successfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.l10n.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null
              ? context.l10n.add_product
              : context.l10n.edit_product,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: context.l10n.product_name,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.enter_valid_product_name;
                  }
                  return null;
                },
              ),
              const Gap(16),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.l10n.price,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.enter_valid_price;
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) < 0) {
                    return context.l10n.enter_valid_price;
                  }
                  return null;
                },
              ),
              const Gap(16),
              TextFormField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.quantity,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.enter_valid_quantity;
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return context.l10n.enter_valid_quantity;
                  }
                  return null;
                },
              ),
              const Gap(16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: context.l10n.status,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.toggle_on),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'Active',
                    child: Text(context.l10n.active),
                  ),
                  DropdownMenuItem(
                    value: 'Inactive',
                    child: Text(context.l10n.inactive),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
              const Gap(24),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.product == null
                      ? context.l10n.save_product
                      : context.l10n.update_product,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
