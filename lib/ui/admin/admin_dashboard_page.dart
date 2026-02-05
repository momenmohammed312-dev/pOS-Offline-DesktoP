import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/provider/app_database_provider.dart';
import 'package:pos_offline_desktop/services/license_manager.dart';
import 'package:pos_offline_desktop/services/session_service.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AdminDashboardPageContent();
  }
}

class _AdminDashboardPageContent extends ConsumerStatefulWidget {
  const _AdminDashboardPageContent();

  @override
  ConsumerState<_AdminDashboardPageContent> createState() =>
      _AdminDashboardPageContentState();
}

class _AdminDashboardPageContentState
    extends ConsumerState<_AdminDashboardPageContent> {
  late Future<Map<String, dynamic>> _dashboardData;
  late Future<List<Map<String, dynamic>>> _activeSessions;
  late Future<List<Map<String, dynamic>>> _recentActivity;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _dashboardData = _getDashboardData();
      _activeSessions = SessionService.getActiveSessions();
      _recentActivity = _getRecentActivity();
    });
  }

  Future<Map<String, dynamic>> _getDashboardData() async {
    try {
      final licenseManager = LicenseManager();
      final license = await licenseManager.getCurrentLicense();
      final db = ref.read(appDatabaseProvider);

      // Get business statistics
      final totalCustomers = await db.customerDao.getTotalCustomerCount();
      final totalProducts = await db.productDao.filterProducts().then(
        (products) => products.length,
      );
      final totalSuppliers = await db.supplierDao.getAllSuppliers().then(
        (suppliers) => suppliers.length,
      );
      final totalInvoices = await db.invoiceDao
          .getInvoicesByDateRange(DateTime(2020), DateTime.now())
          .then((invoices) => invoices.length);

      // Get financial data
      final today = DateTime.now();
      final todayInvoices = await db.invoiceDao.getInvoicesByDate(today);
      final todaySales = todayInvoices.fold<double>(
        0,
        (sum, invoice) => sum + invoice.totalAmount,
      );

      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 0);
      final monthInvoices = await db.invoiceDao.getInvoicesByDateRange(
        monthStart,
        monthEnd,
      );
      final monthSales = monthInvoices.fold<double>(
        0,
        (sum, invoice) => sum + invoice.totalAmount,
      );

      final yearStart = DateTime(today.year, 1, 1);
      final yearEnd = DateTime(today.year + 1, 0, 0);
      final yearInvoices = await db.invoiceDao.getInvoicesByDateRange(
        yearStart,
        yearEnd,
      );
      final yearSales = yearInvoices.fold<double>(
        0,
        (sum, invoice) => sum + invoice.totalAmount,
      );

      // Get system statistics
      final activeSessions = await SessionService.getActiveSessionCount();
      final backupStats = {'totalBackups': 0, 'lastBackup': 'Never'};

      return {
        'license': license,
        'business': {
          'totalCustomers': totalCustomers,
          'totalProducts': totalProducts,
          'totalSuppliers': totalSuppliers,
          'totalInvoices': totalInvoices,
        },
        'financial': {
          'todaySales': todaySales,
          'monthSales': monthSales,
          'yearSales': yearSales,
        },
        'system': {
          'activeSessions': activeSessions,
          'backupStats': backupStats,
        },
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final recentLogs = await db.auditDao.getAuditLogs(limit: 20);

      return recentLogs
          .map(
            (log) => {
              'id': log.id,
              'action': log.action,
              'tableName': log.tableNameField,
              'details': log.details,
              'timestamp': log.timestamp,
              'userId': log.userId,
            },
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLicenseStatus(),
              const SizedBox(height: 16),
              _buildBusinessOverview(),
              const SizedBox(height: 16),
              _buildFinancialOverview(),
              const SizedBox(height: 16),
              _buildSystemStatus(),
              const SizedBox(height: 16),
              _buildActiveSessions(),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorCard('خطأ في تحميل بيانات الترخيص');
            }

            final data = snapshot.data!;
            final license = data['license'];

            if (license == null) {
              return _buildErrorCard('لا يوجد ترخيص نشط');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Colors.green[700],
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'حالة الترخيص',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getLicenseStatusColor(license),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getLicenseStatusText(license),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLicenseDetails(license),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLicenseDetails(dynamic license) {
    return Column(
      children: [
        _buildDetailRow('نوع الترخيص', license.licenseType.name),
        _buildDetailRow('المدة', '${license.durationInDays} يوم'),
        _buildDetailRow('المستخدمون المسموح بهم', '${license.maxUsers}'),
        _buildDetailRow(
          'تاريخ البدء',
          license.startDate.toString().split(' ')[0],
        ),
        _buildDetailRow(
          'تاريخ الانتهاء',
          license.endDate.toString().split(' ')[0],
        ),
        _buildDetailRow('Device ID', license.deviceFingerprint),
      ],
    );
  }

  Widget _buildBusinessOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  'نظرة عامة على الأعمال',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardData,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['business'] != null) {
                  final business = snapshot.data!['business'];
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard(
                        'العملاء',
                        '${business['totalCustomers']}',
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'المنتجات',
                        '${business['totalProducts']}',
                        Icons.inventory,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'الموردون',
                        '${business['totalSuppliers']}',
                        Icons.local_shipping,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'الفواتير',
                        '${business['totalInvoices']}',
                        Icons.receipt,
                        Colors.purple,
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  'نظرة عامة مالية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardData,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['financial'] != null) {
                  final financial = snapshot.data!['financial'];
                  return Column(
                    children: [
                      _buildFinancialRow(
                        'مبيعات اليوم',
                        financial['todaySales'],
                      ),
                      _buildFinancialRow(
                        'مبيعات الشهر',
                        financial['monthSales'],
                      ),
                      _buildFinancialRow(
                        'مبيعات السنة',
                        financial['yearSales'],
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_system_daydream,
                  color: Colors.purple[700],
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'حالة النظام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _dashboardData,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['system'] != null) {
                  final system = snapshot.data!['system'];
                  return Column(
                    children: [
                      _buildDetailRow(
                        'الجلسات النشطة',
                        '${system['activeSessions']}',
                      ),
                      _buildDetailRow(
                        'عدد النسخ الاحتياطية',
                        '${system['backupStats']['total_backups']}',
                      ),
                      _buildDetailRow(
                        'حجم النسخ الاحتياطية',
                        '${system['backupStats']['total_size_mb']} MB',
                      ),
                      _buildDetailRow('آخر تحديث', '${system['lastUpdated']}'),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt, color: Colors.orange[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  'الجلسات النشطة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _forceLogoutInactiveUsers(),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('تسجيل الخروج للغير نشطين'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _activeSessions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد جلسات نشطة'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final session = snapshot.data![index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(session['username'] ?? 'Unknown'),
                      subtitle: Text(
                        'آخر نشاط: ${session['last_activity']}\n'
                        'الجهاز: ${session['device_info']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: () =>
                            _forceLogoutSession(session['session_id']),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.red[700], size: 28),
                const SizedBox(width: 8),
                Text(
                  'النشاط الأخير',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _recentActivity,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا يوجد نشاط حديث'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final activity = snapshot.data![index];
                    return ListTile(
                      leading: Icon(_getActivityIcon(activity['action'])),
                      title: Text(activity['action']),
                      subtitle: Text(
                        '${activity['tableName']}\n'
                        '${activity['timestamp']}',
                      ),
                      trailing: Text(
                        'User ${activity['userId'] ?? '?'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${amount.toStringAsFixed(2)} ج.م',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Color _getLicenseStatusColor(dynamic license) {
    if (license.isExpired) return Colors.red;
    if (license.daysUntilExpiry < 7) return Colors.orange;
    return Colors.green;
  }

  String _getLicenseStatusText(dynamic license) {
    if (license.isExpired) return 'منتهي';
    if (license.daysUntilExpiry < 7) return 'سينتهي قريباً';
    return 'نشط';
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.info;
    }
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات المدير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('إنشاء نسخة احتياطية'),
              onTap: () {
                Navigator.pop(context);
                _createBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('استعادة نسخة احتياطية'),
              onTap: () {
                Navigator.pop(context);
                _restoreBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('إعدادات الأمان'),
              onTap: () {
                Navigator.pop(context);
                _showSecuritySettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('إدارة المستخدمين'),
              onTap: () {
                Navigator.pop(context);
                _manageUsers();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _createBackup() {
    // Implement backup creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إنشاء نسخة احتياطية...')),
    );
  }

  void _restoreBackup() {
    // Implement backup restoration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري استعادة النسخة الاحتياطية...')),
    );
  }

  void _showSecuritySettings() {
    // Implement security settings
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('إعدادات الأمان قيد التطوير')));
  }

  void _manageUsers() {
    // Implement user management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('إدارة المستخدمين قيد التطوير')),
    );
  }

  void _forceLogoutInactiveUsers() async {
    await SessionService.forceLogoutInactiveUsers();
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل خروج المستخدمين غير النشطين')),
      );
    }
  }

  void _forceLogoutSession(String sessionId) async {
    await SessionService.destroySession(sessionId);
    _refreshData();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تسجيل خروج الجلسة')));
    }
  }
}
