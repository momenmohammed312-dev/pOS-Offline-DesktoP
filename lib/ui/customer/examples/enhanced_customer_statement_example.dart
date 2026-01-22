import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/ui/customer/services/enhanced_customer_statement_generator.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

class EnhancedCustomerStatementExample extends StatefulWidget {
  const EnhancedCustomerStatementExample({super.key});

  @override
  State<EnhancedCustomerStatementExample> createState() =>
      _EnhancedCustomerStatementExampleState();
}

class _EnhancedCustomerStatementExampleState
    extends State<EnhancedCustomerStatementExample> {
  late final AppDatabase _db;

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _db = AppDatabase(drift.DatabaseConnection(NativeDatabase.memory()));
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
      final customers = await _db.customerDao.getAllCustomers();
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
      await EnhancedCustomerStatementGenerator.generateStatement(
        db: _db,
        customerId: _selectedCustomerId!,
        customerName: _customers.firstWhere(
          (c) => c['id'] == _selectedCustomerId,
        )['name'],
        fromDate: _fromDate!,
        toDate: _toDate!,
        openingBalance: 0.0, // Simplified for example
        currentBalance: await _db.ledgerDao.getRunningBalance(
          'Customer',
          _selectedCustomerId!,
        ),
      );

      if (mounted) {
        _showSuccessDialog('Customer statement generated successfully!');
      }
    } catch (e) {
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
