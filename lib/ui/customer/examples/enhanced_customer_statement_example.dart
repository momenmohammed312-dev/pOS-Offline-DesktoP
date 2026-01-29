import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/ui/customer/services/enhanced_customer_statement_generator.dart';
import 'package:intl/intl.dart';

class EnhancedCustomerStatementExample extends StatefulWidget {
  final AppDatabase db;

  const EnhancedCustomerStatementExample({super.key, required this.db});

  @override
  State<EnhancedCustomerStatementExample> createState() =>
      _EnhancedCustomerStatementExampleState();
}

class _EnhancedCustomerStatementExampleState
    extends State<EnhancedCustomerStatementExample> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _setDefaultDateRange();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    setState(() {
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await widget.db.customerDao.getAllCustomers();
      setState(() {
        _customers = customers
            .map(
              (customer) => {
                'id': customer.id,
                'name': customer.name,
                'phone': customer.phone,
                'balance': customer.openingBalance,
              },
            )
            .toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to load customers: $e');
    }
  }

  Future<void> _generateStatement() async {
    if (_selectedCustomerId == null || _fromDate == null || _toDate == null) {
      _showErrorDialog('Please select customer and date range');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('=== STARTING STATEMENT GENERATION ===');
      debugPrint('Customer ID: $_selectedCustomerId');

      // Check if customer exists first
      final customer = await widget.db.customerDao.getCustomerById(
        _selectedCustomerId!,
      );
      if (customer == null) {
        debugPrint('ERROR: Customer not found: $_selectedCustomerId');
        _showErrorDialog('Customer not found: $_selectedCustomerId');
        return;
      }

      debugPrint('Customer found: ${customer.name}');
      debugPrint('Customer ID: ${customer.id}');
      debugPrint('Customer ID type: ${customer.id.runtimeType}');
      debugPrint('Customer ID toString: ${customer.id.toString()}');
      debugPrint('Selected Customer ID: $_selectedCustomerId}');
      debugPrint(
        'Selected Customer ID type: ${_selectedCustomerId.runtimeType}',
      );

      // Check if ID mismatch
      if (customer.id.toString() != _selectedCustomerId) {
        debugPrint('WARNING: Customer ID mismatch!');
        debugPrint('Customer DB ID: ${customer.id.toString()}');
        debugPrint('Selected Customer ID: $_selectedCustomerId');
        debugPrint('Using customer DB ID for transactions...');
        _selectedCustomerId = customer.id.toString();
      }

      debugPrint('FINAL Customer ID being used: $_selectedCustomerId');
      debugPrint('=== EXAMPLE DEBUG: Using correct UUID for transactions ===');

      // Test with very wide date range to get all transactions
      final wideFromDate = DateTime(2020, 1, 1); // Very old date
      final wideToDate = DateTime.now(); // Until today

      debugPrint('Using wide date range: $wideFromDate to $wideToDate');

      // Try to get all transactions without date filter first
      try {
        debugPrint('EXAMPLE: Getting all transactions...');
        debugPrint('EXAMPLE: Using customer ID: ${_selectedCustomerId!}');
        debugPrint(
          'EXAMPLE: Using customer ID type: ${_selectedCustomerId.runtimeType}',
        );

        final allTransactions = await widget.db.ledgerDao
            .getTransactionsByEntity('Customer', _selectedCustomerId!);
        debugPrint(
          'EXAMPLE: SUCCESS: Found ${allTransactions.length} total transactions',
        );

        // Show first 5 transactions for debugging
        for (int i = 0; i < allTransactions.length && i < 5; i++) {
          final tx = allTransactions[i];
          debugPrint(
            'EXAMPLE: Transaction $i: ${tx.description} - Date: ${tx.date} - Debit: ${tx.debit}, Credit: ${tx.credit}',
          );
        }

        // Check if any transactions exist
        if (allTransactions.isEmpty) {
          debugPrint(
            'EXAMPLE: WARNING: No transactions found for this customer at all!',
          );
          debugPrint(
            'EXAMPLE: This means invoices are not creating ledger entries for customers!',
          );
          debugPrint(
            'EXAMPLE: Or the customer ID in invoices is different from the customer ID used here!',
          );

          // Let's try to find transactions for different customer IDs
          debugPrint(
            'EXAMPLE: Trying to find transactions for any customer...',
          );
          final allCustomerTransactions = await widget.db.ledgerDao
              .getAllTransactions();
          debugPrint(
            'EXAMPLE: Found ${allCustomerTransactions.length} total ledger transactions',
          );

          // Show first 3 transactions to see the customer IDs used
          for (int i = 0; i < allCustomerTransactions.length && i < 3; i++) {
            final tx = allCustomerTransactions[i];
            debugPrint(
              'EXAMPLE: Ledger TX $i: Entity: ${tx.entityType}, Ref ID: ${tx.refId}, Description: ${tx.description}',
            );
          }

          // Check if there are any Customer transactions at all
          final customerTransactions = allCustomerTransactions
              .where((tx) => tx.entityType == 'Customer')
              .toList();
          debugPrint(
            'EXAMPLE: Found ${customerTransactions.length} Customer transactions in total',
          );

          // Show unique customer IDs in ledger
          final uniqueCustomerIds = customerTransactions
              .map((tx) => tx.refId)
              .toSet()
              .toList();
          debugPrint(
            'EXAMPLE: Unique Customer IDs in ledger: $uniqueCustomerIds',
          );
        } else {
          debugPrint(
            'EXAMPLE: INFO: Customer has transactions, checking date range...',
          );

          // Verify transaction data integrity
          debugPrint('EXAMPLE: === TRANSACTION DATA VERIFICATION ===');
          for (int i = 0; i < allTransactions.length && i < 3; i++) {
            final tx = allTransactions[i];
            debugPrint(
              'EXAMPLE: TX $i - ID: ${tx.id}, Entity: ${tx.entityType}, Ref ID: ${tx.refId}',
            );
            debugPrint(
              'EXAMPLE: TX $i - Date: ${tx.date}, Description: ${tx.description}',
            );
            debugPrint(
              'EXAMPLE: TX $i - Debit: ${tx.debit}, Credit: ${tx.credit}',
            );
            debugPrint('EXAMPLE: TX $i - Created At: ${tx.createdAt}');
          }
        }
      } catch (e) {
        debugPrint('EXAMPLE: ERROR getting transactions: $e');
      }

      // Get opening balance from the beginning of time
      debugPrint('Getting opening balance...');
      final openingBalance = await widget.db.ledgerDao.getRunningBalance(
        'Customer',
        _selectedCustomerId!,
        upToDate: wideFromDate.subtract(const Duration(days: 1)),
      );

      debugPrint('Opening Balance: $openingBalance');

      // Get current balance
      debugPrint('Getting current balance...');
      final currentBalance = await widget.db.ledgerDao.getRunningBalance(
        'Customer',
        _selectedCustomerId!,
        upToDate: wideToDate,
      );

      debugPrint('Current Balance: $currentBalance');

      debugPrint('Generating PDF statement...');
      await EnhancedCustomerStatementGenerator.generateStatement(
        db: widget.db,
        customerId: _selectedCustomerId!,
        customerName: customer.name,
        fromDate: wideFromDate, // Use wide date range
        toDate: wideToDate, // Use wide date range
        openingBalance: openingBalance,
        currentBalance: currentBalance,
      );

      debugPrint('=== STATEMENT GENERATION COMPLETED ===');

      if (mounted) {
        _showSuccessDialog('Customer statement generated successfully!');
      }
    } catch (e) {
      debugPrint('Error generating statement: $e');
      _showErrorDialog('Failed to generate statement: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Customer Statement'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with branding
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Developed by MO2',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enhanced Customer Statement Generator',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate professional PDF statements with nested item details',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Customer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose a customer',
                      ),
                      items: _customers.map((customer) {
                        return DropdownMenuItem<String>(
                          value: customer['id'] as String,
                          child: Text(
                            '${customer['name']} (${customer['phone'] ?? 'No phone'})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCustomerId = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'From Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _fromDate != null
                                    ? DateFormat(
                                        'yyyy/MM/dd',
                                      ).format(_fromDate!)
                                    : 'Select start date',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'To Date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _toDate != null
                                    ? DateFormat('yyyy/MM/dd').format(_toDate!)
                                    : 'Select end date',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateStatement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf),
                          SizedBox(width: 8),
                          Text(
                            'Generate Enhanced Statement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Features List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Features Included:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      '✓',
                      'Professional "Developed by MO2" branding',
                    ),
                    _buildFeatureItem('✓', 'Customer name and balance summary'),
                    _buildFeatureItem('✓', 'Date range display'),
                    _buildFeatureItem('✓', '6-column transaction table'),
                    _buildFeatureItem('✓', 'Nested item details for sales'),
                    _buildFeatureItem('✓', 'Red color for debt amounts'),
                    _buildFeatureItem('✓', 'Professional Arabic typography'),
                    _buildFeatureItem('✓', 'Grid lines for clarity'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? _fromDate ?? DateTime.now()
          : _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }
}
