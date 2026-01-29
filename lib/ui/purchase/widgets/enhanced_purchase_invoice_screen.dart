import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/provider/app_database_provider.dart';
import '../../../core/database/dao/enhanced_purchase_dao.dart';
import '../widgets/enhanced_product_selector.dart';

class EnhancedPurchaseInvoiceScreen extends ConsumerStatefulWidget {
  const EnhancedPurchaseInvoiceScreen({super.key});

  @override
  ConsumerState<EnhancedPurchaseInvoiceScreen> createState() =>
      _EnhancedPurchaseInvoiceScreenState();
}

class _EnhancedPurchaseInvoiceScreenState
    extends ConsumerState<EnhancedPurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<PurchaseItemData> _items = [];
  late final AppDatabase _database;
  late final EnhancedPurchaseDao _purchaseDao;

  // Supplier info
  EnhancedSupplier? _selectedSupplier;
  bool _isCreditPurchase = false;

  // Payment info
  String _paymentMethod = 'cash'; // 'cash', 'credit', 'partial'
  double _paidAmount = 0.0;

  // Controllers
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _database = ref.read(appDatabaseProvider);
    _purchaseDao = EnhancedPurchaseDao(_database);
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('فاتورة توريد جديدة'),
        backgroundColor: Color(0xFF2D2D3D),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business),
            onPressed: () => _showAddSupplierDialog(),
            tooltip: 'إضافة مورد جديد',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Supplier Selection
            _buildSupplierSelector(),
            SizedBox(height: 20),

            // Purchase Type Toggle
            _buildPurchaseTypeToggle(),
            SizedBox(height: 20),

            // Items Section
            _buildItemsSection(),
            SizedBox(height: 20),

            // Totals Section
            if (_items.isNotEmpty) _buildTotalsSection(),
            SizedBox(height: 20),

            // Payment Section
            if (_items.isNotEmpty) _buildPaymentSection(),
            SizedBox(height: 30),

            // Save and Print Button
            ElevatedButton.icon(
              onPressed: _items.isEmpty ? null : () => _saveAndPrint(),
              icon: Icon(Icons.print),
              label: Text('حفظ وطباعة', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(20),
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المورد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          FutureBuilder<List<EnhancedSupplier>>(
            future: _purchaseDao.getAllSuppliers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: Colors.purple),
                );
              }

              final suppliers = snapshot.data!;

              return DropdownButtonFormField<EnhancedSupplier>(
                initialValue: _selectedSupplier,
                decoration: InputDecoration(
                  hintText: 'اختر المورد',
                  filled: true,
                  fillColor: Color(0xFF3D3D4D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: Color(0xFF3D3D4D),
                style: TextStyle(color: Colors.white),
                items: suppliers.map((supplier) {
                  return DropdownMenuItem(
                    value: supplier,
                    child: Text(
                      supplier.businessName,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (supplier) {
                  setState(() => _selectedSupplier = supplier);
                },
                validator: (v) => v == null ? 'يرجى اختيار المورد' : null,
              );
            },
          ),
          if (_selectedSupplier != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF3D3D4D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('الهاتف', _selectedSupplier!.phone),
                  _buildInfoRow(
                    'العنوان',
                    _selectedSupplier!.address ?? 'غير محدد',
                  ),
                  _buildInfoRow(
                    'الرصيد الحالي',
                    '${_selectedSupplier!.currentBalance.toStringAsFixed(2)} ج.م',
                    valueColor: _selectedSupplier!.currentBalance > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseTypeToggle() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: SwitchListTile(
        title: Text(
          'شراء آجل',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        subtitle: Text(
          _isCreditPurchase ? 'سيتم إضافة المبلغ للرصيد' : 'دفع نقدي فوري',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        value: _isCreditPurchase,
        activeThumbColor: Colors.orange,
        onChanged: (value) {
          setState(() {
            _isCreditPurchase = value;
            if (!value) _paymentMethod = 'cash';
          });
        },
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'البنود',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductSelector(),
                icon: Icon(Icons.add, size: 18),
                label: Text('إضافة منتج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              color: Color(0xFF3D3D4D),
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  item.productName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${item.quantity} ${item.unit} × ${item.unitPrice.toStringAsFixed(2)} ج.م',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.totalPrice.toStringAsFixed(2)} ج.م',
                      style: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _items.removeAt(index));
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_items.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'لا توجد بنود\nاضغط "إضافة منتج" للبدء',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final subtotal = _calculateSubtotal();
    final previousBalance = _selectedSupplier?.currentBalance ?? 0.0;
    final total = _isCreditPurchase ? subtotal + previousBalance : subtotal;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildTotalRow('الإجمالي الفرعي', subtotal, Colors.white),
          if (_isCreditPurchase) ...[
            Divider(color: Colors.grey[700]),
            _buildTotalRow('الرصيد السابق', previousBalance, Colors.orange),
            Divider(color: Colors.grey[700], thickness: 2),
            _buildTotalRow(
              'الإجمالي الكلي',
              total,
              Colors.purple,
              fontSize: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (!_isCreditPurchase) return SizedBox.shrink();

    final total =
        _calculateSubtotal() + (_selectedSupplier?.currentBalance ?? 0.0);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3D3D4D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طريقة الدفع',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _paymentMethod = 'credit';
                      _paidAmount = 0.0;
                      _paidAmountController.clear();
                    });
                  },
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentMethod = 'credit';
                            _paidAmount = 0.0;
                            _paidAmountController.clear();
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white),
                            color: _paymentMethod == 'credit'
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          child: _paymentMethod == 'credit'
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('آجل كامل', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _paymentMethod = 'partial';
                    });
                  },
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _paymentMethod = 'partial';
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white),
                            color: _paymentMethod == 'partial'
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          child: _paymentMethod == 'partial'
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('دفع جزئي', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_paymentMethod == 'partial') ...[
            SizedBox(height: 16),
            TextFormField(
              controller: _paidAmountController,
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع',
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
              onChanged: (v) {
                setState(() => _paidAmount = double.tryParse(v) ?? 0.0);
              },
              validator: (v) {
                final amount = double.tryParse(v ?? '0') ?? 0.0;
                if (amount < 0 || amount > total) {
                  return 'المبلغ غير صحيح';
                }
                return null;
              },
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF3D3D4D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المتبقي:', style: TextStyle(color: Colors.white)),
                  Text(
                    '${(total - _paidAmount).toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400])),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    Color color, {
    double fontSize = 16,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _showProductSelector() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF2D2D3D),
      builder: (context) => EnhancedProductSelector(database: _database),
    );

    if (result != null) {
      setState(() {
        _items.add(
          PurchaseItemData(
            productId: result['id'],
            productName: result['name'],
            productBarcode: result['barcode'],
            unit: result['unit'],
            quantity: result['quantity'],
            unitPrice: result['price'],
            totalPrice: result['quantity'] * result['price'],
          ),
        );
      });
    }
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSupplierDialog(
        onSupplierAdded: (supplier) {
          setState(() => _selectedSupplier = supplier);
        },
      ),
    );
  }

  Future<void> _saveAndPrint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى اختيار المورد')));
      return;
    }

    try {
      final purchaseNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch}';
      final subtotal = _calculateSubtotal();
      final previousBalance = _selectedSupplier!.currentBalance;
      final totalAmount = _isCreditPurchase
          ? subtotal + previousBalance
          : subtotal;

      final remainingAmount = _paymentMethod == 'credit'
          ? totalAmount
          : _paymentMethod == 'partial'
          ? totalAmount - _paidAmount
          : 0.0;

      // Create purchase items without purchaseId - DAO will set it
      final items = _items.asMap().entries.map((entry) {
        return EnhancedPurchaseItemsCompanion(
          productId: drift.Value(entry.value.productId),
          productName: drift.Value(entry.value.productName),
          productBarcode: drift.Value(entry.value.productBarcode),
          unit: drift.Value(entry.value.unit),
          quantity: drift.Value(entry.value.quantity),
          unitPrice: drift.Value(entry.value.unitPrice),
          totalPrice: drift.Value(entry.value.totalPrice),
          sortOrder: drift.Value(entry.key),
        );
      }).toList();

      // Save purchase
      await _purchaseDao.createCompletePurchase(
        purchaseNumber: purchaseNumber,
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.businessName,
        supplierPhone: _selectedSupplier!.phone,
        purchaseDate: DateTime.now(),
        subtotal: subtotal,
        totalAmount: totalAmount,
        isCreditPurchase: _isCreditPurchase,
        previousBalance: previousBalance,
        paidAmount: _paidAmount,
        remainingAmount: remainingAmount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ فاتورة التوريد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Data models
class PurchaseItemData {
  final int productId;
  final String productName;
  final String? productBarcode;
  final String unit;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseItemData({
    required this.productId,
    required this.productName,
    this.productBarcode,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class AddSupplierDialog extends ConsumerStatefulWidget {
  final Function(EnhancedSupplier) onSupplierAdded;

  const AddSupplierDialog({required this.onSupplierAdded, super.key});

  @override
  ConsumerState<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends ConsumerState<AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _stateController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF2D2D3D),
      title: Text('إضافة مورد جديد', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'اسم الشركة',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Color(0xFF3D3D4D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
                validator: (v) =>
                    v?.isEmpty == true ? 'يرجى إدخال اسم الشركة' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Color(0xFF3D3D4D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
                validator: (v) =>
                    v?.isEmpty == true ? 'يرجى إدخال رقم الهاتف' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _contactPersonController,
                decoration: InputDecoration(
                  labelText: 'شخص الاتصال',
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
              SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'العنوان',
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: TextStyle(color: Colors.grey[400])),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              final database = ref.read(appDatabaseProvider);
              final purchaseDao = EnhancedPurchaseDao(database);

              await purchaseDao.insertSupplier(
                EnhancedSuppliersCompanion.insert(
                  businessName: _businessNameController.text,
                  phone: _phoneController.text,
                  contactPerson: _contactPersonController.text.isEmpty
                      ? const drift.Value.absent()
                      : drift.Value(_contactPersonController.text),
                  address: _addressController.text.isEmpty
                      ? const drift.Value.absent()
                      : drift.Value(_addressController.text),
                  email: _emailController.text.isEmpty
                      ? const drift.Value.absent()
                      : drift.Value(_emailController.text),
                  taxNumber: _taxNumberController.text.isEmpty
                      ? const drift.Value.absent()
                      : drift.Value(_taxNumberController.text),
                  zipCode: _zipCodeController.text.isEmpty
                      ? '00000'
                      : _zipCodeController.text,
                  state: _stateController.text.isEmpty
                      ? 'غير محدد'
                      : _stateController.text,
                  notes: _notesController.text.isEmpty
                      ? const drift.Value.absent()
                      : drift.Value(_notesController.text),
                  currentBalance: drift.Value(0.0),
                  isCreditAccount: drift.Value(false),
                ),
              );

              // Create supplier object for callback
              final supplier = EnhancedSupplier(
                id: 0, // Will be set by database
                businessName: _businessNameController.text,
                phone: _phoneController.text,
                contactPerson: _contactPersonController.text.isEmpty
                    ? null
                    : _contactPersonController.text,
                address: _addressController.text.isEmpty
                    ? null
                    : _addressController.text,
                email: _emailController.text.isEmpty
                    ? null
                    : _emailController.text,
                taxNumber: _taxNumberController.text.isEmpty
                    ? null
                    : _taxNumberController.text,
                zipCode: _zipCodeController.text.isEmpty
                    ? '00000'
                    : _zipCodeController.text,
                state: _stateController.text.isEmpty
                    ? 'غير محدد'
                    : _stateController.text,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text,
                currentBalance: 0.0,
                isCreditAccount: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              widget.onSupplierAdded(supplier);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          child: Text('حفظ'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    _zipCodeController.dispose();
    _stateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
