import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';
import 'package:pos_offline_desktop/ui/invoice/widgets/enhanced_new_invoice_page.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/customer_dashboard.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك في نظام نقاط البيع',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Developed by MO2 - v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Customer Dashboard Section
            CustomerDashboard(
              db: db,
              onCustomerSelected: (customer) {
                // Navigate to customer details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم اختيار العميل: ${customer.name}'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              onRefresh: () {
                // Refresh dashboard data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث البيانات'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            const Gap(24),

            // Suppliers Dashboard Section
            Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ملخص الموردين',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Refresh suppliers data
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تحديث بيانات الموردين'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'تحديث بيانات الموردين',
                        ),
                      ],
                    ),
                    const Gap(16),
                    StreamBuilder<int>(
                      stream: db.supplierDao.watchSuppliersCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'إجمالي الموردين',
                                count.toString(),
                                Icons.local_shipping,
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Gap(24),

            // Quick Actions Section
            Text(
              'الإجراءات السريعة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'فاتورة جديدة',
                    'إنشاء فاتورة مبيعات جديدة',
                    Icons.add_shopping_cart,
                    Colors.green,
                    () => _createNewInvoice(),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildQuickActionCard(
                    'الفواتير والمدفوعات',
                    'عرض وإدارة الفواتير',
                    Icons.receipt_long,
                    Colors.blue,
                    () => Navigator.of(context).pushNamed('/invoice'),
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'إضافة منتج',
                    'إضافة منتج جديد للمخزون',
                    Icons.inventory,
                    Colors.indigo,
                    () => _navigateToAddProduct(),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildQuickActionCard(
                    'إضافة عميل',
                    'إضافة عميل جديد',
                    Icons.person_add,
                    Colors.teal,
                    () => _navigateToAddCustomer(),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Day Management Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.red.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 32),
                      const Gap(12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة اليوم',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'فتح أو غلق اليوم المالي',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openDay(),
                          icon: const Icon(
                            Icons.lock_open,
                            color: Colors.white,
                          ),
                          label: const Text('فتح اليوم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _closeDay(),
                          icon: const Icon(Icons.lock, color: Colors.white),
                          label: const Text('غلق اليوم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Gap(16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewInvoice() async {
    final db = ref.read(appDatabaseProvider);
    final isOpen = await db.dayDao.isDayOpen();
    if (!isOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برجاء فتح اليوم أولاً'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Navigate to enhanced new invoice page
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EnhancedNewInvoicePage(db: db)),
      );
    }
  }

  void _navigateToAddProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('يمكن الوصول لإضافة المنتجات من القائمة الجانبية'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToAddCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('يمكن الوصول لإضافة العملاء من القائمة الجانبية'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _openDay() async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.dayDao.openDay(openingBalance: 0.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح اليوم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح اليوم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeDay() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final today = await db.dayDao.getTodayDay();
      if (today == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يوجد يوم مفتوح'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await db.dayDao.closeDay(dayId: today['id'] as int, closingBalance: 0.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم غلق اليوم بنجاح'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في غلق اليوم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
}
