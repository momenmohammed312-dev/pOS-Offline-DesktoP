import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../services/analytics_service.dart';

class ProfitReportScreen extends StatefulWidget {
  final AppDatabase database;

  const ProfitReportScreen({super.key, required this.database});

  @override
  State<ProfitReportScreen> createState() => _ProfitReportScreenState();
}

class _ProfitReportScreenState extends State<ProfitReportScreen> {
  Map<String, dynamic> _profitData = {};
  bool _isLoading = true;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadProfitData();
  }

  Future<void> _loadProfitData() async {
    setState(() => _isLoading = true);

    try {
      final analyticsService = AnalyticsService(widget.database);
      final data = await analyticsService.getFinancialAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      setState(() {
        _profitData = {
          'totalRevenue': data.revenue,
          'totalInvoices': 0, // Not available in FinancialAnalytics
          'averageInvoiceValue': data.revenue > 0
              ? data.revenue / 1
              : 0.0, // Simplified
          'totalPaid': data.revenue,
          'outstandingAmount': 0.0, // Not available in FinancialAnalytics
          'paymentCollectionRate': 100.0, // Simplified
          'profit_margin': data.profit > 0
              ? (data.profit / data.revenue) * 100
              : 0.0,
          'period': _selectedPeriod,
          'start_date': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'end_date': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading profit data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الربح'),
        backgroundColor: Colors.blue.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfitData,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'تصدير',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period Selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text(
                          'الفترة:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedPeriod,
                          items: const [
                            DropdownMenuItem(
                              value: 'today',
                              child: Text('اليوم فقط'),
                            ),
                            DropdownMenuItem(
                              value: 'week',
                              child: Text('هذا الأسبوع'),
                            ),
                            DropdownMenuItem(
                              value: 'month',
                              child: Text('هذا الشهر'),
                            ),
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('الكل الوقت'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedPeriod = value!);
                            _loadProfitData();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Profit Summary Cards
                Row(
                  children: [
                    _buildProfitCard(
                      'إجمالي الإيرادات',
                      '${(_profitData['totalRevenue'] ?? 0.0).toStringAsFixed(2)} ج.م',
                      (_profitData['profit_margin'] ?? 0.0) >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 16),
                    _buildProfitCard(
                      'إجمالي المدفوع',
                      '${(_profitData['totalPaid'] ?? 0.0).toStringAsFixed(2)} ج.م',
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildProfitCard(
                      'المبلغ المتبقي',
                      '${(_profitData['outstandingAmount'] ?? 0.0).toStringAsFixed(2)} ج.م',
                      (_profitData['outstandingAmount'] ?? 0.0) <= 0.01
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Profit Margin Card
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: (_profitData['profit_margin'] ?? 0.0) >= 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_profitData['profit_margin'] ?? 0.0) >= 0
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getProfitMarginIcon(),
                              color: _getProfitMarginColor(),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'هامش الربح',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getProfitMarginColor().withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_profitData['profit_margin'] ?? 0.0).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getProfitMarginColor(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getProfitMarginText(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Period Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الفترة: ${_getPeriodText(_selectedPeriod)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'من: ${_formatDate(DateTime.parse(_profitData['start_date'] as String))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'إلى: ${_formatDate(DateTime.parse(_profitData['end_date'] as String))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportReport,
        tooltip: 'تصدير التقرير',
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildProfitCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProfitMarginIcon() {
    final margin = _profitData['profit_margin'] ?? 0.0;
    return margin >= 0 ? Icons.trending_up : Icons.trending_down;
  }

  Color _getProfitMarginColor() {
    final margin = _profitData['profit_margin'] ?? 0.0;
    return margin >= 0 ? Colors.green : Colors.red;
  }

  String _getProfitMarginText() {
    final margin = _profitData['profit_margin'] ?? 0.0;
    return margin >= 0 ? 'ربح جيد' : 'خسارة';
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      case 'all':
        return 'الكل الوقت';
      default:
        return 'غير محدد';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _exportReport() async {
    try {
      final analyticsService = AnalyticsService(widget.database);
      await analyticsService.exportAnalytics(
        _profitData,
        'pdf',
        'profit_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تصدير التقرير بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
