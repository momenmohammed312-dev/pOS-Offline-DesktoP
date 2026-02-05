import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart';

/// Day Management Screen
/// شاشة إدارة اليومية المركزية
class DayManagementScreen extends ConsumerStatefulWidget {
  final AppDatabase db;

  const DayManagementScreen({super.key, required this.db});

  @override
  ConsumerState<DayManagementScreen> createState() =>
      _DayManagementScreenState();
}

class _DayManagementScreenState extends ConsumerState<DayManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Day> _days = [];
  bool _isLoading = true;
  Day? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDays() async {
    setState(() => _isLoading = true);
    try {
      // Get all days ordered by date descending
      final daysData = await widget.db
          .customSelect('SELECT * FROM days ORDER BY date DESC')
          .get();
      final days = daysData.map((row) {
        final data = row.data;
        return Day(
          id: data['id'] as int,
          date: DateTime.parse(data['date'] as String),
          isOpen: data['is_open'] as int == 1,
          openingBalance: data['opening_balance'] as double,
          closingBalance: data['closing_balance'] as double?,
          notes: data['notes'] as String?,
          createdAt: DateTime.parse(data['created_at'] as String),
          closedAt: data['closed_at'] != null
              ? DateTime.parse(data['closed_at'] as String)
              : null,
        );
      }).toList();

      setState(() {
        _days = days;
        _isLoading = false;
        if (_days.isNotEmpty) {
          _selectedDay = _days.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل الأيام: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة اليومية'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'قائمة الأيام'),
            Tab(icon: Icon(Icons.analytics), text: 'تفاصيل اليوم'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDays,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDaysList(), _buildDayDetails()],
      ),
    );
  }

  Widget _buildDaysList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_days.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد أيام مسجلة', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final isOpen = day.isOpen;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOpen ? Colors.green : Colors.grey,
              child: Icon(
                isOpen ? Icons.play_arrow : Icons.check,
                color: Colors.white,
              ),
            ),
            title: Text(
              'يوم ${DateFormat('yyyy-MM-dd').format(day.date)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرصيد الافتتاحي: ${day.openingBalance.toStringAsFixed(2)} ج.م',
                ),
                if (day.closedAt != null)
                  Text(
                    'الرصيد الختامي: ${day.closingBalance?.toStringAsFixed(2) ?? '0.00'} ج.م',
                  ),
                Text(
                  isOpen ? 'مفتوح' : 'مغلق',
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                setState(() {
                  _selectedDay = day;
                  _tabController.animateTo(1);
                });
              },
              tooltip: 'عرض التفاصيل',
            ),
            onTap: () {
              setState(() {
                _selectedDay = day;
                _tabController.animateTo(1);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDayDetails() {
    if (_selectedDay == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('اختر يوماً من القائمة لعرض التفاصيل'),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _getDayStatistics(_selectedDay!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل يوم ${DateFormat('yyyy-MM-dd').format(_selectedDay!.date)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              _selectedDay!.isOpen ? 'مفتوح' : 'مغلق',
                            ),
                            backgroundColor: _selectedDay!.isOpen
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الرصيد الافتتاحي: ${_selectedDay!.openingBalance.toStringAsFixed(2)} ج.م',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'المبيعات',
                      '${stats['totalSales']?.toStringAsFixed(2) ?? '0.00'} ج.م',
                      '${stats['invoicesCount'] ?? 0} فاتورة',
                      Icons.shopping_cart,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'المشتريات',
                      '${stats['totalPurchases']?.toStringAsFixed(2) ?? '0.00'} ج.م',
                      '${stats['purchasesCount'] ?? 0} فاتورة',
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'المصروفات',
                      '${stats['totalExpenses']?.toStringAsFixed(2) ?? '0.00'} ج.م',
                      '${stats['expensesCount'] ?? 0} عملية',
                      Icons.money_off,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'صافي الربح',
                      '${stats['netProfit']?.toStringAsFixed(2) ?? '0.00'} ج.م',
                      'المبيعات - المصروفات',
                      Icons.trending_up,
                      (stats['netProfit'] ?? 0) >= 0
                          ? Colors.purple
                          : Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons
              if (_selectedDay!.isOpen)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'إجراءات اليوم المفتوح',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _closeDay,
                          icon: const Icon(Icons.lock),
                          label: const Text('إغلاق اليوم'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getDayStatistics(Day day) async {
    try {
      final endDate = day.closedAt ?? DateTime.now();

      // Get all transactions for the day using custom queries
      final invoicesData = await widget.db
          .customSelect(
            'SELECT * FROM invoices WHERE date >= ? AND date <= ?',
            variables: [
              drift.Variable.withDateTime(day.date),
              drift.Variable.withDateTime(endDate),
            ],
          )
          .get();

      final purchasesData = await widget.db
          .customSelect(
            'SELECT * FROM enhanced_purchases WHERE created_at >= ? AND created_at <= ?',
            variables: [
              drift.Variable.withDateTime(day.date),
              drift.Variable.withDateTime(endDate),
            ],
          )
          .get();

      final expensesData = await widget.db
          .customSelect(
            'SELECT * FROM expenses WHERE created_at >= ? AND created_at <= ?',
            variables: [
              drift.Variable.withDateTime(day.date),
              drift.Variable.withDateTime(endDate),
            ],
          )
          .get();

      // Calculate totals
      double totalSales = invoicesData.fold(
        0.0,
        (sum, inv) => sum + (inv.data['total_amount'] as double? ?? 0.0),
      );
      double totalPurchases = purchasesData.fold(
        0.0,
        (sum, pur) => sum + (pur.data['total_amount'] as double? ?? 0.0),
      );
      double totalExpenses = expensesData.fold(
        0.0,
        (sum, exp) => sum + (exp.data['amount'] as double? ?? 0.0),
      );

      return {
        'totalSales': totalSales,
        'totalPurchases': totalPurchases,
        'totalExpenses': totalExpenses,
        'netProfit': totalSales - totalPurchases - totalExpenses,
        'invoicesCount': invoicesData.length,
        'purchasesCount': purchasesData.length,
        'expensesCount': expensesData.length,
      };
    } catch (e) {
      return {};
    }
  }

  Future<void> _closeDay() async {
    try {
      // Calculate closing balance (simplified version)
      final stats = await _getDayStatistics(_selectedDay!);
      final closingBalance =
          _selectedDay!.openingBalance +
          (stats['totalSales'] ?? 0.0) -
          (stats['totalExpenses'] ?? 0.0);

      await widget.db.customUpdate(
        'UPDATE days SET is_open = ?, closed_at = ?, closing_balance = ? WHERE id = ?',
        variables: [
          drift.Variable.withBool(false),
          drift.Variable.withDateTime(DateTime.now()),
          drift.Variable.withReal(closingBalance),
          drift.Variable.withInt(_selectedDay!.id),
        ],
      );

      await _loadDays();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إغلاق اليوم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إغلاق اليوم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Extension to create Day from data
extension DayExtension on Day {
  static Day fromJson(Map<String, dynamic> data) {
    return Day(
      id: data['id'] as int,
      date: DateTime.parse(data['date'] as String),
      isOpen: data['is_open'] as int == 1,
      openingBalance: data['opening_balance'] as double,
      closingBalance: data['closing_balance'] as double?,
      notes: data['notes'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      closedAt: data['closed_at'] != null
          ? DateTime.parse(data['closed_at'] as String)
          : null,
    );
  }
}
