import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:pos_offline_desktop/l10n/l10n.dart';

import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/ui/customer/services/customer_validation_service.dart';

class AddCustomerDialog extends StatefulWidget {
  final AppDatabase db;
  const AddCustomerDialog({super.key, required this.db});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Validate fields
        final nameValidation = CustomerValidationService.validateName(
          _nameController.text,
        );
        if (nameValidation != null) {
          CustomerErrorHandler.handleCustomerError(
            context,
            'Validation Error',
            customMessage: nameValidation,
          );
          return;
        }

        final phoneValidation = CustomerValidationService.validatePhone(
          _phoneController.text,
        );
        if (phoneValidation != null) {
          CustomerErrorHandler.handleCustomerError(
            context,
            'Validation Error',
            customMessage: phoneValidation,
          );
          return;
        }

        final customerId = DateTime.now().millisecondsSinceEpoch.toString();

        await widget.db.customerDao.insertCustomer(
          CustomersCompanion.insert(
            id: customerId,
            name: _nameController.text.trim(),
            phone: Value(_phoneController.text.trim()),
            status: const Value(1), // Active = 1
            isActive: const Value(true), // Active as boolean
            openingBalance: const Value(0.0),
          ),
        );

        if (mounted) {
          CustomerErrorHandler.showSuccessMessage(
            context,
            'تم حفظ العميل بنجاح',
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          CustomerErrorHandler.handleCustomerError(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.customer_name,
                  border: const OutlineInputBorder(),
                ),
                validator: CustomerValidationService.validateName,
              ),
              const Gap(16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: context.l10n.phone_number,
                  border: const OutlineInputBorder(),
                  counterText:
                      '', // Hides the default counter text below the field
                ),
                keyboardType: TextInputType.number,
                maxLength: 11, // Limit input length to 11
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only numbers
                  LengthLimitingTextInputFormatter(
                    11,
                  ), // Hard stop at 11 digits
                ],
                validator: CustomerValidationService.validatePhone,
              ),
              const Gap(16),

              const Gap(24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: _saveCustomer,
                    child: Text(context.l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
