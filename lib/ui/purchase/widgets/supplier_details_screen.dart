import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/enhanced_purchase_dao.dart';
import '../../../core/provider/app_database_provider.dart';

class SupplierDetailsScreen extends ConsumerStatefulWidget {
  final EnhancedSupplier supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsScreen> createState() =>
      _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends ConsumerState<SupplierDetailsScreen> {
  late final AppDatabase _database;
  late final EnhancedPurchaseDao _purchaseDao;
  List<EnhancedPurchase> _purchases = [];
  List<SupplierPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = ref.read(appDatabaseProvider);
    _purchaseDao = EnhancedPurchaseDao(_database);
    _loadSupplierData();
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

      setState(() {
        _purchases = purchases;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('تفاصيل المورد'),
        backgroundColor: Color(0xFF2D2D3D),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSupplierData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supplier Info Card
                  _buildSupplierInfoCard(),
                  SizedBox(height: 20),

                  // Balance Summary
                  _buildBalanceSummary(),
                  SizedBox(height: 20),

                  // Tabs for Purchases and Payments
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.purple,
                          unselectedLabelColor: Colors.grey[400],
                          indicatorColor: Colors.purple,
                          tabs: [
                            Tab(text: 'فواتير المشتريات'),
                            Tab(text: 'المدفوعات'),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            children: [
                              _buildPurchasesList(),
                              _buildPaymentsList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _recordPayment(),
        tooltip: 'سداد دفعة',
        backgroundColor: Colors.green,
        child: Icon(Icons.payment),
      ),
    );
  }

  Widget _buildSupplierInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple,
                radius: 30,
                child: Icon(Icons.business, color: Colors.white, size: 30),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.supplier.businessName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.supplier.contactPerson != null)
                      Text(
                        'الشخص المسؤول: ${widget.supplier.contactPerson}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoRow('رقم الهاتف', widget.supplier.phone),
          if (widget.supplier.address != null)
            _buildInfoRow('العنوان', widget.supplier.address!),
          if (widget.supplier.email != null)
            _buildInfoRow('البريد الإلكتروني', widget.supplier.email!),
          if (widget.supplier.taxNumber != null)
            _buildInfoRow('الرقم الضريبي', widget.supplier.taxNumber!),
          _buildInfoRow('الرمز البريدي', widget.supplier.zipCode),
          _buildInfoRow('الولاية', widget.supplier.state),
          if (widget.supplier.notes != null)
            _buildInfoRow('ملاحظات', widget.supplier.notes!),
          _buildInfoRow(
            'تاريخ الإنشاء',
            DateFormat('yyyy-MM-dd HH:mm').format(widget.supplier.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary() {
    final totalPurchases = _purchases.fold(
      0.0,
      (sum, p) => sum + p.totalAmount,
    );
    final totalPaid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final remainingBalance = totalPurchases - totalPaid;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remainingBalance > 0
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحساب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          _buildBalanceRow('إجمالي المشتريات', totalPurchases, Colors.purple),
          _buildBalanceRow('إجمالي المدفوعات', totalPaid, Colors.green),
          Divider(color: Colors.grey[600]),
          _buildBalanceRow(
            'الرصيد المتبقي',
            remainingBalance,
            remainingBalance > 0 ? Colors.red : Colors.green,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesList() {
    if (_purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 64, color: Colors.grey[600]),
            SizedBox(height: 16),
            Text(
              'لا توجد فواتير مشتريات',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        final purchase = _purchases[index];
        return Card(
          color: Color(0xFF3D3D4D),
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.receipt, color: Colors.purple),
            title: Text(
              purchase.purchaseNumber,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${DateFormat('yyyy-MM-dd').format(purchase.purchaseDate)} - ${purchase.paymentMethod}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${purchase.totalAmount.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  purchase.isCreditPurchase ? 'آجل' : 'نقدي',
                  style: TextStyle(
                    color: purchase.isCreditPurchase
                        ? Colors.orange
                        : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () => _showPurchaseDetails(purchase),
          ),
        );
      },
    );
  }

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[600]),
            SizedBox(height: 16),
            Text(
              'لا توجد مدفوعات',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          color: Color(0xFF3D3D4D),
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.payment, color: Colors.green),
            title: Text(
              payment.paymentNumber,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${DateFormat('yyyy-MM-dd').format(payment.paymentDate)} - ${payment.paymentMethod}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: Text(
              '${payment.amount.toStringAsFixed(2)} ج.م',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showPaymentDetails(payment),
          ),
        );
      },
    );
  }

  void _showPurchaseDetails(EnhancedPurchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D3D),
        title: Text('تفاصيل الفاتورة', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('رقم الفاتورة', purchase.purchaseNumber),
              _buildInfoRow(
                'التاريخ',
                DateFormat('yyyy-MM-dd').format(purchase.purchaseDate),
              ),
              _buildInfoRow('طريقة الدفع', purchase.paymentMethod),
              _buildInfoRow(
                'الإجمالي الفرعي',
                '${purchase.subtotal.toStringAsFixed(2)} ج.م',
              ),
              _buildInfoRow(
                'الإجمالي',
                '${purchase.totalAmount.toStringAsFixed(2)} ج.م',
              ),
              _buildInfoRow(
                'المدفوع',
                '${purchase.paidAmount.toStringAsFixed(2)} ج.م',
              ),
              _buildInfoRow(
                'المتبقي',
                '${purchase.remainingAmount.toStringAsFixed(2)} ج.م',
              ),
              if (purchase.notes != null)
                _buildInfoRow('ملاحظات', purchase.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(SupplierPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D3D),
        title: Text('تفاصيل الدفعة', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('رقم الدفعة', payment.paymentNumber),
              _buildInfoRow(
                'التاريخ',
                DateFormat('yyyy-MM-dd').format(payment.paymentDate),
              ),
              _buildInfoRow(
                'المبلغ',
                '${payment.amount.toStringAsFixed(2)} ج.م',
              ),
              _buildInfoRow('طريقة الدفع', payment.paymentMethod),
              if (payment.referenceNumber != null)
                _buildInfoRow('رقم المرجع', payment.referenceNumber!),
              if (payment.notes != null)
                _buildInfoRow('ملاحظات', payment.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  void _recordPayment() {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        supplier: widget.supplier,
        onPaymentRecorded: () {
          _loadSupplierData(); // Refresh data
        },
      ),
    );
  }
}

class RecordPaymentDialog extends StatefulWidget {
  final EnhancedSupplier supplier;
  final VoidCallback onPaymentRecorded;

  const RecordPaymentDialog({
    super.key,
    required this.supplier,
    required this.onPaymentRecorded,
  });

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D3D),
          title: Text(
            'سداد دفعة - ${widget.supplier.businessName}',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الرصيد الحالي: ${widget.supplier.currentBalance.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    color: widget.supplier.currentBalance > 0
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'المبلغ*',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Color(0xFF3D3D4D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: 'ج.م',
                    suffixStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '0');
                    if (amount == null || amount <= 0) {
                      return 'يرجى إدخال مبلغ صحيح';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'طريقة الدفع',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Color(0xFF3D3D4D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Color(0xFF3D3D4D),
                  style: TextStyle(color: Colors.white),
                  items: [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text(
                        'نقدي',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text(
                        'تحويل بنكي',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'check',
                      child: Text('شيك', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _paymentMethod = value!),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'رقم المرجع',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Color(0xFF3D3D4D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final database = ref.read(appDatabaseProvider);
                  final purchaseDao = EnhancedPurchaseDao(database);
                  final amount = double.parse(_amountController.text);

                  // Record payment
                  await purchaseDao.insertPayment(
                    SupplierPaymentsCompanion.insert(
                      supplierId: widget.supplier.id,
                      paymentNumber:
                          'PAY-${DateTime.now().millisecondsSinceEpoch}',
                      paymentDate: DateTime.now(),
                      amount: amount,
                      paymentMethod: _paymentMethod,
                      referenceNumber: _referenceController.text.isEmpty
                          ? drift.Value(null)
                          : drift.Value(_referenceController.text),
                    ),
                  );

                  // Update supplier balance
                  final updatedSupplier = widget.supplier.copyWith(
                    currentBalance: widget.supplier.currentBalance - amount,
                    updatedAt: DateTime.now(),
                  );
                  await purchaseDao.updateSupplier(updatedSupplier);

                  widget.onPaymentRecorded();
                  if (mounted) {
                    final navigatorContext = context;
                    Navigator.pop(navigatorContext);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('سداد'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
