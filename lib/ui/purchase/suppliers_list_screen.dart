import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/enhanced_purchase_dao.dart';
import '../../../core/provider/app_database_provider.dart';
import 'widgets/supplier_details_screen.dart';

class SuppliersListScreen extends ConsumerStatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  ConsumerState<SuppliersListScreen> createState() =>
      _SuppliersListScreenState();
}

class _SuppliersListScreenState extends ConsumerState<SuppliersListScreen> {
  late final AppDatabase _database;
  late final EnhancedPurchaseDao _purchaseDao;
  final _searchController = TextEditingController();
  List<EnhancedSupplier> _suppliers = [];
  List<EnhancedSupplier> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _database = ref.read(appDatabaseProvider);
    _purchaseDao = EnhancedPurchaseDao(_database);
    _loadSuppliers();
    _searchController.addListener(_filterSuppliers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final suppliers = await _purchaseDao.getAllSuppliers();
    setState(() {
      _suppliers = suppliers;
      _filteredSuppliers = suppliers;
    });
  }

  void _filterSuppliers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.businessName.toLowerCase().contains(query) ||
            supplier.phone.toLowerCase().contains(query) ||
            (supplier.contactPerson?.toLowerCase().contains(query) ?? false) ||
            (supplier.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E2E),
      appBar: AppBar(
        title: Text('الموردين'),
        backgroundColor: Color(0xFF2D2D3D),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddSupplierDialog(),
            tooltip: 'إضافة مورد جديد',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSuppliers,
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن مورد...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF3D3D4D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),

          // Suppliers list
          Expanded(
            child: _filteredSuppliers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business, size: 64, color: Colors.grey[600]),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد موردين',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSupplierDialog(),
                          icon: Icon(Icons.add),
                          label: Text('إضافة مورد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = _filteredSuppliers[index];
                      return Card(
                        color: Color(0xFF2D2D3D),
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Icon(Icons.business, color: Colors.white),
                          ),
                          title: Text(
                            supplier.businessName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.phone,
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              if (supplier.contactPerson != null)
                                Text(
                                  'الشخص المسؤول: ${supplier.contactPerson}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: supplier.currentBalance > 0
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  supplier.currentBalance > 0
                                      ? 'دين: ${supplier.currentBalance.toStringAsFixed(2)} ج.م'
                                      : 'رصيد: ${supplier.currentBalance.toStringAsFixed(2)} ج.م',
                                  style: TextStyle(
                                    color: supplier.currentBalance > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            color: Color(0xFF3D3D4D),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      color: Colors.purple,
                                    ),
                                    SizedBox(width: 8),
                                    Text('عرض التفاصيل'),
                                  ],
                                ),
                                onTap: () => _viewSupplierDetails(supplier),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('فاتورة جديدة'),
                                  ],
                                ),
                                onTap: () => _createPurchaseInvoice(supplier),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.payment, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('سداد دفعة'),
                                  ],
                                ),
                                onTap: () => _recordPayment(supplier),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('تعديل'),
                                  ],
                                ),
                                onTap: () => _editSupplier(supplier),
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('حذف'),
                                  ],
                                ),
                                onTap: () => _deleteSupplier(supplier),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(),
        tooltip: 'إضافة مورد جديد',
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
    );
  }

  void _viewSupplierDetails(EnhancedSupplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDetailsScreen(supplier: supplier),
      ),
    );
  }

  void _createPurchaseInvoice(EnhancedSupplier supplier) {
    // Navigate to purchase invoice with pre-selected supplier
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم فتح فاتورة توريد جديدة للمورد: ${supplier.businessName}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _recordPayment(EnhancedSupplier supplier) {
    showDialog(
      context: context,
      builder: (context) => RecordPaymentDialog(
        supplier: supplier,
        onPaymentRecorded: () {
          _loadSuppliers(); // Refresh the list
        },
        database: ref.read(appDatabaseProvider),
      ),
    );
  }

  void _editSupplier(EnhancedSupplier supplier) {
    showDialog(
      context: context,
      builder: (context) => EditSupplierDialog(
        supplier: supplier,
        onSupplierUpdated: () {
          _loadSuppliers(); // Refresh the list
        },
        database: ref.read(appDatabaseProvider),
      ),
    );
  }

  void _deleteSupplier(EnhancedSupplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2D2D3D),
        title: Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف المورد "${supplier.businessName}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await _purchaseDao.deleteSupplier(supplier.id);
                _loadSuppliers();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('تم حذف المورد بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('خطأ في حذف المورد: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSupplierDialog(
        onSupplierAdded: () {
          _loadSuppliers(); // Refresh the list
        },
      ),
    );
  }
}

// Helper dialogs
class AddSupplierDialog extends ConsumerWidget {
  final VoidCallback onSupplierAdded;

  const AddSupplierDialog({super.key, required this.onSupplierAdded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AddSupplierDialogContent(
      onSupplierAdded: onSupplierAdded,
      ref: ref,
    );
  }
}

class _AddSupplierDialogContent extends StatefulWidget {
  final VoidCallback onSupplierAdded;
  final WidgetRef ref;

  const _AddSupplierDialogContent({
    required this.onSupplierAdded,
    required this.ref,
  });

