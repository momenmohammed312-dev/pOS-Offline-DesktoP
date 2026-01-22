import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/dao/ledger_dao.dart';
import '../../../core/database/dao/invoice_dao.dart';
import '../widgets/enhanced_account_statement_button.dart';

class EnhancedAccountStatementExample extends StatefulWidget {
  const EnhancedAccountStatementExample({super.key});

  @override
  State<EnhancedAccountStatementExample> createState() =>
      _EnhancedAccountStatementExampleState();
}

class _EnhancedAccountStatementExampleState
    extends State<EnhancedAccountStatementExample> {
  late final LedgerDao ledgerDao;
  late final InvoiceDao invoiceDao;
  Customer? selectedCustomer;
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // This would normally come from your database
    // For demo purposes, we'll create a mock customer
    final mockCustomer = Customer(
      id: 'demo-customer-1',
      name: 'عميل تجريبي',
      phone: '01234567890',
      address: 'العنوان التجريبي',
      openingBalance: 1000.0,
      totalDebt: 0.0,
      totalPaid: 0.0,
      isActive: true,
      status: 1,
      createdAt: DateTime.now(),
    );

    setState(() {
      selectedCustomer = mockCustomer;
      customers = [mockCustomer];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تجربة كشف الحساب المطور'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اختيار العميل',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Customer>(
                      initialValue: selectedCustomer,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر العميل',
                      ),
                      items: customers.map((customer) {
                        return DropdownMenuItem<Customer>(
                          value: customer,
                          child: Text(customer.name),
                        );
                      }).toList(),
                      onChanged: (customer) {
                        setState(() {
                          selectedCustomer = customer;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedCustomer != null)
              EnhancedAccountStatementButton(customer: selectedCustomer!),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الكشف',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• يحتوي على 13 عموداً كما في الصورة المطلوبة\n'
                      '• يدعم تفاصيل المنتجات في عمود البيان\n'
                      '• يتضمن معلومات الفرع في الترويسة\n'
                      '• يحتوي على أرقام الصفحات والتوقيت في التذييل\n'
                      '• يدعم العلامة التجارية MO2.com',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
