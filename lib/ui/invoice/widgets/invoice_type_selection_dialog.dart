import 'package:flutter/material.dart';

class InvoiceTypeSelectionDialog extends StatelessWidget {
  const InvoiceTypeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختيار نوع الفاتورة'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('نقدي'),
              subtitle: const Text('فاتورة بيع نقدًا'),
              leading: const Icon(Icons.money),
              onTap: () => Navigator.of(context).pop('cash'),
            ),
            ListTile(
              title: const Text('آجل'),
              subtitle: const Text('فاتورة بيع بالأجل'),
              leading: const Icon(Icons.account_balance),
              onTap: () => Navigator.of(context).pop('credit'),
            ),
            ListTile(
              title: const Text('ضريبي'),
              subtitle: const Text('فاتورة بيع بضريبة'),
              leading: const Icon(Icons.receipt_long),
              onTap: () => Navigator.of(context).pop('tax'),
            ),
            ListTile(
              title: const Text('مرتجع'),
              subtitle: const Text('فاتورة إرجاع بضاعة'),
              leading: const Icon(Icons.assignment_return),
              onTap: () => Navigator.of(context).pop('return'),
            ),
            ListTile(
              title: const Text('تبديل'),
              subtitle: const Text('فاتورة استبدال بضاعة'),
              leading: const Icon(Icons.swap_horiz),
              onTap: () => Navigator.of(context).pop('exchange'),
            ),
            ListTile(
              title: const Text('توريد'),
              subtitle: const Text('فاتورة شراء من مورد'),
              leading: const Icon(Icons.local_shipping),
              onTap: () => Navigator.of(context).pop('supply'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
