import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import "package:pos_offline_desktop/core/database/app_database.dart";
import 'package:pos_offline_desktop/core/services/unified_print_service.dart'
    as ups;
import 'package:pos_offline_desktop/l10n/app_localizations.dart';
import '../../core/services/export_service.dart';
import 'package:pos_offline_desktop/ui/invoice/invoice_details_page.dart';
import 'widgets/add_invoice_page.dart';

class InvoicePage extends StatefulWidget {
  final AppDatabase db;
  final int? customerId;

  const InvoicePage({super.key, required this.db, this.customerId});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  bool _isDayOpen = true; // Checked via DayDao

  // Stats
  double _totalSales = 0.0;
  double _totalExpenses = 0.0;
  double _totalReceivables = 0.0;
  double _currentBalance = 0.0;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Default to today
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _checkDayStatus();
    _loadData();
  }

  Future<void> _checkDayStatus() async {
    final isOpen = await widget.db.dayDao.isDayOpen();
    if (mounted) {
      setState(() => _isDayOpen = isOpen);
    }
  }

  Future<void> _openNewDay() async {
    // Logic to open day (same as before or simplified)
    // For brevity reusing existing pattern but calling DayDao
    final controller = TextEditingController();
    final openingBalance = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('فتح يوم جديد'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الرصيد الافتتاحي',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                double.tryParse(controller.text) ?? 0.0,
              ),
              child: const Text('فتح'),
            ),
          ],
        );
      },
    );

    if (openingBalance != null && mounted) {
      await widget.db.dayDao.openDay(openingBalance: openingBalance);
      _checkDayStatus();
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Sanitize data to prevent crashes due to nulls in non-nullable columns
      await widget.db.customStatement(
        'UPDATE invoices SET total_amount = 0 WHERE total_amount IS NULL',
      );
      await widget.db.customStatement(
        'UPDATE invoices SET paid_amount = 0 WHERE paid_amount IS NULL',
      );
      await widget.db.customStatement(
        "UPDATE invoices SET status = 'pending' WHERE status IS NULL",
      );

      // Debug: Check date range
      debugPrint('Loading invoices from $_startDate to $_endDate');

      // 1. Invoices (Filtered)
      final invoices = await widget.db.invoiceDao.getInvoicesByDateRange(
        _startDate,
        _endDate,
      );

      // Debug: Log results
      debugPrint('Found ${invoices.length} invoices in date range');

      // 2. Expenses (Filtered)
      final totalExpenses = await widget.db.expenseDao.getTotalExpenses(
        from: _startDate,
        to: _endDate,
      );

      // 4. Current Balance (Global - Cash in hand)
      final currentBalance = await widget.db.ledgerDao.getRunningBalance(
        'Bank',
        'Cash',
      );

      // 5. Calculate Total Sales from filtered invoices
      final totalSales = invoices.fold<double>(
        0.0,
        (sum, inv) => sum + inv.totalAmount,
      );

      // 6. Total Receivables (Global)
      final totalReceivables = await widget.db.invoiceDao.getTotalReceivables();

      if (mounted) {
        setState(() {
          _invoices = invoices;
          _totalSales = totalSales;
          _totalExpenses = totalExpenses;
          _totalReceivables = totalReceivables;
          _currentBalance = currentBalance;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading data: $e');
      debugPrintStack(stackTrace: stack);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    surface: Color(0xFF161B22),
                  )
                : const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
      });
      _loadData();
    }
  }

  Future<void> _showNewInvoiceDialog() async {
    if (!_isDayOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب فتح اليوم أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Use the NEW AddInvoiceDialog we created
    await showDialog(
      context: context,
      builder: (context) => AddInvoiceDialog(db: widget.db),
    );
    _loadData();
  }

  // Helper methods for new invoice list format
  void _viewInvoice(BuildContext context, Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InvoiceDetailsPage(invoice: invoice, db: widget.db),
      ),
    );
  }

  Future<void> _printInvoiceNew(BuildContext context, Invoice invoice) async {
    try {
      // Get invoice items with product details
      final itemsWithProducts = await widget.db.invoiceDao
          .getItemsWithProductsByInvoice(invoice.id);

      // Convert to InvoiceItem models
      final invoiceItems = itemsWithProducts.map((itemWithProduct) {
        final item = itemWithProduct.$1;
        final product = itemWithProduct.$2;
        return ups.InvoiceItem(
          id: item.id,
          invoiceId: item.invoiceId,
          description: product?.name ?? 'Product ${item.productId}',
          unit: 'قطعة',
          quantity: item.quantity,
          unitPrice: item.price,
          totalPrice: item.quantity * item.price,
        );
      }).toList();

      // Create store info
      final storeInfo = ups.StoreInfo(
        storeName: 'المحل التجاري',
        phone: '01234567890',
        zipCode: '12345',
        state: 'القاهرة',
      );

      // Create invoice model
      final invoiceModel = ups.Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber ?? 'INV${invoice.id}',
        customerName: invoice.customerName ?? 'عميل غير محدد',
        customerPhone: 'N/A',
        customerZipCode: '',
        customerState: '',
        invoiceDate: invoice.date,
        subtotal: invoice.totalAmount,
        isCreditAccount: invoice.status != 'paid',
        previousBalance: 0.0,
        totalAmount: invoice.totalAmount,
      );

      // Create InvoiceData
      final invoiceData = ups.InvoiceData(
        invoice: invoiceModel,
        items: invoiceItems,
        storeInfo: storeInfo,
      );

      // Print using new SOP 4.0 format
      await ups.UnifiedPrintService.printToThermalPrinter(
        documentType: ups.DocumentType.salesInvoice,
        data: invoiceData,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الفاتورة للطباعة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
      }
    }
  }

  Future<void> _shareInvoiceNew(BuildContext context, Invoice invoice) async {
    try {
      // Get invoice items with product details
      final itemsWithProducts = await widget.db.invoiceDao
          .getItemsWithProductsByInvoice(invoice.id);

      // Convert to InvoiceItem models
      final invoiceItems = itemsWithProducts.map((itemWithProduct) {
        final item = itemWithProduct.$1;
        final product = itemWithProduct.$2;
        return ups.InvoiceItem(
          id: item.id,
          invoiceId: item.invoiceId,
          description: product?.name ?? 'Product ${item.productId}',
          unit: 'قطعة',
          quantity: item.quantity,
          unitPrice: item.price,
          totalPrice: item.quantity * item.price,
        );
      }).toList();

      // Create store info
      final storeInfo = ups.StoreInfo(
        storeName: 'المحل التجاري',
        phone: '01234567890',
        zipCode: '12345',
        state: 'القاهرة',
      );

      // Create invoice model
      final invoiceModel = ups.Invoice(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber ?? 'INV${invoice.id}',
        customerName: invoice.customerName ?? 'عميل غير محدد',
        customerPhone: 'N/A',
        customerZipCode: '',
        customerState: '',
        invoiceDate: invoice.date,
        subtotal: invoice.totalAmount,
        isCreditAccount: invoice.status != 'paid',
        previousBalance: 0.0,
        totalAmount: invoice.totalAmount,
      );

      // Create InvoiceData
      final invoiceData = ups.InvoiceData(
        invoice: invoiceModel,
        items: invoiceItems,
        storeInfo: storeInfo,
      );

      // Share using new SOP 4.0 format
      await ups.UnifiedPrintService.shareDocument(
        documentType: ups.DocumentType.salesInvoice,
        data: invoiceData,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم مشاركة الفاتورة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في المشاركة: $e')));
      }
    }
  }

  Future<void> _exportToPDF() async {
    // Capture context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Fetch detailed report data (with joins)
    final reportData = await widget.db.invoiceDao.getInvoicesWithDetails(
      _startDate,
      _endDate,
    );

    if (reportData.isEmpty) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
      }
      return;
    }

    // 2. Export using the specialized Sales Report method
    await ExportService().exportSalesReport(
      title: 'تقرير المبيعات',
      data: reportData,
      fileName:
          'sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _exportToExcel() async {
    if (_invoices.isEmpty) return;
    final l10n = AppLocalizations.of(context);

    final headers = [
      '#',
      l10n.customer_name,
      l10n.date,
      l10n.total_amount,
      l10n.status,
    ];

    final columns = ['id', 'customer', 'date', 'total', 'status'];

    final data = _invoices
        .map(
          (inv) => {
            'id': inv.id.toString(),
            'customer': inv.customerName,
            'date': DateFormat('yyyy/MM/dd HH:mm').format(inv.date),
            'total': inv.totalAmount.toStringAsFixed(2),
            'status': inv.status == 'paid' ? 'مدفوع' : 'آجل',
          },
        )
        .toList();

    await ExportService().exportToExcel(
      title: 'Sales_Report',
      headers: headers,
      columns: columns,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoice_list), // "قائمة الفواتير"
        actions: [
          if (!_isDayOpen)
            TextButton.icon(
              onPressed: _openNewDay,
              icon: const Icon(Icons.lock_open, color: Colors.red),
              label: Text(
                l10n.day_is_closed,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_month),
            tooltip: l10n.date_filter,
          ),
          IconButton(
            onPressed: _invoices.isEmpty ? null : _exportToPDF,
            icon: const Icon(Icons.print),
            tooltip: 'Print Summary', // Todo localization
          ),
          IconButton(
            onPressed: _invoices.isEmpty ? null : _exportToExcel,
            icon: const Icon(Icons.file_download),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // DASHBOARD STATS SECTION
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Date Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${DateFormat('yyyy-MM-dd').format(_startDate)}  -  ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Cards
                        Row(
                          children: [
                            _buildStatCard(
                              l10n.total_sales,
                              _totalSales,
                              Colors.blue,
                              l10n.currency,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              l10n.total_expenses,
                              _totalExpenses,
                              Colors.red,
                              l10n.currency,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              'إجمالي المديونيات', // Total Receivables (Debt owed to us)
                              _totalReceivables,
                              Colors.orange,
                              l10n.currency,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              'الرصيد الحالي', // Current Balance (Cash in hand)
                              _currentBalance,
                              Colors.green,
                              l10n.currency,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // "New Invoice" Button prominent here too?
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showNewInvoiceDialog,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              l10n.new_invoice,
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: isDark
                                  ? Colors.white
                                  : Colors.black,
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // INVOICES LIST
                _invoices.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text(
                            l10n.no_data,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final invoice = _invoices[index];
                          final isCredit = invoice.status != 'paid';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                child: Icon(
                                  isCredit ? Icons.access_time : Icons.check,
                                  color: isCredit
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              title: Text(
                                invoice.customerName ?? 'عميل غير محدد',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '#${invoice.id} - ${DateFormat('yyyy-MM-dd HH:mm').format(invoice.date)}',
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('عرض'),
                                      ],
                                    ),
                                    onTap: () => _viewInvoice(context, invoice),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.print),
                                        SizedBox(width: 8),
                                        Text('طباعة'),
                                      ],
                                    ),
                                    onTap: () =>
                                        _printInvoiceNew(context, invoice),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        Icon(Icons.share),
                                        SizedBox(width: 8),
                                        Text('مشاركة'),
                                      ],
                                    ),
                                    onTap: () =>
                                        _shareInvoiceNew(context, invoice),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Open details
                              },
                            ),
                          );
                        }, childCount: _invoices.length),
                      ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    Color color,
    String currency,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${value.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
