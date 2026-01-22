import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/reports_provider.dart';

class FilterPanel extends ConsumerStatefulWidget {
  final String reportType;
  final Function(ReportFilter) onFilterChanged;

  const FilterPanel({
    super.key,
    required this.reportType,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  final _debouncer = Debouncer(milliseconds: 500);

  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedCustomer;
  String? _selectedSupplier;
  String? _selectedProduct;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  final List<Map<String, String>> _customers = [
    {'id': '1', 'name': 'أحمد محمد'},
    {'id': '2', 'name': 'فاطمة علي'},
    {'id': '3', 'name': 'محمد أحمد'},
  ];

  final List<Map<String, String>> _suppliers = [
    {'id': '1', 'name': 'شركة النور'},
    {'id': '2', 'name': 'شركة الأمل'},
  ];

  final List<Map<String, String>> _products = [
    {'id': '1', 'name': 'منتج أ'},
    {'id': '2', 'name': 'منتج ب'},
    {'id': '3', 'name': 'منتج ج'},
  ];

  final List<Map<String, String>> _statusOptions = [
    {'id': 'مدفوع', 'name': 'مدفوع'},
    {'id': 'جزئي', 'name': 'جزئي'},
    {'id': 'غير مدفوع', 'name': 'غير مدفوع'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeDefaultFilters();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeDefaultFilters() {
    final now = DateTime.now();
    _toDate = now;
    _fromDate = DateTime(now.year, now.month, 1); // First day of current month
    _applyFilters();
  }

  void _applyFilters() {
    final filter = ReportFilter(
      fromDate: _fromDate,
      toDate: _toDate,
      customerId: _selectedCustomer,
      supplierId: _selectedSupplier,
      productId: _selectedProduct,
      status: _selectedStatus,
      additionalFilters: {'search': _searchController.text.trim()},
    );

    widget.onFilterChanged(filter);
  }

  void _onFilterChanged() {
    _debouncer.run(() {
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'فلاتر البحث',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة تعيين'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date range filters
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    label: 'من تاريخ',
                    date: _fromDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    label: 'إلى تاريخ',
                    date: _toDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dynamic filters based on report type
            _buildDynamicFilters(),

            const SizedBox(height: 16),

            // Search field
            TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'بحث...',
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث عن...',
              ),
              onChanged: (value) => _onFilterChanged(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'اختر التاريخ',
          style: TextStyle(
            color: date != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicFilters() {
    switch (widget.reportType) {
      case 'sales':
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'العميل',
                    value: _selectedCustomer,
                    items: _customers,
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                      });
                      _onFilterChanged();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'الحالة',
                    value: _selectedStatus,
                    items: _statusOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _onFilterChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        );

      case 'customers':
        return _buildDropdown(
          label: 'العميل',
          value: _selectedCustomer,
          items: _customers,
          onChanged: (value) {
            setState(() {
              _selectedCustomer = value;
            });
            _onFilterChanged();
          },
        );

      case 'suppliers':
        return _buildDropdown(
          label: 'المورد',
          value: _selectedSupplier,
          items: _suppliers,
          onChanged: (value) {
            setState(() {
              _selectedSupplier = value;
            });
            _onFilterChanged();
          },
        );

      case 'products':
        return _buildDropdown(
          label: 'المنتج',
          value: _selectedProduct,
          items: _products,
          onChanged: (value) {
            setState(() {
              _selectedProduct = value;
            });
            _onFilterChanged();
          },
        );

      case 'financial':
        return _buildDropdown(
          label: 'النوع',
          value: _selectedStatus,
          items: [
            {'id': 'دخل', 'name': 'دخل'},
            {'id': 'مصروف', 'name': 'مصروف'},
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
            _onFilterChanged();
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'],
          child: Text(item['name'] ?? 'Unknown'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? _fromDate ?? DateTime.now()
          : _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _onFilterChanged();
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCustomer = null;
      _selectedSupplier = null;
      _selectedProduct = null;
      _selectedStatus = null;
      _searchController.clear();
      _initializeDefaultFilters();
    });
  }
}

// Debouncer utility class
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
