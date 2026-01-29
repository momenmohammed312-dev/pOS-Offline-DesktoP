import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/ui/customer/services/enhanced_customer_statement_generator.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

class EnhancedCustomerStatementButton extends StatelessWidget {
  final Customer customer;
  final AppDatabase db;
  final VoidCallback? onSuccess;

  const EnhancedCustomerStatementButton({
    super.key,
    required this.customer,
    required this.db,
    this.onSuccess,
  });

  Future<void> _generateStatement(BuildContext context) async {
    try {
      // Use very wide date range to get all transactions
      final wideFromDate = DateTime(2020, 1, 1); // Very old date
      final wideToDate = DateTime.now(); // Until today

      // Get opening balance from the beginning of time
      final openingBalance = await db.ledgerDao.getRunningBalance(
        'Customer',
        customer.id.toString(),
        upToDate: wideFromDate.subtract(const Duration(days: 1)),
      );

      // Get current balance using same method as example
      final currentBalance = await db.ledgerDao.getRunningBalance(
        'Customer',
        customer.id.toString(),
        upToDate: wideToDate,
      );

      await EnhancedCustomerStatementGenerator.generateStatement(
        db: db,
        customerId: customer.id.toString(),
        customerName: customer.name,
        fromDate: wideFromDate, // Use wide date range
        toDate: wideToDate, // Use wide date range
        openingBalance: openingBalance,
        currentBalance: currentBalance,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enhanced statement generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        onSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _generateStatement(context),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Enhanced Statement'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _generateStatement(context),
          icon: const Icon(Icons.print),
          label: const Text('Print'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}
