import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/enhanced_purchase_dao.dart';
import '../../../core/provider/app_database_provider.dart';

class PurchaseReportsScreen extends ConsumerStatefulWidget {
  const PurchaseReportsScreen({super.key});

  @override
  ConsumerState<PurchaseReportsScreen> createState() =>
      _PurchaseReportsScreenState();
}

class _PurchaseReportsScreenState extends ConsumerState<PurchaseReportsScreen> {
  late final AppDatabase _database;
  late final EnhancedPurchaseDao _purchaseDao;
  DateTimeRange? _selectedDateRange;
  List<EnhancedPurchase> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = ref.read(appDatabaseProvider);
    _purchaseDao = EnhancedPurchaseDao(_database);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final purchases = await _purchaseDao.getAllPurchases();

      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<EnhancedPurchase> get _filteredPurchases {
    if (_selectedDateRange == null) return _purchases;

    return _purchases.where((purchase) {
      return purchase.purchaseDate.isAfter(
            _selectedDateRange!.start.subtract(Duration(days: 1)),
          ) &&
          purchase.purchaseDate.isBefore(
            _selectedDateRange!.end.add(Duration(days: 1)),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('تقارير المشتريات'),
        backgroundColor: Color(0xFF2D2D3D),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'اختر نطاق التاريخ',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _printReport,
            tooltip: 'طباعة التقرير',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Selector
                  _buildDateRangeSelector(),
                  SizedBox(height: 20),

                  // Summary Cards
                  _buildSummaryCards(),
                  SizedBox(height: 20),

                  // Simple Chart
                  _buildSimpleChart(),
                  SizedBox(height: 20),

                  // Supplier Analysis
                  _buildSupplierAnalysis(),
                  SizedBox(height: 20),

                  // Detailed Table
                  _buildDetailedTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: Colors.purple),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedDateRange != null
                  ? '${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}'
                  : 'كل الوقت',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: _selectDateRange,
            child: Text('تغيير', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final filteredPurchases = _filteredPurchases;
    final totalPurchases = filteredPurchases.fold(
      0.0,
      (sum, p) => sum + p.totalAmount,
    );
    final creditPurchases = filteredPurchases
        .where((p) => p.isCreditPurchase)
        .fold(0.0, (sum, p) => sum + p.totalAmount);
    final cashPurchases = filteredPurchases
        .where((p) => !p.isCreditPurchase)
        .fold(0.0, (sum, p) => sum + p.totalAmount);
    final totalSuppliers = filteredPurchases
        .map((p) => p.supplierId)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'إجمالي المشتريات',
            '${totalPurchases.toStringAsFixed(2)} ج.م',
            Icons.shopping_cart,
            Colors.purple,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'مشتريات آجلة',
            '${creditPurchases.toStringAsFixed(2)} ج.م',
            Icons.credit_card,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'مشتريات نقدية',
            '${cashPurchases.toStringAsFixed(2)} ج.م',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'عدد الموردين',
            totalSuppliers.toString(),
            Icons.business,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    final filteredPurchases = _filteredPurchases;

    // Group purchases by month
    final Map<String, double> monthlyData = {};
    for (final purchase in filteredPurchases) {
      final monthKey = DateFormat('MMM yyyy').format(purchase.purchaseDate);
      monthlyData[monthKey] =
          (monthlyData[monthKey] ?? 0) + purchase.totalAmount;
    }

    final chartData = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (chartData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF3D3D4D)),
        ),
        child: Center(
          child: Text(
            'لا توجد بيانات لعرضها',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxValue = chartData.fold(
      0.0,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المشتريات الشهرية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: chartData.map((entry) {
                final height = maxValue > 0
                    ? (entry.value / maxValue * 150).toDouble()
                    : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      entry.value.toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierAnalysis() {
    final filteredPurchases = _filteredPurchases;

    // Calculate supplier totals
    final Map<int, double> supplierTotals = {};
    final Map<int, String> supplierNames = {};

    for (final purchase in filteredPurchases) {
      supplierTotals[purchase.supplierId] =
          (supplierTotals[purchase.supplierId] ?? 0) + purchase.totalAmount;
      supplierNames[purchase.supplierId] = purchase.supplierName;
    }

    final sortedSuppliers = supplierTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أعلى الموردين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(sortedSuppliers.take(5).length, (index) {
            final supplierEntry = sortedSuppliers[index];
            final supplierName =
                supplierNames[supplierEntry.key] ?? 'غير معروف';
            final amount = supplierEntry.value;

            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      supplierName,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    '${amount.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedTable() {
    final filteredPurchases = _filteredPurchases;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل المشتريات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'رقم الفاتورة',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'المورد',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'التاريخ',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الإجمالي',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'النوع',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الحالة',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              rows: filteredPurchases.map((purchase) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        purchase.purchaseNumber,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataCell(
                      Text(
                        purchase.supplierName,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataCell(
                      Text(
                        DateFormat('yyyy-MM-dd').format(purchase.purchaseDate),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${purchase.totalAmount.toStringAsFixed(2)} ج.م',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: purchase.isCreditPurchase
                              ? Colors.orange.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          purchase.isCreditPurchase ? 'آجل' : 'نقدي',
                          style: TextStyle(
                            color: purchase.isCreditPurchase
                                ? Colors.orange
                                : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: purchase.remainingAmount > 0
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          purchase.remainingAmount > 0 ? 'متبقي' : 'مدفوع',
                          style: TextStyle(
                            color: purchase.remainingAmount > 0
                                ? Colors.red
                                : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.purple,
              surface: Color(0xFF2D2D3D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم طباعة تقرير المشتريات'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
