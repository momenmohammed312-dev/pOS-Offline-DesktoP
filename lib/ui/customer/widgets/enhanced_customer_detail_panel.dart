import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/l10n/app_localizations.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/customer_transaction_list.dart';

class EnhancedCustomerDetailPanel extends ConsumerWidget {
  final Customer customer;
  final double balance;
  final AppDatabase db;
  final Function(Customer) onCustomerEdit;
  final VoidCallback? onAddPayment;
  final VoidCallback? onExportPdf;

  const EnhancedCustomerDetailPanel({
    super.key,
    required this.customer,
    required this.balance,
    required this.db,
    required this.onCustomerEdit,
    this.onAddPayment,
    this.onExportPdf,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Info Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      customer.phone?.isNotEmpty == true
                          ? customer.phone!
                          : 'No phone',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (customer.address?.isNotEmpty == true) ...[
                      const Gap(2),
                      Text(
                        customer.address!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const Gap(24),

          // Quick Contact Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.grey.shade600, size: 20),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer.phone?.isNotEmpty == true
                              ? customer.phone!
                              : l10n.no_phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.address,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          customer.address ?? 'No address',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Gap(24),

          // Balance Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: balance < 0
                    ? [Colors.red.shade50, Colors.red.shade100]
                    : [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.current_balance,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${balance.toStringAsFixed(2)} ${l10n.currency}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  balance < 0 ? l10n.overdue_balance : l10n.available_balance,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onCustomerEdit(customer),
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.edit_customer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const Gap(12),
              if (onAddPayment != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAddPayment?.call(),
                    icon: const Icon(Icons.payment),
                    label: Text(l10n.add_payment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const Gap(12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onExportPdf?.call(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l10n.export_pdf),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const Gap(24),

          // Transaction List
          Expanded(
            child: CustomerTransactionList(customer: customer, db: db),
          ),
        ],
      ),
    );
  }
}
