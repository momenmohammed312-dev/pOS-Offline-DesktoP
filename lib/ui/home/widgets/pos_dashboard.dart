import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/l10n/app_localizations.dart';
import 'package:pos_offline_desktop/ui/invoice/widgets/add_invoice_page.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/add_customer_page.dart';
import 'package:pos_offline_desktop/ui/product/widgets/add_product_page.dart';

class POSDashboard extends ConsumerWidget {
  final AppDatabase db;

  const POSDashboard({super.key, required this.db});

  // Stream to get today's sales total
  Stream<double> _getTodaySalesTotal() {
    return (db.select(
      db.ledgerTransactions,
    )..where((tbl) => tbl.origin.equals('sale'))).watch().map((transactions) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      return transactions
          .where(
            (t) => t.date.isAfter(startOfDay.subtract(const Duration(days: 1))),
          )
          .fold(0.0, (sum, t) => sum + t.debit);
    });
  }

  // Stream to get today's expenses
  Stream<double> _getTodayExpenses() {
    return (db.select(
      db.ledgerTransactions,
    )..where((tbl) => tbl.origin.equals('expense'))).watch().map((
      transactions,
    ) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      return transactions
          .where(
            (t) => t.date.isAfter(startOfDay.subtract(const Duration(days: 1))),
          )
          .fold(0.0, (sum, t) => sum + t.credit);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _DynamicStatCard(
                    title: l10n.today_sales,
                    stream: _getTodaySalesTotal(),
                    icon: Icons.trending_up,
                    color: Colors.green,
                    formatter: (value) =>
                        '${value.toStringAsFixed(2)} ${l10n.currency}',
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _DynamicStatCard(
                    title: l10n.today_expenses,
                    stream: _getTodayExpenses(),
                    icon: Icons.trending_down,
                    color: Colors.red,
                    formatter: (value) =>
                        '${value.toStringAsFixed(2)} ${l10n.currency}',
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: StreamBuilder<double>(
                    stream: db.ledgerDao.watchCurrentBalance(),
                    builder: (context, snapshot) {
                      final balance = snapshot.data ?? 0.0;
                      final title = balance >= 0
                          ? l10n.receivable_label
                          : l10n.payable_label;
                      return _DynamicStatCard(
                        title: title,
                        stream: db.ledgerDao.watchCurrentBalance(),
                        icon: Icons.account_balance_wallet,
                        color: balance >= 0 ? Colors.purple : Colors.deepOrange,
                        formatter: (value) =>
                            '${value.abs().toStringAsFixed(2)} ${l10n.currency}',
                      );
                    },
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Quick Actions
            Text(
              l10n.quick_actions,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    title: l10n.new_invoice,
                    color: Colors.blue,
                    onTap: () async {
                      final isOpen = await db.dayDao.isDayOpen();
                      if (!isOpen) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.day_is_closed),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: AddInvoiceDialog(db: db),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_add,
                    title: l10n.add_customer,
                    color: Colors.green,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: AddCustomerDialog(db: db),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.inventory_2,
                    title: l10n.add_product,
                    color: Colors.orange,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: AddProductDialog(db: db),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const Gap(16),

            // Recent Transactions
            SizedBox(
              height: 300,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.last_transactions,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Gap(16),
                      Expanded(
                        child: StreamBuilder<List<LedgerTransaction>>(
                          stream: db.ledgerDao.watchAllTransactions(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text(l10n.no_transactions));
                            }
                            final transactions = snapshot.data!;
                            return ListView.builder(
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = transactions[index];
                                return _TransactionTile(
                                  customerName: transaction.description,
                                  amount: transaction.debit > 0
                                      ? transaction.debit
                                      : transaction.credit,
                                  time: DateFormat(
                                    'HH:mm',
                                  ).format(transaction.date),
                                  type: transaction.debit > 0
                                      ? l10n.sale
                                      : l10n.purchase,
                                  l10n: l10n,
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
      ),
    );
  }
}

class _DynamicStatCard<T> extends StatelessWidget {
  final String title;
  final Stream<T> stream;
  final IconData icon;
  final Color color;
  final String Function(T) formatter;

  const _DynamicStatCard({
    required this.title,
    required this.stream,
    required this.icon,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        T value;
        if (T == double) {
          value = (snapshot.data ?? 0.0) as T;
        } else if (T == int) {
          value = (snapshot.data ?? 0) as T;
        } else {
          value = snapshot.data ?? ('' as T);
        }
        final displayValue = formatter(value);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const Spacer(),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                  ],
                ),
                const Gap(12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Gap(4),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Gap(8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String customerName;
  final double amount;
  final String time;
  final String type;
  final AppLocalizations l10n;

  const _TransactionTile({
    required this.customerName,
    required this.amount,
    required this.time,
    required this.type,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isSale = type == l10n.sale;
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
      title: Text(customerName),
      subtitle: Text(time),
      trailing: Text(
        '${isSale ? '+' : '-'}${amount.toStringAsFixed(2)} ${l10n.currency}',
        style: TextStyle(
          color: isSale ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
