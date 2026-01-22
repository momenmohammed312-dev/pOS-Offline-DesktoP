import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/export_service.dart';
import 'package:pos_offline_desktop/l10n/l10n.dart';
import '../add_edit_customer_page.dart'; // Import the new page
import 'customer_details_dialog.dart';

import '../../widgets/widgets.dart';
import 'widgets.dart';
import '../../payment/integrated_payment_dialog.dart';

class CustomerContainer extends ConsumerStatefulWidget {
  final AppDatabase db;

  const CustomerContainer({super.key, required this.db});

  @override
  ConsumerState<CustomerContainer> createState() => _CustomerContainerState();
}

class _CustomerContainerState extends ConsumerState<CustomerContainer> {
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  Map<String, double> customerBalances = {};
  final TextEditingController _searchController = TextEditingController();

  // Dashboard Stats
  double _totalSales = 0.0;
  double _totalExpenses = 0.0;
  double _totalReceivables = 0.0;
  double _currentBalance = 0.0;

  // Date Filter State
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _loadData();
    widget.db.customerDao.watchAllCustomers().listen((event) {
      if (mounted) {
        setState(() {
          customers = event;
          filteredCustomers = event;
        });
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      // 1. Customer Balances
      final balances = <String, double>{};
      for (final customer in customers) {
        try {
          final balance = await widget.db.ledgerDao.getRunningBalance(
            'Customer',
            customer.id,
          );
          balances[customer.id] = balance;
        } catch (e) {
          balances[customer.id] = customer.openingBalance;
        }
      }

      // 2. Invoices (Filtered)
      final invoices = await widget.db.invoiceDao.getInvoicesByDateRange(
        _startDate,
        _endDate,
      );

      // 3. Expenses (Filtered)
      double totalExpenses = 0;
      try {
        totalExpenses = await widget.db.expenseDao.getTotalExpenses(
          from: _startDate,
          to: _endDate,
        );
      } catch (e) {
        debugPrint('Error loading expenses in customer list: $e');
      }

      // 4. Current Balance (Global)
      final currentBalance = await widget.db.ledgerDao.getRunningBalance(
        'Bank',
        'Cash',
      );

      // 5. Total Sales
      final totalSales = invoices.fold<double>(
        0.0,
        (sum, inv) => sum + inv.totalAmount,
      );

      // 6. Total Receivables
      final totalReceivables = await widget.db.invoiceDao.getTotalReceivables();

      if (mounted) {
        setState(() {
          customerBalances = balances;
          _totalSales = totalSales;
          _totalExpenses = totalExpenses;
          _totalReceivables = totalReceivables;
          _currentBalance = currentBalance;
        });
      }
    } catch (e) {
      debugPrint('Error loading customer data: $e');
    }
  }

  void _searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = customers.where((customer) {
      return customer.name.toLowerCase().contains(lowerQuery) ||
          (customer.phone ?? '').toLowerCase().contains(lowerQuery) ||
          (customer.address ?? '').toLowerCase().contains(lowerQuery);
    }).toList();

    if (mounted) {
      setState(() {
        filteredCustomers = filtered;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) {
        return DeleteConfirmationDialog(
          name: customer.name,
          onConfirm: () async {
            await widget.db.customerDao.deleteCustomer(customer.id);
          },
        );
      },
    );
  }

  void _editCustomer(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCustomerPage(customer: customer),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  // REPLACED: _showCustomerTransactions with CustomerDetailsDialog
  Future<void> _showCustomerDetails(Customer customer) async {
    await showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(
        customer: customer,
        db: widget.db,
        onDataChanged: _loadData, // Refresh balances when payments happen
      ),
    );
  }

  void _showPaymentDialog(Customer customer) {
    final balance = customerBalances[customer.id] ?? 0.0;
    final initialAmount = balance > 0 ? balance : 0.0;
    showDialog(
      context: context,
      builder: (context) => IntegratedPaymentDialog(
        db: widget.db,
        totalAmount: initialAmount,
        customerId: customer.id,
        customerName: customer.name,
        onPaymentComplete: (paymentData) {
          _loadData();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DASHBOARD STATS SECTION
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${DateFormat('yyyy-MM-dd').format(_startDate)}  -  ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    _buildStatCard(
                      context.l10n.total_sales,
                      _totalSales,
                      Colors.blue,
                      context.l10n.currency,
                    ),
                    const Gap(8),
                    _buildStatCard(
                      context.l10n.total_expenses,
                      _totalExpenses,
                      Colors.red,
                      context.l10n.currency,
                    ),
                    const Gap(8),
                    _buildStatCard(
                      'إجمالي المديونيات',
                      _totalReceivables,
                      Colors.orange,
                      context.l10n.currency,
                    ),
                    const Gap(8),
                    _buildStatCard(
                      'الرصيد الحالي',
                      _currentBalance,
                      Colors.green,
                      context.l10n.currency,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Gap(16),

        // Header Row (Title, Add, Print, Export, Date)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.customer_list,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),

            Row(
              children: [
                // Add Customer
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditCustomerPage(),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.l10n.add_customer),
                ),
                const Gap(8),
                // NEW: Date Filter
                IconButton(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month),
                  tooltip: context.l10n.date_filter,
                  color: Colors.blue,
                ),
                // NEW: Print All
                IconButton(
                  onPressed: () async {
                    if (filteredCustomers.isEmpty) return;
                    // Prepare data for printing summary
                    final summaryData = <Map<String, dynamic>>[];
                    for (final c in filteredCustomers) {
                      final balance = customerBalances[c.id] ?? 0.0;

                      // Calculate "Paid" in the selected date range
                      final txs = await widget.db.ledgerDao
                          .getCustomerTransactionsByDateRange(
                            c.id,
                            _startDate,
                            _endDate,
                          );
                      final paidInRange = txs.fold(
                        0.0,
                        (sum, t) => sum + t.credit,
                      );

                      summaryData.add({
                        'name': c.name,
                        'paid': paidInRange,
                        'balance': balance,
                      });
                    }

                    await ExportService().printCustomerSummaryReport(
                      customers: summaryData,
                      dateRange: DateTimeRange(
                        start: _startDate,
                        end: _endDate,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print),
                  tooltip: 'Print All',
                ),
                // Export Excel
                IconButton(
                  onPressed: () async =>
                      await exportCustomersToExcel(widget.db, context),
                  icon: const Icon(Icons.file_download),
                  tooltip: context.l10n.export,
                ),
              ],
            ),
          ],
        ),

        const Gap(12),
        SearchWidget(
          controller: _searchController,
          onSearch: _searchCustomers,
          hintText: 'Search Customers',
        ),
        const Gap(12),

        // Table
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: widget.db.customerDao.watchAllCustomers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final customers = filteredCustomers;
              if (customers.isEmpty) {
                return const Center(child: Text('No customers available.'));
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 350,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 0.8,
                      ),
                      // ... styles ...
                      columns: const [
                        DataColumn(label: Text('SL')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Contact')),
                        DataColumn(label: Text('Address')),
                        DataColumn(label: Text('Balance')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: List.generate(customers.length, (index) {
                        final customer = customers[index];
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(Text(customer.name)),
                            DataCell(Text(customer.phone ?? '')),
                            DataCell(Text(customer.address ?? '')),
                            DataCell(
                              Text(
                                '${(customerBalances[customer.id] ?? 0.0).toStringAsFixed(2)} ج.م',
                                style: TextStyle(
                                  color:
                                      (customerBalances[customer.id] ?? 0.0) >=
                                          0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  // Detail View (Transactions) - Updated to use _showCustomerDetails
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showCustomerDetails(customer),
                                    tooltip: 'Details',
                                  ),

                                  // Quick Actions
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showPaymentDialog(customer),
                                    icon: const Icon(
                                      Icons.payment,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    label: const Text(
                                      'سداد',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const Gap(4),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editCustomer(customer),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirmation(customer),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    Color color,
    String currency,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
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
    );
  }
}
