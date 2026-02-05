import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/enhanced_purchase_dao.dart';
import '../../../core/database/dao/ledger_dao.dart';
import '../../../core/provider/app_database_provider.dart';
import '../../supplier/services/supplier_statement_generator.dart';

/// Enhanced Supplier Details Screen with Tabs
/// شاشة تفاصيل المورد المحسنة مع التبويبات
class SupplierDetailsScreenWithTabs extends ConsumerStatefulWidget {
  final EnhancedSupplier supplier;

  const SupplierDetailsScreenWithTabs({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsScreenWithTabs> createState() =>
      _SupplierDetailsScreenWithTabsState();
}

class _SupplierDetailsScreenWithTabsState
    extends ConsumerState<SupplierDetailsScreenWithTabs>
    with SingleTickerProviderStateMixin {
  late final AppDatabase _database;
  late final EnhancedPurchaseDao _purchaseDao;
  late final LedgerDao _ledgerDao;
  late TabController _tabController;

  List<EnhancedPurchase> _purchases = [];
  List<SupplierPayment> _payments = [];
  List<LedgerTransactionWithBalance> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _database = ref.read(appDatabaseProvider);
    _purchaseDao = EnhancedPurchaseDao(_database);
    _ledgerDao = LedgerDao(_database);
    _loadSupplierData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplierData() async {
    setState(() => _isLoading = true);

    try {
      final purchases = await _purchaseDao.getPurchasesBySupplier(
        widget.supplier.id,
      );
      final payments = await _purchaseDao.getPaymentsBySupplier(
        widget.supplier.id,
      );
      final transactions = await _ledgerDao.getTransactionsWithRunningBalance(
        'Supplier',
        widget.supplier.id.toString(),
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now(),
      );

      setState(() {
        _purchases = purchases;
        _payments = payments;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل بيانات المورد: $e')),
        );
      }
    }
  }

  Future<void> _generateStatement() async {
    try {
      final fromDate = DateTime.now().subtract(const Duration(days: 90));
      final toDate = DateTime.now();

      await SupplierStatementGenerator.generateStatement(
        db: _database,
        supplierId: widget.supplier.id.toString(),
        supplierName: widget.supplier.businessName,
        fromDate: fromDate,
        toDate: toDate,
        openingBalance:
            0.0, // EnhancedSupplier doesn't have openingBalance, using 0.0
        currentBalance: widget.supplier.currentBalance,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في توليد كشف الحساب: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المورد: ${widget.supplier.businessName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'معلومات عامة'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'المشتريات'),
            Tab(icon: Icon(Icons.payment), text: 'المدفوعات'),
            Tab(icon: Icon(Icons.account_balance), text: 'كشف الحساب'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _generateStatement,
            tooltip: 'طباعة كشف الحساب',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSupplierData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralInfoTab(),
                _buildPurchasesTab(),
                _buildPaymentsTab(),
                _buildStatementTab(),
              ],
            ),
    );
  }

  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier Basic Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المعلومات الأساسية',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('الاسم', widget.supplier.businessName),
                  _buildInfoRow('رقم الهاتف', widget.supplier.phone),
                  _buildInfoRow(
                    'العنوان',
                    widget.supplier.address ?? 'غير متوفر',
                  ),
                  _buildInfoRow(
                    'البريد الإلكتروني',
                    widget.supplier.email ?? 'غير متوفر',
                  ),
                  _buildInfoRow(
                    'الرقم الضريبي',
                    widget.supplier.taxNumber ?? 'غير متوفر',
                  ),
                  _buildInfoRow(
                    'السجل التجاري',
                    widget.supplier.taxNumber ?? 'غير متوفر',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Financial Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المعلومات المالية',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'الرصيد الافتتاحي',
                    '0.00 ج.م', // EnhancedSupplier doesn't have openingBalance
                  ),
                  _buildInfoRow(
                    'الرصيد الحالي',
                    '${widget.supplier.currentBalance.toStringAsFixed(2)} ج.م',
                    valueColor: widget.supplier.currentBalance >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildInfoRow(
                    'حد الائتمان',
                    'غير محدود', // EnhancedSupplier doesn't have creditLimit
                  ),
                  _buildInfoRow(
                    'الحالة',
                    widget.supplier.isCreditAccount ? 'نشط' : 'غير نشط',
                    valueColor: widget.supplier.isCreditAccount
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'إجمالي المشتريات',
                  _purchases.fold(0.0, (sum, p) => sum + p.totalAmount),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'إجمالي المدفوعات',
                  _payments.fold(0.0, (sum, p) => sum + p.amount),
                  Icons.payment,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'عدد الفواتير',
                  _purchases.length.toDouble(),
                  Icons.receipt,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'المتبقي',
                  widget.supplier.currentBalance,
                  Icons.account_balance_wallet,
                  widget.supplier.currentBalance >= 0
                      ? Colors.purple
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesTab() {
    return Column(
      children: [
        // Summary Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('عدد الفواتير', _purchases.length.toString()),
                _buildSummaryItem(
                  'إجمالي المشتريات',
                  '${_purchases.fold(0.0, (sum, p) => sum + p.totalAmount).toStringAsFixed(2)} ج.م',
                ),
                _buildSummaryItem(
                  'متوسط الفاتورة',
                  _purchases.isNotEmpty
                      ? '${(_purchases.fold(0.0, (sum, p) => sum + p.totalAmount) / _purchases.length).toStringAsFixed(2)} ج.م'
                      : '0.00 ج.م',
                ),
              ],
            ),
          ),
        ),

        // Purchases List
        Expanded(
          child: _purchases.isEmpty
              ? const Center(child: Text('لا توجد مشتريات لهذا المورد'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = _purchases[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.blue),
                        title: Text(purchase.purchaseNumber),
                        subtitle: Text(
                          DateFormat(
                            'yyyy-MM-dd',
                          ).format(purchase.purchaseDate),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${purchase.totalAmount.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              purchase.isCreditPurchase ? 'آجل' : 'نقدي',
                              style: TextStyle(
                                fontSize: 12,
                                color: purchase.isCreditPurchase
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showPurchaseDetails(purchase);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    return Column(
      children: [
        // Summary Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('عدد المدفوعات', _payments.length.toString()),
                _buildSummaryItem(
                  'إجمالي المدفوعات',
                  '${_payments.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(2)} ج.م',
                ),
                _buildSummaryItem(
                  'متوسط الدفعة',
                  _payments.isNotEmpty
                      ? '${(_payments.fold(0.0, (sum, p) => sum + p.amount) / _payments.length).toStringAsFixed(2)} ج.م'
                      : '0.00 ج.م',
                ),
              ],
            ),
          ),
        ),

        // Payments List
        Expanded(
          child: _payments.isEmpty
              ? const Center(child: Text('لا توجد مدفوعات لهذا المورد'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.payment, color: Colors.green),
                        title: Text(payment.paymentMethod),
                        subtitle: Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(payment.paymentDate),
                        ),
                        trailing: Text(
                          '${payment.amount.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () {
                          _showPaymentDetails(payment);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatementTab() {
    return Column(
      children: [
        // Balance Summary Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص الرصيد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBalanceRow(
                  'الرصيد الافتتاحي',
                  0.0, // EnhancedSupplier doesn't have openingBalance
                  Colors.grey,
                ),
                _buildBalanceRow(
                  'إجمالي المشتريات (دائن)',
                  _purchases.fold(0.0, (sum, p) => sum + p.totalAmount),
                  Colors.green,
                ),
                _buildBalanceRow(
                  'إجمالي المدفوعات (مدين)',
                  _payments.fold(0.0, (sum, p) => sum + p.amount),
                  Colors.red,
                ),
                const Divider(),
                _buildBalanceRow(
                  'الرصيد الحالي',
                  widget.supplier.currentBalance,
                  widget.supplier.currentBalance >= 0
                      ? Colors.blue
                      : Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),

        // Transactions List
        Expanded(
          child: _transactions.isEmpty
              ? const Center(child: Text('لا توجد معاملات لهذا المورد'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          transaction.transaction.debit > 0
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: transaction.transaction.debit > 0
                              ? Colors.red
                              : Colors.green,
                        ),
                        title: Text(transaction.transaction.description),
                        subtitle: Text(
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(transaction.transaction.date),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (transaction.transaction.debit > 0)
                              Text(
                                '-${transaction.transaction.debit.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (transaction.transaction.credit > 0)
                              Text(
                                '+${transaction.transaction.credit.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text(
                              '${transaction.runningBalance.toStringAsFixed(2)} ج.م',
                              style: TextStyle(
                                fontSize: 12,
                                color: transaction.runningBalance >= 0
                                    ? Colors.blue
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBalanceRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDetails(EnhancedPurchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الفاتورة: ${purchase.purchaseNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('رقم الفاتورة', purchase.purchaseNumber),
              _buildDetailRow(
                'تاريخ الفاتورة',
                DateFormat('yyyy-MM-dd').format(purchase.purchaseDate),
              ),
              _buildDetailRow('المورد', purchase.supplierName),
              _buildDetailRow('هاتف المورد', purchase.supplierPhone),
              _buildDetailRow('طريقة الدفع', purchase.paymentMethod),
              _buildDetailRow(
                'نوع الفاتورة',
                purchase.isCreditPurchase ? 'آجل' : 'نقدي',
              ),
              const Divider(),
              _buildDetailRow(
                'المجموع الفرعي',
                '${purchase.subtotal.toStringAsFixed(2)} ج.م',
              ),
              _buildDetailRow(
                'الضريبة',
                '${purchase.tax.toStringAsFixed(2)} ج.م',
              ),
              _buildDetailRow(
                'الخصم',
                '${purchase.discount.toStringAsFixed(2)} ج.م',
              ),
              _buildDetailRow(
                'الإجمالي',
                '${purchase.totalAmount.toStringAsFixed(2)} ج.م',
                isBold: true,
              ),
              if (purchase.isCreditPurchase) ...[
                const Divider(),
                _buildDetailRow(
                  'الرصيد السابق',
                  '${purchase.previousBalance.toStringAsFixed(2)} ج.م',
                ),
                _buildDetailRow(
                  'المدفوع',
                  '${purchase.paidAmount.toStringAsFixed(2)} ج.م',
                ),
                _buildDetailRow(
                  'المتبقي',
                  '${purchase.remainingAmount.toStringAsFixed(2)} ج.م',
                ),
              ],
              if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow('ملاحظات', purchase.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(SupplierPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الدفع: ${payment.paymentMethod}'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('طريقة الدفع', payment.paymentMethod),
            _buildDetailRow(
              'تاريخ الدفع',
              DateFormat('yyyy-MM-dd HH:mm').format(payment.paymentDate),
            ),
            _buildDetailRow(
              'المبلغ',
              '${payment.amount.toStringAsFixed(2)} ج.م',
              isBold: true,
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty)
              _buildDetailRow('ملاحظات', payment.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
