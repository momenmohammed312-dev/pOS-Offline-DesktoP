import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

class EnhancedAccountStatementButton extends StatelessWidget {
  final Customer customer;

  const EnhancedAccountStatementButton({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'كشف الحساب المطور',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'اسم العميل: ${customer.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
