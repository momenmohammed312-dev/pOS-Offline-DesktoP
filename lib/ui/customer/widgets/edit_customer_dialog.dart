import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/l10n/l10n.dart';
import 'package:pos_offline_desktop/ui/home/widgets/text_formatter.dart';
import 'package:pos_offline_desktop/ui/customer/services/customer_validation_service.dart';

class EditCustomerDialog extends StatefulWidget {
  final Customer customer;
  final Function(CustomersCompanion)? onCustomerUpdated;

  const EditCustomerDialog({
    super.key,
    required this.customer,
    this.onCustomerUpdated,
  });

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _addressController = TextEditingController(
      text: widget.customer.address ?? '',
    );
    _gstinController = TextEditingController(
      text: widget.customer.gstinNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();

    super.dispose();
  }

  void _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Validate all fields
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

        final addressValidation = CustomerValidationService.validateAddress(
          _addressController.text,
        );
        if (addressValidation != null) {
          CustomerErrorHandler.handleCustomerError(
            context,
            'Validation Error',
            customMessage: addressValidation,
          );
          return;
        }

        final gstinValidation = CustomerValidationService.validateGstin(
          _gstinController.text,
        );
        if (gstinValidation != null) {
          CustomerErrorHandler.handleCustomerError(
            context,
            'Validation Error',
            customMessage: gstinValidation,
          );
          return;
        }

        final updatedData = CustomersCompanion(
          id: Value(widget.customer.id),
          name: Value(_nameController.text.trim()),
          phone: Value(_phoneController.text.trim()),
          address: (_addressController.text.isNotEmpty)
              ? Value(_addressController.text.trim())
              : const Value.absent(),
          gstinNumber: (_gstinController.text.isNotEmpty)
              ? Value(_gstinController.text.trim())
              : const Value.absent(),
          createdAt: const Value.absent(), // Prevent createdAt update
        );

        if (widget.onCustomerUpdated != null) {
          widget.onCustomerUpdated!(updatedData);
        }

        CustomerErrorHandler.showSuccessMessage(
          context,
          'تم تحديث بيانات العميل بنجاح',
        );
        Navigator.of(context).pop(updatedData);
      } catch (e) {
        CustomerErrorHandler.handleCustomerError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.customer_name,
                  border: const OutlineInputBorder(),
                ),
                validator: CustomerValidationService.validateName,
              ),
              const Gap(16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: context.l10n.phone_number,
                  border: const OutlineInputBorder(),
                  counterText:
                      '', // Hides the default counter text below the field
                ),
                keyboardType: TextInputType.number,
                maxLength: 10, // Limit input length to 10
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only numbers
                  LengthLimitingTextInputFormatter(
                    10,
                  ), // Hard stop at 10 digits
                ],
                validator: CustomerValidationService.validatePhone,
              ),
              const Gap(16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: context.l10n.address,
                  border: const OutlineInputBorder(),
                ),
                validator: CustomerValidationService.validateAddress,
              ),
              const Gap(16),
              TextFormField(
                controller: _gstinController,
                decoration: InputDecoration(
                  labelText: context.l10n.gstin,
                  border: const OutlineInputBorder(),
                  counterText: '', // Hides the default counter text
                ),
                maxLength: 15,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(15),
                ],
                textCapitalization: TextCapitalization.characters,
                validator: CustomerValidationService.validateGstin,
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: _saveChanges,

                    child: Text(context.l10n.save_customer),
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
