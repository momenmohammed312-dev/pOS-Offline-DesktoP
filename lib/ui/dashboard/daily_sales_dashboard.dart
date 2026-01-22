import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';
import 'package:pos_offline_desktop/core/services/daily_sales_service.dart';
import 'package:pos_offline_desktop/ui/widgets/daily_sales_calendar.dart';

class DailySalesDashboard extends ConsumerStatefulWidget {
  const DailySalesDashboard({super.key});

  @override
  ConsumerState<DailySalesDashboard> createState() =>
      _DailySalesDashboardState();
}

class _DailySalesDashboardState extends ConsumerState<DailySalesDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DailySalesService _dailySalesService;

  // Data
  double _todaySales = 0.0;
  int _todaySalesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final db = ref.read(appDatabaseProvider);
    _dailySalesService = DailySalesService(db);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final todaySales = await _dailySalesService.getTodaySales();
      final todayCount = await _dailySalesService.getTodaySalesCount();

      setState(() {
        _todaySales = todaySales;
        _todaySalesCount = todayCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المبيعات اليومية'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ملخص اليوم'),
            Tab(text: 'تقويم المبيعات'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodaySummary(),
          DailySalesCalendar(db: ref.read(appDatabaseProvider)),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Date Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                  const Gap(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مبيعات اليوم',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Gap(24),

          // Sales Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'إجمالي المبيعات',
                  '${_todaySales.toStringAsFixed(2)} ج.م',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildSummaryCard(
                  'عدد الفواتير',
                  '$_todaySalesCount',
                  Icons.receipt,
                  Colors.blue,
                ),
              ),
            ],
          ),

          const Gap(16),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'متوسط الفاتورة',
                  _todaySalesCount > 0
                      ? '${(_todaySales / _todaySalesCount).toStringAsFixed(2)} ج.م'
                      : '0.00 ج.م',
                  Icons.calculate,
                  Colors.orange,
                ),
              ),
              const Gap(16),
              Expanded(
                child: _buildSummaryCard(
                  'حالة اليوم',
                  _todaySales > 0
                      ? 'مبيعات نشطة'
                      : '${_todaySales.toStringAsFixed(2)} ج.م',
                  _todaySales > 0 ? Icons.trending_up : Icons.trending_flat,
                  _todaySales > 0 ? Colors.purple : Colors.grey,
                ),
              ),
            ],
          ),

          const Gap(24),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجراءات سريعة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/cashier');
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('بيع جديد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/invoices');
                          },
                          icon: const Icon(Icons.list),
                          label: const Text('عرض الفواتير'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Gap(16),

          // Today's Status Message
          if (_todaySales == 0)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade700),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'إجمالي المبيعات اليوم: ${_todaySales.toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                          color: _todaySales > 0
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'ممتاز! اليوم لديك $_todaySalesCount عملية بيع بقيمة $_todaySales ج.م',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const Gap(12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const Gap(8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
