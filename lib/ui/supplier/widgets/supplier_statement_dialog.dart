import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/database/dao/supplier_dao.dart';
import 'package:pos_offline_desktop/core/services/purchase_print_service_simple.dart';

class SupplierStatementDialog extends StatefulWidget {
  final AppDatabase database;
  final Supplier supplier;

  const SupplierStatementDialog({
    super.key,
    required this.database,
    required this.supplier,
  });

  @override
  State<SupplierStatementDialog> createState() =>
      _SupplierStatementDialogState();
}

class _SupplierStatementDialogState extends State<SupplierStatementDialog> {
  bool _isLoading = true;
  List<LedgerTransaction> _transactions = [];
  double _currentBalance = 0.0;
  late final SupplierDao _supplierDao;

  @override
  void initState() {
    super.initState();
    _supplierDao = SupplierDao(widget.database);
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    try {
      final transactions = await widget.database
          .customSelect(
            '''SELECT * FROM ledger_transactions 
           WHERE entity_type = 'Supplier' AND ref_id = ?
           ORDER BY date DESC''',
            variables: [drift.Variable.withString(widget.supplier.id)],
          )
          .get();

      final balance = await _supplierDao.getSupplierBalance(widget.supplier.id);

      setState(() {
        _transactions = transactions
            .map(
              (row) => LedgerTransaction(
                id: row.read<String>('id'),
                entityType: row.read<String>('entity_type'),
                refId: row.read<String>('ref_id'),
                date: row.read<DateTime>('date'),
                description: row.read<String>('description'),
                debit: row.read<double>('debit'),
                credit: row.read<double>('credit'),
                origin: row.read<String>('origin'),
              ),
            )
            .toList();
        _currentBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل كشف الحساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateRunningBalance(int index) {
    double balance = 0.0;
    for (int i = _transactions.length - 1; i >= index; i--) {
      final transaction = _transactions[i];
      balance += transaction.credit - transaction.debit;
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كشف حساب المورد',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        Text(
                          widget.supplier.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
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
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الرصيد الحالي',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${_currentBalance.toStringAsFixed(2)} ج.م',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _currentBalance > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد معاملات',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final runningBalance = _calculateRunningBalance(index);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: transaction.debit > 0
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              child: Icon(
                                transaction.debit > 0
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: transaction.debit > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(
                              transaction.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(transaction.date),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (transaction.debit > 0)
                                  Text(
                                    '${transaction.debit.toStringAsFixed(2)} ج.م',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (transaction.credit > 0)
                                  Text(
                                    '${transaction.credit.toStringAsFixed(2)} ج.م',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  '${runningBalance.toStringAsFixed(2)} ج.م',
                                  style: TextStyle(
                                    color: runningBalance > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Footer
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي المعاملات: ${_transactions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Print supplier statement
                          final printService = PurchasePrintService(
                            widget.database,
                          );
                          printService.printSupplierStatement(
                            int.parse(widget.supplier.id),
                          );
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('طباعة'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for ledger transactions
class LedgerTransaction {
  final String id;
  final String entityType;
  final String refId;
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final String origin;

  LedgerTransaction({
    required this.id,
    required this.entityType,
    required this.refId,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.origin,
  });
}
