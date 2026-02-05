import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/ui/supplier/widgets/supplier_form_dialog.dart';

class SupplierDetailsDialog extends StatefulWidget {
  final AppDatabase database;
  final Supplier supplier;

  const SupplierDetailsDialog({
    super.key,
    required this.database,
    required this.supplier,
  });

  @override
  State<SupplierDetailsDialog> createState() => _SupplierDetailsDialogState();
}

class _SupplierDetailsDialogState extends State<SupplierDetailsDialog> {
  bool _isLoading = true;
  double _currentBalance = 0.0;
  int _totalPurchases = 0;
  double _totalPurchaseAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSupplierDetails();
  }

  Future<void> _loadSupplierDetails() async {
    try {
      final balance = await widget.database.supplierDao.getSupplierBalance(
        widget.supplier.id,
      );

      // Get purchase statistics
      final purchaseStats = await widget.database
          .customSelect(
            '''SELECT COUNT(*) as count, COALESCE(SUM(total_amount), 0) as total
           FROM purchases 
           WHERE supplier_id = ? AND is_deleted = 0''',
            variables: [drift.Variable.withString(widget.supplier.id)],
          )
          .getSingle();

      setState(() {
        _currentBalance = balance;
        _totalPurchases = purchaseStats.read<int>('count');
        _totalPurchaseAmount = purchaseStats.read<double>('total');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل تفاصيل المورد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.business,
                      size: 30,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.supplier.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        Text(
                          'كود المورد: ${widget.supplier.id}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.supplier.status == 'Active'
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.supplier.status == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              child: Text(
                                widget.supplier.status == 'Active'
                                    ? 'نشط'
                                    : 'غير نشط',
                                style: TextStyle(
                                  color: widget.supplier.status == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Financial Summary
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الملخص المالي',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'الرصيد الحالي',
                                          '${_currentBalance.toStringAsFixed(2)} ج.م',
                                          _currentBalance > 0
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildSummaryItem(
                                          'إجمالي المشتريات',
                                          '$_totalPurchases فاتورة',
                                          Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSummaryItem(
                                    'إجمالي قيمة المشتريات',
                                    '${_totalPurchaseAmount.toStringAsFixed(2)} ج.م',
                                    Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact Information
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'معلومات الاتصال',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    'رقم الهاتف',
                                    widget.supplier.phone ?? '-',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'العنوان',
                                    widget.supplier.address ?? '-',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'تاريخ الإضافة',
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(widget.supplier.createdAt),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'الرصيد الافتتاحي',
                                    '${widget.supplier.openingBalance.toStringAsFixed(2)} ج.م',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => SupplierFormDialog(
                          database: widget.database,
                          supplier: widget.supplier,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
