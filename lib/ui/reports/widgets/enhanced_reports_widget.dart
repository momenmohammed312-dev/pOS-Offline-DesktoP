import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/export_service.dart';
import 'package:pos_offline_desktop/core/services/sales_report_service.dart';
import 'package:pos_offline_desktop/core/services/supplier_expense_service.dart';
import 'package:pos_offline_desktop/l10n/l10n.dart';
import 'package:pos_offline_desktop/ui/reports/widgets/customer_report_tab.dart';

class EnhancedReportsWidget extends StatefulWidget {
  final AppDatabase db;

  const EnhancedReportsWidget({super.key, required this.db});

  @override
  State<EnhancedReportsWidget> createState() => _EnhancedReportsWidgetState();
}

class _EnhancedReportsWidgetState extends State<EnhancedReportsWidget> {
  late SalesReportService _salesReportService;
  late SupplierExpenseService _supplierExpenseService;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCustomerId;
  String? _selectedSupplierId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _salesReportService = SalesReportService(
      db: widget.db,
      exportService: ExportService(),
    );
    _supplierExpenseService = SupplierExpenseService(
      db: widget.db,
      exportService: ExportService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.advanced_reports,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(20),

              // Date Range Filter
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.date_filter,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text(context.l10n.from_date),
                              subtitle: Text(
                                _startDate != null
                                    ? DateFormat(
                                        'yyyy/MM/dd',
                                      ).format(_startDate!)
                                    : context.l10n.select_start_date,
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _selectStartDate,
                            ),
                          ),
                          const Gap(16),
                          Expanded(
                            child: ListTile(
                              title: Text(context.l10n.to_date),
                              subtitle: Text(
                                _endDate != null
                                    ? DateFormat('yyyy/MM/dd').format(_endDate!)
                                    : context.l10n.select_end_date,
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _selectEndDate,
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _clearDateFilter,
                            icon: const Icon(Icons.clear),
                            label: Text(context.l10n.clear_filter),
                          ),
                          const Gap(8),
                          ElevatedButton.icon(
                            onPressed: _applyDateFilter,
                            icon: const Icon(Icons.filter_list),
                            label: Text(context.l10n.apply_filter),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(20),

              // Report Cards
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ReportCard(
                    title: context.l10n.detailed_sales_report,
                    icon: Icons.trending_up,
                    color: Colors.green,
                    onTap: () => _showDetailedSalesReport(context),
                  ),
                  _ReportCard(
                    title: context.l10n.supplier_expense_report,
                    icon: Icons.trending_down,
                    color: Colors.red,
                    onTap: () => _showSupplierExpenseReport(context),
                  ),
                  _ReportCard(
                    title: context.l10n.comprehensive_report,
                    icon: Icons.analytics,
                    color: Colors.blue,
                    onTap: () => _showComprehensiveReport(context),
                  ),
                  _ReportCard(
                    title: context.l10n.customer_report,
                    icon: Icons.people,
                    color: Colors.purple,
                    onTap: () => _showCustomerReport(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.grey, // Header background and selected date
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Calendar background
              onSurface: Colors.black, // Calendar text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Button text color
              ),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.grey, // Header background and selected date
              onPrimary: Colors.white, // Header text color
              surface: Colors.white, // Calendar background
              onSurface: Colors.black, // Calendar text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Button text color
              ),
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _applyDateFilter() {
    setState(() {
      // Trigger rebuild with applied filter
    });
  }

  Future<void> _showDetailedSalesReport(BuildContext context) async {
    final scaffoldContext = context;
    setState(() {
      _isLoading = true;
    });

    try {
      final reportData = await _salesReportService.generateSalesReport(
        startDate: _startDate,
        endDate: _endDate,
        customerId: _selectedCustomerId,
      );

      if (!mounted || !scaffoldContext.mounted) return;

      showDialog(
        context: scaffoldContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            '${context.l10n.detailed_sales_report}${_getDateRangeText()}',
          ),
          content: SizedBox(
            width: 800,
            height: 600,
            child: Column(
              children: [
                // Summary Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        title: context.l10n.total_sales,
                        value: _formatCurrency(reportData.totalSales),
                        color: Colors.green,
                      ),
                      _SummaryItem(
                        title: context.l10n.total_paid,
                        value: _formatCurrency(reportData.totalPaid),
                        color: Colors.blue,
                      ),
                      _SummaryItem(
                        title: context.l10n.outstanding,
                        value: _formatCurrency(reportData.totalOutstanding),
                        color: Colors.orange,
                      ),
                      _SummaryItem(
                        title: context.l10n.invoice_count,
                        value: reportData.totalInvoices.toString(),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                // Customer Breakdown
                Expanded(
                  child: reportData.customerBreakdown.isEmpty
                      ? Center(child: Text(context.l10n.no_data))
                      : ListView.builder(
                          itemCount: reportData.customerBreakdown.length,
                          itemBuilder: (context, index) {
                            final customer =
                                reportData.customerBreakdown[index];
                            final balance =
                                reportData.customerBalances[customer
                                    .customerId] ??
                                0.0;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ExpansionTile(
                                title: Text(customer.customerName),
                                subtitle: Text(
                                  '${context.l10n.invoice_count}: ${customer.invoiceCount}',
                                ),
                                trailing: Text(
                                  _formatCurrency(customer.totalSales),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              context.l10n.total_sales_colon,
                                            ),
                                            Text(
                                              _formatCurrency(
                                                customer.totalSales,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(context.l10n.paid_colon),
                                            Text(
                                              _formatCurrency(
                                                customer.totalPaid,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(context.l10n.outstanding_debt),
                                            Text(
                                              _formatCurrency(
                                                customer.totalOutstanding,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              context
                                                  .l10n
                                                  .current_balance_colon,
                                            ),
                                            Text(_formatCurrency(balance)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _salesReportService.exportSalesReportToPDF(reportData);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.pdf_exported_successfully),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(context.l10n.export_pdf),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _salesReportService.exportSalesReportToExcel(reportData);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.excel_exported_successfully),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.table_chart),
              label: Text(context.l10n.export_excel),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSupplierExpenseReport(BuildContext context) async {
    final scaffoldContext = context;
    setState(() {
      _isLoading = true;
    });

    try {
      final reportData = await _supplierExpenseService
          .generateSupplierExpenseReport(
            startDate: _startDate,
            endDate: _endDate,
            supplierId: _selectedSupplierId,
          );

      if (!mounted || !scaffoldContext.mounted) return;

      showDialog(
        context: scaffoldContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            '${context.l10n.supplier_expense_report}${_getDateRangeText()}',
          ),
          content: SizedBox(
            width: 800,
            height: 600,
            child: Column(
              children: [
                // Summary Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(
                        title: context.l10n.total_expenses,
                        value: _formatCurrency(reportData.totalExpenses),
                        color: Colors.red,
                      ),
                      _SummaryItem(
                        title: context.l10n.expenses_count,
                        value: reportData.totalExpensesCount.toString(),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                // Supplier Breakdown
                Expanded(
                  child: reportData.supplierBreakdown.isEmpty
                      ? Center(child: Text(context.l10n.no_data))
                      : ListView.builder(
                          itemCount: reportData.supplierBreakdown.length,
                          itemBuilder: (context, index) {
                            final supplier =
                                reportData.supplierBreakdown[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(supplier.supplierName),
                                subtitle: Text(
                                  '${context.l10n.expenses_count}: ${supplier.expenseCount}',
                                ),
                                trailing: Text(
                                  _formatCurrency(supplier.totalExpenses),
                                ),
                                onTap: () {
                                  // Show supplier details
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _supplierExpenseService.exportSupplierExpenseReportToPDF(
                  reportData,
                );
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.pdf_exported_successfully),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(context.l10n.export_pdf),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _supplierExpenseService
                    .exportSupplierExpenseReportToExcel(reportData);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.excel_exported_successfully),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.table_chart),
              label: Text(context.l10n.export_excel),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showComprehensiveReport(BuildContext context) async {
    final scaffoldContext = context;
    setState(() {
      _isLoading = true;
    });

    try {
      final reportData = await _supplierExpenseService
          .generateComprehensiveReport(
            startDate: _startDate,
            endDate: _endDate,
          );

      if (!mounted || !scaffoldContext.mounted) return;

      showDialog(
        context: scaffoldContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            '${context.l10n.comprehensive_report}${_getDateRangeText()}',
          ),
          content: SizedBox(
            width: 600,
            height: 500,
            child: Column(
              children: [
                // Executive Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _SummaryItem(
                        title: context.l10n.total_sales,
                        value: _formatCurrency(
                          reportData.salesReport.totalSales,
                        ),
                        color: Colors.green,
                      ),
                      const Gap(8),
                      _SummaryItem(
                        title: context.l10n.total_expenses,
                        value: _formatCurrency(
                          reportData.expenseReport.totalExpenses,
                        ),
                        color: Colors.red,
                      ),
                      const Gap(8),
                      _SummaryItem(
                        title: context.l10n.net_profit,
                        value: _formatCurrency(reportData.netProfit),
                        color: reportData.netProfit >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                      const Gap(8),
                      _SummaryItem(
                        title: context.l10n.accounts_receivable,
                        value: _formatCurrency(
                          reportData.totalOutstandingReceivables,
                        ),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _supplierExpenseService.exportComprehensiveReportToPDF(
                  reportData,
                );
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(context.l10n.comprehensive_report)),
                  );
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(context.l10n.export_pdf),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCustomerReport(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.customer_report),
        content: SizedBox(
          width: 800,
          height: 600,
          child: CustomerReportTab(db: widget.db),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) return '';
    if (_startDate != null && _endDate != null) {
      return ' (${DateFormat('yyyy/MM/dd').format(_startDate!)} - ${DateFormat('yyyy/MM/dd').format(_endDate!)})';
    }
    if (_startDate != null) {
      return ' ${context.l10n.from_date} ${DateFormat('yyyy/MM/dd').format(_startDate!)}';
    }
    return ' ${context.l10n.to_date} ${DateFormat('yyyy/MM/dd').format(_endDate!)}';
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: Localizations.localeOf(context).languageCode == 'ar'
          ? 'ar_EG'
          : 'en_EG',
      symbol: context.l10n.currency_symbol,
      decimalDigits: 2,
    ).format(amount);
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const Gap(12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const Gap(4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
