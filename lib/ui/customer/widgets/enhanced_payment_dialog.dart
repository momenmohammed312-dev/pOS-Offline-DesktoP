import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/l10n/app_localizations.dart';

class EnhancedPaymentDialog extends StatefulWidget {
  final Customer customer;
  final double outstandingBalance;
  final Function(double amount, String note)? onPaymentConfirmed;

  const EnhancedPaymentDialog({
    super.key,
    required this.customer,
    required this.outstandingBalance,
    this.onPaymentConfirmed,
  });

  @override
  State<EnhancedPaymentDialog> createState() => _EnhancedPaymentDialogState();
}

class _EnhancedPaymentDialogState extends State<EnhancedPaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _enteredAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _enteredAmount = 0.0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    setState(() {
      _enteredAmount = double.tryParse(value) ?? 0.0;
    });
  }

  bool _isAmountValid() {
    return _enteredAmount > 0;
  }

  bool _isAmountExceedsBalance() {
    return _enteredAmount > widget.outstandingBalance;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const Gap(12),
                Text(
                  'Payment for: ${widget.customer.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Warning Message
            if (_isAmountExceedsBalance())
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Amount exceeds outstanding balance of ${widget.outstandingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Field
                  Text(
                    l10n.amount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: l10n.enter_amount,
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: _onAmountChanged,
                  ),
                  const Gap(8),

                  // Note Field
                  Text(
                    l10n.note_optional,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.enter_note,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  const Gap(16),

                  // Warning Text
                  if (_isAmountExceedsBalance())
                    Text(
                      'Proceeding will exceed balance by ${(_enteredAmount - widget.outstandingBalance).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                ],
              ),
            ),

            const Gap(24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const Gap(16),
                ElevatedButton(
                  onPressed: _isAmountValid() && !_isAmountExceedsBalance()
                      ? () {
                          if (widget.onPaymentConfirmed == null) return;

                          Navigator.of(context).pop();
                          widget.onPaymentConfirmed!(
                            _enteredAmount,
                            _noteController.text,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isAmountValid() && !_isAmountExceedsBalance()
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.confirm_payment),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
