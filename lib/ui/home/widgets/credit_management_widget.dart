import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class CreditManagementWidget extends ConsumerWidget {
  final AppDatabase db;

  const CreditManagementWidget({super.key, required this.db});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Credit Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'ملخص الديون',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: _CreditSummaryItem(
                          title: 'الديون المستحقة',
                          amount: 8500.0,
                          color: Colors.red,
                          count: 12,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _CreditSummaryItem(
                          title: 'الديون المدفوعة',
                          amount: 3200.0,
                          color: Colors.green,
                          count: 8,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: _CreditSummaryItem(
                          title: 'الديون المتأخرة',
                          amount: 2100.0,
                          color: Colors.orange,
                          count: 3,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: _CreditSummaryItem(
                          title: 'إجمالي الديون',
                          amount: 13800.0,
                          color: Colors.blue,
                          count: 23,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Gap(20),

          // Filter and Actions
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'بحث عن عميل',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Gap(16),
              DropdownButton<String>(
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'pending', child: Text('معلقة')),
                  DropdownMenuItem(value: 'overdue', child: Text('متأخرة')),
                  DropdownMenuItem(value: 'paid', child: Text('مدفوعة')),
                ],
                onChanged: (value) {
                  // Filter credits
                },
              ),
              const Gap(16),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddCreditDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة دين'),
              ),
            ],
          ),

          const Gap(20),

          // Credits List
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'قائمة الديون',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Export to PDF
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              tooltip: 'تصدير PDF',
                            ),
                            IconButton(
                              onPressed: () {
                                // Print
                              },
                              icon: const Icon(Icons.print),
                              tooltip: 'طباعة',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(16),
                    Expanded(
                      child: StreamBuilder<List<Customer>>(
                        stream: db.select(db.customers).watch(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data == null ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('لا يوجد عملاء حالياً'),
                            );
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final customer = snapshot.data![index];
                              return FutureBuilder<double>(
                                future: db.ledgerDao.getCustomerBalance(
                                  customer.id,
                                ),
                                builder: (context, balanceSnapshot) {
                                  final balance = balanceSnapshot.data ?? 0.0;
                                  final debt = balance > 0 ? balance : 0.0;
                                  final paid = balance < 0 ? -balance : 0.0;
                                  return _CreditTile(
                                    customer: customer,
                                    totalDebt: debt,
                                    paidAmount: paid,
                                    dueDate: DateTime.now().add(
                                      Duration(days: index + 1),
                                    ),
                                    status: debt > 0 ? 'pending' : 'paid',
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCreditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دين جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'اسم العميل',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(16),
            TextField(
              decoration: InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
                prefixText: 'ج.م',
              ),
              keyboardType: TextInputType.number,
            ),
            const Gap(16),
            TextField(
              decoration: InputDecoration(
                labelText: 'تاريخ الاستحقاق',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const Gap(16),
            TextField(
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إضافة الدين بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _CreditSummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final int count;

  const _CreditSummaryItem({
    required this.title,
    required this.amount,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
          const Gap(8),
          Text(
            '${amount.toStringAsFixed(2)} ج.م',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            '$count عميل',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  final Customer customer;
  final double totalDebt;
  final double paidAmount;
  final DateTime dueDate;
  final String status;

  const _CreditTile({
    required this.customer,
    required this.totalDebt,
    required this.paidAmount,
    required this.dueDate,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDebt = totalDebt - paidAmount;
    final isOverdue = status == 'overdue';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (customer.phone != null && customer.phone!.isNotEmpty)
                        Text(
                          customer.phone!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverdue ? 'متأخرة' : 'معلقة',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _CreditInfoItem(
                    title: 'إجمالي الدين',
                    value: '${totalDebt.toStringAsFixed(2)} ج.م',
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _CreditInfoItem(
                    title: 'المدفوع',
                    value: '${paidAmount.toStringAsFixed(2)} ج.م',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _CreditInfoItem(
                    title: 'المتبقي',
                    value: '${remainingDebt.toStringAsFixed(2)} ج.م',
                    color: remainingDebt > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const Gap(4),
                Text(
                  'تاريخ الاستحقاق: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Pay debt
                      },
                      icon: const Icon(Icons.payment),
                      tooltip: 'سداد الدين',
                    ),
                    IconButton(
                      onPressed: () {
                        // Edit credit
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'تعديل',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditInfoItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _CreditInfoItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
