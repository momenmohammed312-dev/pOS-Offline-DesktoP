import 'package:flutter/material.dart';
import '../services/export_service_simple.dart';

class ResultsTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String reportType;

  const ResultsTable({super.key, required this.data, required this.reportType});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'نتائج البحث (${data.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (data.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _exportToCSV(context),
                    tooltip: 'تصدير CSV',
                  ),
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () => _printTable(context),
                    tooltip: 'طباعة',
                  ),
                ],
              ],
            ),
          ),

          // Table content
          data.isEmpty ? _buildEmptyState(context) : _buildDataTable(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات لعرضها',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير الفلاتر أو اختيار تقرير آخر',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: _getTableHeaders().map((header) {
              return Expanded(
                flex: _getColumnFlex(header),
                child: Text(
                  header,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: _getTextAlign(header),
                ),
              );
            }).toList(),
          ),
        ),

        // Table rows
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildTableRow(context, item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final isEven = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.transparent
            : Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: _getTableHeaders().map((header) {
          return Expanded(
            flex: _getColumnFlex(header),
            child: _buildCellContent(context, header, item),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCellContent(
    BuildContext context,
    String header,
    Map<String, dynamic> item,
  ) {
    final value = item[_getCellValueKey(header)];
    final displayValue = _formatCellValue(header, value);

    return Text(
      displayValue,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: _isNumericColumn(header)
            ? FontWeight.w500
            : FontWeight.normal,
        color: _getValueColor(context, header, value),
      ),
      textAlign: _getTextAlign(header),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  List<String> _getTableHeaders() {
    switch (reportType) {
      case 'sales':
        return [
          'رقم الفاتورة',
          'العميل',
          'التاريخ',
          'الإجمالي',
          'المدفوع',
          'الحالة',
        ];
      case 'customers':
        return ['اسم العميل', 'رقم الاتصال', 'الرصيد', 'عدد الفواتير'];
      case 'suppliers':
        return ['اسم المورد', 'رقم الاتصال', 'الرصيد', 'عدد المشتريات'];
      case 'products':
        return ['اسم المنتج', 'التصنيف', 'الكمية', 'السعر', 'المباع'];
      case 'financial':
        return ['التاريخ', 'النوع', 'الوصف', 'المبلغ'];
      default:
        return ['البيان'];
    }
  }

  String _getCellValueKey(String header) {
    switch (header) {
      case 'رقم الفاتورة':
        return 'invoiceNumber';
      case 'العميل':
      case 'اسم العميل':
      case 'اسم المورد':
      case 'اسم المنتج':
        return 'name' == 'name'
            ? 'name'
            : header.contains('عميل')
            ? 'customerName'
            : header.contains('مورد')
            ? 'name'
            : header.contains('منتج')
            ? 'name'
            : 'name';
      case 'التاريخ':
        return 'date';
      case 'الإجمالي':
      case 'المدفوع':
      case 'الرصيد':
      case 'السعر':
      case 'المبلغ':
        return header == 'الإجمالي'
            ? 'totalAmount'
            : header == 'المدفوع'
            ? 'paidAmount'
            : header == 'الرصيد'
            ? 'balance'
            : header == 'السعر'
            ? 'price'
            : 'amount';
      case 'الحالة':
        return 'status';
      case 'رقم الاتصال':
        return 'contact';
      case 'عدد الفواتير':
        return 'totalInvoices';
      case 'عدد المشتريات':
        return 'totalPurchases';
      case 'التصنيف':
        return 'category';
      case 'الكمية':
        return 'quantity';
      case 'المباع':
        return 'totalSold';
      case 'النوع':
        return 'type';
      case 'الوصف':
        return 'description';
      default:
        return 'name';
    }
  }

  int _getColumnFlex(String header) {
    switch (header) {
      case 'رقم الفاتورة':
      case 'التاريخ':
      case 'الحالة':
      case 'النوع':
        return 1;
      case 'الكمية':
      case 'السعر':
      case 'المبلغ':
      case 'المدفوع':
      case 'المباع':
        return 1;
      case 'العميل':
      case 'اسم العميل':
      case 'اسم المورد':
      case 'اسم المنتج':
      case 'رقم الاتصال':
      case 'عدد الفواتير':
      case 'عدد المشتريات':
        return 2;
      case 'التصنيف':
      case 'الوصف':
        return 2;
      case 'الرصيد':
      case 'الإجمالي':
        return 1;
      default:
        return 1;
    }
  }

  TextAlign _getTextAlign(String header) {
    return _isNumericColumn(header) ? TextAlign.center : TextAlign.start;
  }

  bool _isNumericColumn(String header) {
    return [
      'الإجمالي',
      'المدفوع',
      'الرصيد',
      'السعر',
      'المبلغ',
      'الكمية',
      'المباع',
      'عدد الفواتير',
      'عدد المشتريات',
    ].contains(header);
  }

  String _formatCellValue(String header, dynamic value) {
    if (value == null) return '-';

    if (_isNumericColumn(header)) {
      if (header == 'التاريخ') {
        return value.toString();
      }
      return value is double ? value.toStringAsFixed(2) : value.toString();
    }

    return value.toString();
  }

  Color _getValueColor(BuildContext context, String header, dynamic value) {
    if (value == null) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }

    if (header == 'الحالة') {
      switch (value.toString()) {
        case 'مدفوع':
          return Colors.green;
        case 'جزئي':
          return Colors.orange;
        case 'غير مدفوع':
          return Colors.red;
        default:
          return Theme.of(context).colorScheme.onSurface;
      }
    }

    if (header == 'النوع') {
      if (value.toString() == 'دخل') {
        return Colors.green;
      } else {
        return Colors.red;
      }
    }

    if (_isNumericColumn(header) && value is double) {
      if (header == 'الرصيد') {
        return value >= 0 ? Colors.red : Colors.green;
      }
      return Theme.of(context).colorScheme.onSurface;
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  void _exportToCSV(BuildContext context) async {
    try {
      await ExportService.exportToCSV(
        data: data,
        reportType: reportType,
        fileName: 'تقرير_$reportType',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير البيانات بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في التصدير: $e')));
      }
    }
  }

  void _printTable(BuildContext context) async {
    try {
      await ExportService.exportToCSV(
        data: data,
        reportType: reportType,
        fileName: 'تقرير_$reportType',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('جاري إعداد الطباعة...')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في الطباعة: $e')));
      }
    }
  }
}
