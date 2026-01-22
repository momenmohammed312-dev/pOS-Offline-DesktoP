import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/printer_service.dart';
import 'package:pos_offline_desktop/core/services/export_service.dart';

/// صفحة تفاصيل الفاتورة البسيطة - Simple Invoice Details Page
class InvoiceDetailsPage extends StatefulWidget {
  final Invoice invoice;
  final AppDatabase db;
  final Customer? customer;

  const InvoiceDetailsPage({
    super.key,
    required this.invoice,
    required this.db,
    this.customer,
  });

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  List<(InvoiceItem, Product?)> _itemsWithProducts = [];

  @override
  void initState() {
    super.initState();
    _loadInvoiceItems();
  }

  Future<void> _loadInvoiceItems() async {
    try {
      final itemsWithProducts = await widget.db.invoiceDao
          .getItemsWithProductsByInvoice(widget.invoice.id);
      setState(() {
        _itemsWithProducts = itemsWithProducts;
      });
    } catch (e) {
      // Handle error silently or show a message if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.invoice.totalAmount - widget.invoice.paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الفاتورة #${widget.invoice.id}'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            tooltip: 'طباعة الفاتورة',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الفاتورة الرئيسية - Main Invoice Info
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رأس الفاتورة - Invoice Header
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 40,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فاتورة: ${widget.invoice.id}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                            ),
                            Text(
                              widget.invoice.invoiceNumber ?? 'N/A',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // معلومات العميل - Customer Info
                    if (widget.customer != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'العميل: ${widget.customer!.name}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  widget.customer!.phone ?? 'لا يوجد',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                if (widget.customer!.address?.isNotEmpty ==
                                    true)
                                  Text(
                                    widget.customer!.address!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // معلومات الدفع - Payment Info
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'المبلغ الإجمالي',
                            '${widget.invoice.totalAmount.toStringAsFixed(2)} ج.م',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'المدفوع',
                            '${widget.invoice.paidAmount.toStringAsFixed(2)} ج.م',
                            Icons.payment,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'المتبقي',
                            '${remaining.toStringAsFixed(2)} ج.م',
                            remaining > 0
                                ? Icons.money_off
                                : Icons.check_circle,
                            remaining > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // معلومات إضافية - Additional Info
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'طريقة الدفع',
                            _getPaymentMethodText(widget.invoice.paymentMethod),
                            _getPaymentMethodIcon(widget.invoice.paymentMethod),
                            _getPaymentMethodColor(
                              widget.invoice.paymentMethod,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'الحالة',
                            _getStatusText(widget.invoice.status),
                            _getStatusIcon(widget.invoice.status),
                            _getStatusColor(widget.invoice.status),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'التاريخ',
                            DateFormat(
                              'yyyy/MM/dd HH:mm',
                            ).format(widget.invoice.date),
                            Icons.calendar_today,
                            Colors.grey.shade600,
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        label: const Text('رجوع'),
        backgroundColor: Colors.blue.shade900,
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText(String? method) {
    switch (method) {
      case 'cash':
        return 'كاش';
      case 'credit':
        return 'آجل';
      case 'visa':
        return 'فيزا';
      case 'bank':
        return 'تحويل بنكي';
      default:
        return method ?? 'غير محدد';
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'credit':
        return Icons.account_balance;
      case 'visa':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance_wallet;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPaymentMethodColor(String? method) {
    switch (method) {
      case 'cash':
        return Colors.green;
      case 'credit':
        return Colors.orange;
      case 'visa':
        return Colors.blue;
      case 'bank':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'معلقة';
      case 'paid':
        return 'مدفوعة';
      case 'partial':
        return 'مدفوعة جزئياً';
      default:
        return status ?? 'غير محدد';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'paid':
        return Icons.check_circle;
      case 'partial':
        return Icons.pending_actions;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _printInvoice() async {
    try {
      if (widget.customer != null) {
        await PrinterService.printCustomerStatement(
          customerId: widget.customer!.id,
          customerName: widget.customer!.name,
          startDate: widget.invoice.date,
          endDate: widget.invoice.date,
          invoices: [widget.invoice],
          ledgerDao: widget.db.ledgerDao,
        );
      } else {
        // Use autoPrintInvoice to honor thermal/A4 preference
        // Convert invoice items to maps for printing with proper product names
        final itemsMaps = _itemsWithProducts.map((itemWithProduct) {
          final item = itemWithProduct.$1;
          final product = itemWithProduct.$2;
          return {
            'productName': product?.name ?? 'Product ${item.productId}',
            'name': product?.name ?? 'Product ${item.productId}',
            'quantity': item.quantity,
            'price': item.price,
            'total': item.quantity * item.price,
          };
        }).toList();

        await PrinterService.autoPrintInvoice(
          invoice: {
            'id': widget.invoice.id,
            'customerName': widget.invoice.customerName,
            'date': widget.invoice.date,
            'totalAmount': widget.invoice.totalAmount,
            'paymentMethod': widget.invoice.paymentMethod,
          },
          items: itemsMaps,
          paymentMethod: widget.invoice.paymentMethod ?? 'cash',
          ledgerDao: widget.db.ledgerDao,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الفاتورة للطباعة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final exportService = ExportService();

      // بيانات الفاتورة - Invoice Data
      final invoiceData = {
        'رقم الفاتورة': widget.invoice.id.toString(),
        'العميل': widget.invoice.customerName,
        'التاريخ': DateFormat('yyyy/MM/dd HH:mm').format(widget.invoice.date),
        'الإجمالي': widget.invoice.totalAmount.toStringAsFixed(2),
        'المدفوع': widget.invoice.paidAmount.toStringAsFixed(2),
        'المتبقي': (widget.invoice.totalAmount - widget.invoice.paidAmount)
            .toStringAsFixed(2),
        'طريقة الدفع': _getPaymentMethodText(widget.invoice.paymentMethod),
        'الحالة': _getStatusText(widget.invoice.status),
      };

      await exportService.exportToPDF(
        title: 'تفاصيل الفاتورة #${widget.invoice.id}',
        data: [invoiceData],
        headers: [
          'رقم الفاتورة',
          'العميل',
          'التاريخ',
          'الإجمالي',
          'المدفوع',
          'المتبقي',
          'طريقة الدفع',
          'الحالة',
        ],
        columns: [
          'رقم الفاتورة',
          'العميل',
          'التاريخ',
          'الإجمالي',
          'المدفوع',
          'المتبقي',
          'طريقة الدفع',
          'الحالة',
        ],
        fileName:
            'invoice_details_${widget.invoice.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير الفاتورة كـ PDF'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التصدير: $e')));
      }
    }
  }
}