  @override
  _AddSupplierDialogContentState createState() =>
      _AddSupplierDialogContentState();
}

class _AddSupplierDialogContentState extends State<_AddSupplierDialogContent> {
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
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الشركة*',
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
                    labelText: 'رقم الهاتف*',
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
              final database = widget.ref.read(appDatabaseProvider);
              final purchaseDao = EnhancedPurchaseDao(database);

              await purchaseDao.insertSupplier(
                EnhancedSuppliersCompanion.insert(
                  businessName: _businessNameController.text,
                  phone: _phoneController.text,
                  contactPerson: _contactPersonController.text.isEmpty
                      ? const Value.absent()
                      : Value(_contactPersonController.text),
                  address: _addressController.text.isEmpty
                      ? const Value.absent()
                      : Value(_addressController.text),
                  email: _emailController.text.isEmpty
                      ? const Value.absent()
                      : Value(_emailController.text),
                  taxNumber: _taxNumberController.text.isEmpty
                      ? const Value.absent()
                      : Value(_taxNumberController.text),
                  zipCode: _zipCodeController.text.isEmpty
                      ? '00000'
                      : _zipCodeController.text,
                  state: _stateController.text.isEmpty
                      ? 'غير محدد'
                      : _stateController.text,
                  notes: _notesController.text.isEmpty
                      ? const Value.absent()
                      : Value(_notesController.text),
                  currentBalance: Value(0.0),
                  isCreditAccount: Value(false),
                ),
              );

              widget.onSupplierAdded();
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

class RecordPaymentDialog extends StatefulWidget {
  final EnhancedSupplier supplier;
  final VoidCallback onPaymentRecorded;
  final AppDatabase database;

  const RecordPaymentDialog({
    super.key,
    required this.supplier,
    required this.onPaymentRecorded,
    required this.database,
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
                  child: Text('نقدي', style: TextStyle(color: Colors.white)),
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
              Navigator.pop(context);
              final database = widget.database;
              final purchaseDao = EnhancedPurchaseDao(database);
              final amount = double.parse(_amountController.text);

              // Record payment
              await purchaseDao.insertPayment(
                SupplierPaymentsCompanion.insert(
                  supplierId: widget.supplier.id,
                  paymentNumber: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                  paymentDate: DateTime.now(),
                  amount: amount,
                  paymentMethod: _paymentMethod,
                  referenceNumber: _referenceController.text.isEmpty
                      ? const Value.absent()
                      : Value(_referenceController.text),
                ),
              );

              // Update supplier balance
              final updatedSupplier = widget.supplier.copyWith(
                currentBalance: widget.supplier.currentBalance - amount,
                updatedAt: DateTime.now(),
              );
              await purchaseDao.updateSupplier(updatedSupplier);

              widget.onPaymentRecorded();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text('سداد'),
        ),
      ],
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

class EditSupplierDialog extends StatefulWidget {
  final EnhancedSupplier supplier;
  final VoidCallback onSupplierUpdated;
  final AppDatabase database;

  const EditSupplierDialog({
    super.key,
    required this.supplier,
    required this.onSupplierUpdated,
    required this.database,
  });

  @override
  State<EditSupplierDialog> createState() => _EditSupplierDialogState();
}

class _EditSupplierDialogState extends State<EditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _emailController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _stateController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.supplier.businessName,
    );
    _phoneController = TextEditingController(text: widget.supplier.phone);
    _addressController = TextEditingController(
      text: widget.supplier.address ?? '',
    );
    _contactPersonController = TextEditingController(
      text: widget.supplier.contactPerson ?? '',
    );
    _emailController = TextEditingController(text: widget.supplier.email ?? '');
    _taxNumberController = TextEditingController(
      text: widget.supplier.taxNumber ?? '',
    );
    _zipCodeController = TextEditingController(text: widget.supplier.zipCode);
    _stateController = TextEditingController(text: widget.supplier.state);
    _notesController = TextEditingController(text: widget.supplier.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF2D2D3D),
      title: Text('تعديل مورد', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الشركة*',
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
                    labelText: 'رقم الهاتف*',
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
              ],
            ),
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
              final database = widget.database;
              final purchaseDao = EnhancedPurchaseDao(database);

              final updatedSupplier = widget.supplier.copyWith(
                businessName: _businessNameController.text,
                phone: _phoneController.text,
                contactPerson: _contactPersonController.text.isEmpty
                    ? const Value.absent()
                    : Value(_contactPersonController.text),
                address: _addressController.text.isEmpty
                    ? const Value.absent()
                    : Value(_addressController.text),
                email: _emailController.text.isEmpty
                    ? const Value.absent()
                    : Value(_emailController.text),
                taxNumber: _taxNumberController.text.isEmpty
                    ? const Value.absent()
                    : Value(_taxNumberController.text),
                zipCode: _zipCodeController.text.isEmpty
                    ? '00000'
                    : _zipCodeController.text,
                state: _stateController.text.isEmpty
                    ? 'غير محدد'
                    : _stateController.text,
                notes: _notesController.text.isEmpty
                    ? const Value.absent()
                    : Value(_notesController.text),
                updatedAt: DateTime.now(),
              );

              await purchaseDao.updateSupplier(updatedSupplier);
              widget.onSupplierUpdated();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text('تحديث'),
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
