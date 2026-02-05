import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart';
import '../../core/provider/app_database_provider.dart';
import '../../ui/supplier/widgets/supplier_form_dialog.dart';
import 'package:pos_offline_desktop/ui/supplier/widgets/supplier_payment_dialog.dart';
import 'package:pos_offline_desktop/ui/supplier/widgets/supplier_statement_dialog.dart';
import 'package:pos_offline_desktop/ui/supplier/widgets/supplier_details_dialog.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل'; // الكل، نشط، غير نشط
  String _selectedBalanceFilter = 'الكل'; // الكل، له رصيد، عليه رصيد، متوازن

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final suppliers = await db.supplierDao.getAllSuppliers();

      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات الموردين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        // Apply search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            supplier.name.toLowerCase().contains(searchQuery) ||
            (supplier.phone?.toLowerCase().contains(searchQuery) ?? false) ||
            supplier.id.toLowerCase().contains(searchQuery);

        // Apply status filter
        final matchesStatus =
            _selectedFilter == 'الكل' ||
            (_selectedFilter == 'نشط' && supplier.status == 'Active') ||
            (_selectedFilter == 'غير نشط' && supplier.status == 'Inactive');

        return matchesSearch && matchesStatus;
      }).toList();

      // Apply balance filter
      if (_selectedBalanceFilter != 'الكل') {
        _filteredSuppliers = _filteredSuppliers.where((supplier) {
          // This would need to be implemented to get actual balance
          // For now, we'll use opening balance as a placeholder
          final balance = supplier.openingBalance;

          switch (_selectedBalanceFilter) {
            case 'له رصيد':
              return balance > 0;
            case 'عليه رصيد':
              return balance < 0;
            case 'متوازن':
              return balance == 0;
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  Future<void> _showAddSupplierDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          SupplierFormDialog(database: ref.read(appDatabaseProvider)),
    );

    if (result == true) {
      _loadSuppliers();
    }
  }

  Future<void> _showEditSupplierDialog(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SupplierFormDialog(
        database: ref.read(appDatabaseProvider),
        supplier: supplier,
      ),
    );

    if (result == true) {
      _loadSuppliers();
    }
  }

  Future<void> _showPaymentDialog(Supplier supplier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SupplierPaymentDialog(
        database: ref.read(appDatabaseProvider),
        supplier: supplier,
      ),
    );

    if (result == true) {
      _loadSuppliers();
    }
  }

  Future<void> _showStatementDialog(Supplier supplier) async {
    await showDialog(
      context: context,
      builder: (context) => SupplierStatementDialog(
        database: ref.read(appDatabaseProvider),
        supplier: supplier,
      ),
    );
  }

  Future<void> _showDetailsDialog(Supplier supplier) async {
    await showDialog(
      context: context,
      builder: (context) => SupplierDetailsDialog(
        database: ref.read(appDatabaseProvider),
        supplier: supplier,
      ),
    );
  }

  Future<void> _toggleSupplierStatus(Supplier supplier) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final newStatus = supplier.status == 'Active' ? 'Inactive' : 'Active';

      await db.supplierDao.updateSupplier(
        SuppliersCompanion(
          id: drift.Value(supplier.id),
          status: drift.Value(newStatus),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Active'
                  ? 'تم تفعيل المورد'
                  : 'تم إلغاء تفعيل المورد',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadSuppliers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث حالة المورد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المورد "${supplier.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = ref.read(appDatabaseProvider);
        await db.supplierDao.deleteSupplier(supplier.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المورد بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }

        _loadSuppliers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف المورد: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadSuppliers,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'البحث عن مورد...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'الحالة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                          DropdownMenuItem(value: 'نشط', child: Text('نشط')),
                          DropdownMenuItem(
                            value: 'غير نشط',
                            child: Text('غير نشط'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBalanceFilter,
                        decoration: const InputDecoration(
                          labelText: 'الرصيد',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                          DropdownMenuItem(
                            value: 'له رصيد',
                            child: Text('له رصيد'),
                          ),
                          DropdownMenuItem(
                            value: 'عليه رصيد',
                            child: Text('عليه رصيد'),
                          ),
                          DropdownMenuItem(
                            value: 'متوازن',
                            child: Text('متوازن'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBalanceFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddSupplierDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مورد جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                // Add export and print buttons here if needed
              ],
            ),
          ),

          // Suppliers Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSuppliers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا يوجد موردين',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('كود المورد')),
                        DataColumn(label: Text('اسم المورد')),
                        DataColumn(label: Text('رقم الهاتف')),
                        DataColumn(label: Text('العنوان')),
                        DataColumn(label: Text('الرصيد')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('الإجراءات')),
                      ],
                      rows: _filteredSuppliers.map((supplier) {
                        return DataRow(
                          cells: [
                            DataCell(Text(supplier.id)),
                            DataCell(
                              Text(
                                supplier.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(supplier.phone ?? '-')),
                            DataCell(Text(supplier.address ?? '-')),
                            DataCell(
                              Text(
                                '${supplier.openingBalance.toStringAsFixed(2)} ج.م',
                                style: TextStyle(
                                  color: supplier.openingBalance > 0
                                      ? Colors.red
                                      : supplier.openingBalance < 0
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: supplier.status == 'Active'
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: supplier.status == 'Active'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                child: Text(
                                  supplier.status == 'Active'
                                      ? 'نشط'
                                      : 'غير نشط',
                                  style: TextStyle(
                                    color: supplier.status == 'Active'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // View Details
                                  IconButton(
                                    onPressed: () =>
                                        _showDetailsDialog(supplier),
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'عرض التفاصيل',
                                    color: Colors.blue,
                                  ),
                                  // Edit
                                  IconButton(
                                    onPressed: () =>
                                        _showEditSupplierDialog(supplier),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'تعديل',
                                    color: Colors.orange,
                                  ),
                                  // Payment
                                  IconButton(
                                    onPressed: () =>
                                        _showPaymentDialog(supplier),
                                    icon: const Icon(Icons.payment),
                                    tooltip: 'سداد قيمة',
                                    color: Colors.green,
                                  ),
                                  // Statement
                                  IconButton(
                                    onPressed: () =>
                                        _showStatementDialog(supplier),
                                    icon: const Icon(Icons.receipt_long),
                                    tooltip: 'كشف الحساب',
                                    color: Colors.purple,
                                  ),
                                  // Toggle Status
                                  IconButton(
                                    onPressed: () =>
                                        _toggleSupplierStatus(supplier),
                                    icon: Icon(
                                      supplier.status == 'Active'
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                    ),
                                    tooltip: supplier.status == 'Active'
                                        ? 'إلغاء التفعيل'
                                        : 'تفعيل',
                                    color: supplier.status == 'Active'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  // Delete
                                  IconButton(
                                    onPressed: () => _deleteSupplier(supplier),
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'حذف',
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
