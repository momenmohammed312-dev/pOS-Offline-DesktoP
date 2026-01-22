import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/export_service.dart';
import 'package:pos_offline_desktop/core/services/printer_service.dart';

class ExpensesPage extends StatefulWidget {
  final AppDatabase db;

  const ExpensesPage({super.key, required this.db});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<LedgerTransaction> _expenses = [];
  List<LedgerTransaction> _filteredExpenses = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  final ExportService _exportService = ExportService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);
      final expenses = await widget.db.ledgerDao.getTransactionsByDateRange(
        'Expense',
        'expense',
        startOfMonth,
        today,
      );
      setState(() {
        _expenses = expenses.where((e) => e.origin == 'expense').toList();
        _filteredExpenses = _expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المصروفات: $e')));
      }
    }
  }

  Future<void> _addExpense() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (description.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل بيانات صحيحة')),
      );
      return;
    }

    try {
      await widget.db.ledgerDao.insertTransaction(
        LedgerTransactionsCompanion.insert(
          id: '${DateTime.now().millisecondsSinceEpoch}_expense',
          entityType: 'Expense',
          refId: 'expense',
          date: DateTime.now(),
          description: description,
          debit: const Value(0.0),
          credit: Value(amount),
          origin: 'expense',
          paymentMethod: Value(_selectedPaymentMethod),
        ),
      );

      _descriptionController.clear();
      _amountController.clear();
      await _loadExpenses();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إضافة المصروف بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في إضافة المصروف: $e')));
      }
    }
  }

  void _filterExpenses() {
    if (_startDate == null || _endDate == null) {
      setState(() => _filteredExpenses = _expenses);
      return;
    }

    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        return expense.date.isAfter(
              _startDate!.subtract(const Duration(days: 1)),
            ) &&
            expense.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    });
  }

  Future<void> _exportToPDF() async {
    if (_filteredExpenses.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }

    try {
      final data = _filteredExpenses
          .map(
            (expense) => {
              'date': expense.date,
              'description': expense.description,
              'amount': expense.credit,
              'paymentMethod': expense.paymentMethod,
            },
          )
          .toList();

      await _exportService.exportToPDF(
        title: 'تقرير المصروفات',
        data: data,
        headers: ['التاريخ', 'الوصف', 'المبلغ', 'طريقة الدفع'],
        columns: ['date', 'description', 'amount', 'paymentMethod'],
        fileName: 'تقرير_المصروفات.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التصدير: $e')));
      }
    }
  }

  Future<void> _exportToExcel() async {
    if (_filteredExpenses.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }

    try {
      final data = _filteredExpenses
          .map(
            (expense) => {
              'date': expense.date,
              'description': expense.description,
              'amount': expense.credit,
              'paymentMethod': expense.paymentMethod,
            },
          )
          .toList();

      await _exportService.exportToExcel(
        title: 'تقرير المصروفات',
        data: data,
        headers: ['التاريخ', 'الوصف', 'المبلغ', 'طريقة الدفع'],
        columns: ['date', 'description', 'amount', 'paymentMethod'],
        fileName: 'تقرير_المصروفات.xlsx',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التصدير: $e')));
      }
    }
  }

  Future<void> _printExpenseReceipt(LedgerTransaction expense) async {
    try {
      await PrinterService.printExpenseReceipt(
        expense: {
          'description': expense.description,
          'amount': expense.credit,
          'date': expense.date,
          'paymentMethod': expense.paymentMethod ?? 'cash',
          'receiptNumber': expense.receiptNumber ?? 'EXP-${expense.id}',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم طباعة إيصال المصروف'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getTotalExpenses() {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.credit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المصروفات'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadExpenses),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'تصدير PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _exportToExcel,
            tooltip: 'تصدير Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add Expense Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إضافة مصروف جديد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'وصف المصروف',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'المبلغ (ج.م)',
                                    border: OutlineInputBorder(),
                                    prefixText: 'ج.م ',
                                  ),
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedPaymentMethod,
                                  decoration: const InputDecoration(
                                    labelText: 'طريقة الدفع',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'cash',
                                      child: Text('كاش'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'visa',
                                      child: Text('فيزا'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'bank',
                                      child: Text('تحويل بنكي'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(
                                      () => _selectedPaymentMethod = value!,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),
                          ElevatedButton(
                            onPressed: _addExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('إضافة مصروف'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Filters Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _startDate != null
                                ? DateFormat('yyyy/MM/dd').format(_startDate!)
                                : '',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'من تاريخ',
                            border: OutlineInputBorder(),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _startDate = date);
                              _filterExpenses();
                            }
                          },
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _endDate != null
                                ? DateFormat('yyyy/MM/dd').format(_endDate!)
                                : '',
                          ),
                          decoration: const InputDecoration(
                            labelText: 'إلى تاريخ',
                            border: OutlineInputBorder(),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _endDate = date);
                              _filterExpenses();
                            }
                          },
                        ),
                      ),
                      const Gap(16),
                      ElevatedButton(
                        onPressed: _filterExpenses,
                        child: const Text('تطبيق'),
                      ),
                    ],
                  ),
                ),

                // Summary Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إجمالي المصروفات:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_getTotalExpenses().toStringAsFixed(2)} ج.م',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Expenses List
                Expanded(
                  child: _filteredExpenses.isEmpty
                      ? const Center(child: Text('لا توجد مصروفات'))
                      : ListView.builder(
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = _filteredExpenses[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.money_off,
                                  color: Colors.red.shade700,
                                ),
                                title: Text(expense.description),
                                subtitle: Text(
                                  DateFormat(
                                    'yyyy/MM/dd HH:mm',
                                  ).format(expense.date),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${expense.credit.toStringAsFixed(2)} ج.م',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                        Text(
                                          expense.paymentMethod
                                                  ?.toUpperCase() ??
                                              'CASH',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.print, size: 20),
                                      onPressed: () =>
                                          _printExpenseReceipt(expense),
                                      tooltip: 'طباعة إيصال المصروف',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
