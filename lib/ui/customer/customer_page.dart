import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:printing/printing.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/enhanced_account_statement_generator.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/widgets.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/edit_customer_dialog.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/customer_details_dialog.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/enhanced_payment_dialog.dart';
import 'package:pos_offline_desktop/ui/customer/widgets/date_range_picker_dialog.dart'
    as custom;

import 'widgets/customer_dashboard.dart';
import 'widgets/enhanced_customer_list.dart';
import 'widgets/enhanced_customer_detail_panel.dart';

class CustomerPage extends ConsumerStatefulWidget {
  final AppDatabase db;

  const CustomerPage({super.key, required this.db});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  Map<String, double> _customerBalances = {};
  bool _showDetailPanel = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Listen to customer updates
    widget.db.customerDao.watchAllCustomers().listen((customers) {
      if (mounted) {
        setState(() {
          _customers = customers;
        });
        _loadCustomerBalances();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final customers = await widget.db.customerDao.getAllCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
        });
      }
      await _loadCustomerBalances();
    } catch (e) {
      debugPrint('Error loading customer data: $e');
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadCustomerBalances() async {
    final balances = <String, double>{};

    for (final customer in _customers) {
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

    if (mounted) {
      setState(() {
        _customerBalances = balances;
      });
    }
  }

  void _onCustomerSelected(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _showDetailPanel = true;
    });
  }

  void _onCustomerEdit(Customer customer) async {
    final updatedData = await showDialog<CustomersCompanion>(
      context: context,
      builder: (context) => EditCustomerDialog(
        customer: customer,
        onCustomerUpdated: (updatedCustomer) async {
          try {
            await widget.db.customerDao.updateCustomer(updatedCustomer);
            await _loadData(); // Refresh the customer list

            // Use a post-frame callback to safely show snackbar
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Customer updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
          } catch (e) {
            // Use a post-frame callback to safely show snackbar
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating customer: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          }
        },
      ),
    );

    if (updatedData != null) {
      // Use post-frame callback to safely show snackbar across async gaps
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Customer updated')));
        }
      });
    }
  }

  void _onAddPayment(Customer customer) {
    final balance = _customerBalances[customer.id] ?? 0.0;
    final outstandingBalance = balance < 0 ? balance.abs() : 0.0;

    showDialog(
      context: context,
      builder: (dialogContext) => EnhancedPaymentDialog(
        customer: customer,
        outstandingBalance: outstandingBalance,
        onPaymentConfirmed: (amount, note) async {
          // Close dialog immediately to avoid context issues
          Navigator.of(dialogContext).pop();

          try {
            // Create payment record
            await widget.db.ledgerDao.insertTransaction(
              LedgerTransactionsCompanion.insert(
                id: '', // Will be auto-generated
                entityType: 'Customer',
                refId: customer.id,
                description:
                    'Payment received: ${note.isNotEmpty ? note : 'No note'}',
                debit: drift.Value(0.0),
                createdAt: drift.Value(DateTime.now()),
                paymentMethod: const drift.Value('Cash'),
                date: DateTime.now(),
                origin: 'payment',
              ),
            );

            // Refresh data
            await _loadData();

            // Use a post-frame callback to safely show snackbar
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment of ${amount.toStringAsFixed(2)} recorded successfully',
                      ),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'View Ledger',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CustomerDetailsDialog(
                                customer: customer,
                                db: widget.db,
                                onDataChanged: _loadData,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              });
            }
          } catch (e) {
            // Use a post-frame callback to safely show snackbar
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error processing payment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }
          }
        },
      ),
    );
  }

  void _onExportPdf(Customer customer) {
    _showDateRangeDialog(customer, (fromDate, toDate) async {
      try {
        final generator = EnhancedAccountStatementGenerator();
        final pdfData = await generator.generateAccountStatement(
          entityName: customer.name,
          entityType: 'Customer',
          entityId: customer.id,
          fromDate: fromDate,
          toDate: toDate,
          ledgerDao: widget.db.ledgerDao,
          invoiceDao: widget.db.invoiceDao,
          customerDao: widget.db.customerDao,
          branchName: 'الفرع الرئيسي المصنع',
        );

        // Save and display the PDF
        await Printing.sharePdf(
          bytes: pdfData,
          filename:
              'account_statement_${customer.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error exporting PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _showDateRangeDialog(
    Customer customer,
    Function(DateTime, DateTime) onDateRangeSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => custom.DateRangePickerDialog(
        initialFromDate: DateTime.now().subtract(const Duration(days: 30)),
        initialToDate: DateTime.now(),
        onDateRangeSelected: onDateRangeSelected,
      ),
    );
  }

  Future<void> _createSampleData() async {
    try {
      // Create sample customers
      await widget.db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust_${DateTime.now().millisecondsSinceEpoch}_1',
          name: 'أحمد محمد علي',
          phone: drift.Value('01234567890'),
          address: drift.Value('القاهرة، مصر الجديدة'),
          openingBalance: drift.Value(0.0),
          status: const drift.Value(1),
          isActive: const drift.Value(true), // Active as boolean
        ),
      );

      await widget.db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust_${DateTime.now().millisecondsSinceEpoch}_2',
          name: 'سارة أحمد خالد',
          phone: drift.Value('01123456789'),
          address: drift.Value('الجيزة، المهندسين'),
          openingBalance: drift.Value(500.0),
          status: const drift.Value(1),
          isActive: const drift.Value(true), // Active as boolean
        ),
      );

      await widget.db.customerDao.insertCustomer(
        CustomersCompanion.insert(
          id: 'cust_${DateTime.now().millisecondsSinceEpoch}_3',
          name: 'محمد علي حسن',
          phone: drift.Value('01098765432'),
          address: drift.Value('الإسكندرية، سان ستيفانو'),
          openingBalance: drift.Value(-200.0),
          status: const drift.Value(1),
          isActive: const drift.Value(true), // Active as boolean
        ),
      );

      // Reload data after adding samples
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة 3 عملاء تجريبيين بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // Main Content Area
          Expanded(
            flex: _showDetailPanel ? 1 : 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dashboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customers',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _createSampleData,
                        icon: const Icon(Icons.add_circle),
                        label: const Text('إضافة بيانات تجريبية'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  CustomerDashboard(
                    db: widget.db,
                    onCustomerSelected: _onCustomerSelected,
                    onRefresh: _loadData,
                  ),
                  const Gap(24),

                  // Customer List
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customers',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Gap(16),
                            Expanded(
                              child: EnhancedCustomerList(
                                customers: _customers,
                                customerBalances: _customerBalances,
                                onCustomerSelected: _onCustomerSelected,
                                onCustomerEdit: _onCustomerEdit,
                                onAddPayment: () =>
                                    _onAddPayment(_selectedCustomer!),
                                onExportPdf: () =>
                                    _onExportPdf(_selectedCustomer!),
                                onRefresh: _loadData,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detail Panel (shown when customer is selected)
          if (_showDetailPanel && _selectedCustomer != null) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EnhancedCustomerDetailPanel(
                  customer: _selectedCustomer!,
                  balance: _customerBalances[_selectedCustomer!.id] ?? 0.0,
                  db: widget.db,
                  onCustomerEdit: _onCustomerEdit,
                  onAddPayment: () => _onAddPayment(_selectedCustomer!),
                  onExportPdf: () => _onExportPdf(_selectedCustomer!),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
