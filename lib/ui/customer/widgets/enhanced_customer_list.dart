import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class EnhancedCustomerList extends ConsumerWidget {
  final List<Customer> customers;
  final Map<String, double> customerBalances;
  final Function(Customer) onCustomerSelected;
  final Function(Customer) onCustomerEdit;
  final VoidCallback? onAddPayment;
  final VoidCallback? onExportPdf;
  final VoidCallback? onRefresh;

  const EnhancedCustomerList({
    super.key,
    required this.customers,
    required this.customerBalances,
    required this.onCustomerSelected,
    required this.onCustomerEdit,
    required this.onAddPayment,
    required this.onExportPdf,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'قائمة العملاء',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh ?? () {},
                  tooltip: 'تحديث القائمة',
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'البحث عن العملاء...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          const Gap(16),

          // Customer List
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const Gap(16),
                        Text(
                          'لا يوجد عملاء',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final balance = customerBalances[customer.id] ?? 0.0;

                      return CustomerCard(
                        customer: customer,
                        balance: balance,
                        onTap: () => onCustomerSelected(customer),
                        onEdit: () => onCustomerEdit(customer),
                        onAddPayment: () => onAddPayment?.call(),
                        onExportPdf: () => onExportPdf?.call(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final double balance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onAddPayment;
  final VoidCallback? onExportPdf;
  final VoidCallback? onRefresh;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.balance,
    required this.onTap,
    required this.onEdit,
    this.onAddPayment,
    this.onExportPdf,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = balance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          customer.phone ?? 'لا يوجد هاتف',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Balance Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.1)
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الرصيد',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${balance.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(12),

              // Action Buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    tooltip: 'تعديل العميل',
                  ),
                  if (onAddPayment != null)
                    IconButton(
                      icon: const Icon(Icons.payment, size: 20),
                      onPressed: onAddPayment,
                      tooltip: 'إضافة دفعة',
                    ),
                  if (onExportPdf != null)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      onPressed: onExportPdf,
                      tooltip: 'تصدير PDF',
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
