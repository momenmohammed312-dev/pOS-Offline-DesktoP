import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';

class ModernSalesDashboard extends ConsumerWidget {
  const ModernSalesDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context),
              const Gap(20),

              // Quick Stats Cards
              _buildQuickStats(context, db),
              const Gap(20),

              // Sales Chart Section
              _buildSalesChart(context, db),
              const Gap(20),

              // Recent Sales Table
              _buildRecentSalesTable(context, db),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSaleDialog(context, db),
        backgroundColor: Colors.blue.shade700,
        tooltip: 'إضافة بيع جديد',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التحكم',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const Gap(8),
                Text(
                  'نظام نقطة البيع',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Gap(16),
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 30,
            child: Icon(Icons.dashboard, color: Colors.white),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الإجماليات اليوم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppDatabase db) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'المبيعات اليوم',
            Icons.trending_up,
            Colors.green,
            () async => await _getTodaySales(db),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            context,
            'الإجمالي الشهري',
            Icons.attach_money,
            Colors.blue,
            () async => await _getMonthSales(db),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            context,
            'عدد الفواتير',
            Icons.receipt_long,
            Colors.orange,
            () => _getTodayInvoicesCount(db).then((count) => count.toDouble()),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildStatCard(
            context,
            'العملاء النشطين',
            Icons.people,
            Colors.purple,
            () =>
                _getActiveCustomersCount(db).then((count) => count.toDouble()),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Future<double> Function() getValue,
  ) {
    return FutureBuilder<double>(
      future: getValue(),
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 32),
                    const Gap(12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesChart(BuildContext context, AppDatabase db) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تحليل المبيعات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const Gap(12),
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('مخطأ في تحميل البيانات')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesTable(BuildContext context, AppDatabase db) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبيعات الأخيرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAllSalesDialog(context, db),
                  icon: const Icon(Icons.list),
                  label: Text('عرض الكل'),
                ),
              ],
            ),
            const Gap(12),
            SizedBox(
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('لا توجد بيانات')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSaleDialog(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة بيع جديد'),
        content: const Text('وظيفة إضافة المبيعات قيد التطوير'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showAllSalesDialog(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جميع المبيعات'),
        content: const Text('وظيفة عرض جميع المبيعات قيد التطوير'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<double> _getTodaySales(AppDatabase db) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todaySales = await db.invoiceDao.getInvoicesByDateRange(
        startOfDay,
        endOfDay,
      );
      double total = 0.0;
      for (final invoice in todaySales) {
        total += invoice.totalAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getMonthSales(AppDatabase db) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final monthSales = await db.invoiceDao.getInvoicesByDateRange(
        monthStart,
        monthEnd,
      );
      double total = 0.0;
      for (final invoice in monthSales) {
        total += invoice.totalAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> _getTodayInvoicesCount(AppDatabase db) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayInvoices = await db.invoiceDao.getInvoicesByDateRange(
        startOfDay,
        endOfDay,
      );
      return todayInvoices.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getActiveCustomersCount(AppDatabase db) async {
    try {
      final allCustomers = await db.customerDao.getAllCustomers();
      return allCustomers.length;
    } catch (e) {
      return 0;
    }
  }
}
