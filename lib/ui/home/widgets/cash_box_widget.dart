import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/ui/invoice/widgets/add_invoice_page.dart';

class CashBoxWidget extends ConsumerWidget {
  final AppDatabase db;

  const CashBoxWidget({super.key, required this.db});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Cash Summary
          StreamBuilder<double>(
            stream: db.ledgerDao.watchCurrentBalance(),
            builder: (context, snapshot) {
              final currentBalance = snapshot.data ?? 0.0;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'ملخص الكاش',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          Expanded(
                            child: _CashSummaryItem(
                              title: 'الرصيد الحالي',
                              amount: currentBalance,
                              color: currentBalance >= 0
                                  ? Colors.blue
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Gap(20),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    log('زرار المبيعات اتضغط');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddInvoiceDialog(db: db),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مبيعات +'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAddTransactionDialog(context, 'expense');
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('إضافة مصروفات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),

          const Gap(20),

          // Recent Transactions
          SizedBox(
            height: 400,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'آخر المعاملات',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              // Export transactions
                            },
                            icon: const Icon(Icons.download),
                          ),
                        ],
                      ),
                      const Gap(12),
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return _CashTransactionTile(
                              type: index % 3 == 0 ? 'sale' : 'expense',
                              description: index % 3 == 0
                                  ? 'فاتورة بيع #${100 + index}'
                                  : 'مصروفات ${['إيجار', 'كهرباء', 'مياه', 'إنترنت'][index % 4]}',
                              amount: (index + 1) * 150.0,
                              time: '10:${30 + index}',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, String type) {
    final isSale = type == 'sale';
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSale ? 'إضافة مبيعات' : 'إضافة مصروفات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: isSale ? 'وصف المبيعات' : 'وصف المصروفات',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(12),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
                prefixText: 'ج.م',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                try {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  final description = descriptionController.text.isNotEmpty
                      ? descriptionController.text
                      : (isSale ? 'مبيعات' : 'مصروفات');

                  // Add transaction to database
                  await db.ledgerDao.insertTransaction(
                    LedgerTransactionsCompanion.insert(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      entityType: 'Cash',
                      refId: 'cash_box',
                      date: DateTime.now(),
                      description: description,
                      debit: Value(isSale ? amount : 0.0),
                      credit: Value(!isSale ? amount : 0.0),
                      origin: isSale ? 'sale' : 'expense',
                      paymentMethod: Value('cash'),
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSale ? 'تمت إضافة المبيعات' : 'تمت إضافة المصروفات',
                        ),
                        backgroundColor: isSale ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _CashSummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _CashSummaryItem({
    required this.title,
    required this.amount,
    required this.color,
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
        ],
      ),
    );
  }
}

class _CashTransactionTile extends StatelessWidget {
  final String type;
  final String description;
  final double amount;
  final String time;

  const _CashTransactionTile({
    required this.type,
    required this.description,
    required this.amount,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = type == 'sale';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSale
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isSale ? Icons.arrow_upward : Icons.arrow_downward,
          color: isSale ? Colors.green : Colors.red,
        ),
      ),
      title: Text(description),
      subtitle: Text(time),
      trailing: Text(
        '${isSale ? '+' : '-'}${amount.toStringAsFixed(2)} ج.م',
        style: TextStyle(
          color: isSale ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
