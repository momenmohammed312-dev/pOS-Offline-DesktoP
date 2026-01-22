import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  final AppDatabase db;
  final Function(Customer)? onCustomerSelected;
  final VoidCallback? onRefresh;

  const CustomerDashboard({
    super.key,
    required this.db,
    this.onCustomerSelected,
    this.onRefresh,
  });

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  int _totalCustomers = 0;
  double _totalCustomerSales = 0.0;
  double _outstandingBalances = 0.0;
  List<Customer> _recentActiveCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Get total customers
      final customers = await widget.db.customerDao.getAllCustomers();

      // Get total customer sales (sum of all invoice amounts)
      final allInvoices = await widget.db.invoiceDao.getAllInvoices();
      final totalSales = allInvoices.fold<double>(
        0.0,
        (sum, invoice) => sum + invoice.totalAmount,
      );

      // Get outstanding balances (sum of POSITIVE customer balances)
      // Strict SOP: Positive = They Owe Us (Debt/Receivable)
      double outstanding = 0.0;
      for (final customer in customers) {
        try {
          final rawBalance = await widget.db.ledgerDao.getCustomerBalance(
            customer.id,
          );
          // Add opening balance
          final totalBalance = rawBalance + customer.openingBalance;

          if (totalBalance > 0) {
            outstanding += totalBalance;
          }
        } catch (e) {
          // Fallback
          if (customer.openingBalance > 0) {
            outstanding += customer.openingBalance;
          }
        }
      }

      // Get recent active customers (customers with recent transactions)
      final recentTransactions = await widget.db.ledgerDao
          .getRecentTransactions(30);
      final recentCustomerIds = recentTransactions
          .where((t) => t.entityType == 'Customer')
          .map((t) => t.refId)
          .toSet();

      final recentCustomers = customers
          .where((c) => recentCustomerIds.contains(c.id))
          .take(5)
          .toList();

      if (mounted) {
        setState(() {
          _totalCustomers = customers.length;
          _totalCustomerSales = totalSales;
          _outstandingBalances = outstanding;
          _recentActiveCustomers = recentCustomers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'لوحة تحكم العملاء',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: () {
                      widget.onRefresh?.call();
                      _loadDashboardData();
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث لوحة التحكم',
                  ),
              ],
            ),
            const Gap(24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'إجمالي العملاء',
                      _totalCustomers.toString(),
                      Icons.people,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _buildMetricCard(
                      'إجمالي مبيعات العملاء',
                      '${_totalCustomerSales.toStringAsFixed(2)} ج.م',
                      Icons.trending_up,
                      Colors.green.shade600,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _buildMetricCard(
                      'الأرصدة المستحقة',
                      '${_outstandingBalances.toStringAsFixed(2)} ج.م',
                      Icons.account_balance,
                      Colors.orange.shade600,
                    ),
                  ),
                ],
              ),

              const Gap(24),

              // Charts Row
              Row(
                children: [
                  Expanded(child: _buildCustomerStatusChart()),
                  const Gap(16),
                  Expanded(child: _buildBalanceDistributionChart()),
                ],
              ),

              const Gap(24),

              // Recent Active Customers Section
              Text(
                'العملاء النشطون مؤخراً',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Gap(12),

              if (_recentActiveCustomers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'لا يوجد نشاط مؤخر للعملاء',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActiveCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _recentActiveCustomers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : 'ع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        customer.phone ?? 'لا يوجد هاتف',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onTap: () => widget.onCustomerSelected?.call(customer),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatusChart() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'حالة العملاء',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Gap(16),
          // Simple pie chart representation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartSegment('نشط', Colors.green, 0.6),
              _buildChartSegment('غير نشط', Colors.orange, 0.3),
              _buildChartSegment('جديد', Colors.blue, 0.1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'توزيع الأرصدة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Gap(16),
          // Simple bar chart representation
          Column(
            children: [
              _buildBarSegment('0-1000', 0.4, Colors.green),
              const Gap(8),
              _buildBarSegment('1000-5000', 0.3, Colors.orange),
              const Gap(8),
              _buildBarSegment('5000+', 0.3, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSegment(String label, Color color, double percentage) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBarSegment(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const Gap(4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
