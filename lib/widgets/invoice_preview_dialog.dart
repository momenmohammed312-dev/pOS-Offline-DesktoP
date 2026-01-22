import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';
import 'package:pos_offline_desktop/core/services/pdf_invoice_service.dart';

/// Invoice Preview Dialog Widget
/// Shows PDF preview with print/share options
class InvoicePreviewDialog extends StatelessWidget {
  final Invoice invoice;
  final List<InvoiceItem> items;
  final String customerName;

  const InvoicePreviewDialog({
    super.key,
    required this.invoice,
    required this.items,
    this.customerName = 'عميل',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header with Close Button
            AppBar(
              title: Text(
                'عرض الفاتورة #${invoice.invoiceNumber ?? invoice.id}',
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Export PDF Button
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'تصدير PDF',
                  onPressed: () async {
                    try {
                      final pdfFile = await PdfInvoiceService.exportPdf(
                        invoice,
                        items,
                        customerName: customerName,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تصدير الفاتورة بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ في التصدير: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            // The PDF Viewer
            Expanded(
              child: PdfPreview(
                build: (format) => PdfInvoiceService.generateInvoicePdf(
                  invoice,
                  items,
                  customerName: customerName,
                ),
                allowPrinting: true,
                allowSharing: true,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName:
                    'invoice_${invoice.invoiceNumber ?? invoice.id}.pdf',
                dynamicLayout:
                    false, // Disable dynamic layout to ensure exact match
                // Custom actions
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (context, save, layout) async {
                      await save(layout);
                    },
                  ),
                ],
              ),
            ),
            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final pdfFile = await PdfInvoiceService.exportPdf(
                          invoice,
                          items,
                          customerName: customerName,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تصدير الفاتورة: ${pdfFile.path}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ في التصدير: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('تصدير PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Show loading indicator
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جاري تحميل الفاتورة للطباعة...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }

                        // Generate PDF with proper error handling
                        final pdfBytes =
                            await PdfInvoiceService.generateInvoicePdf(
                              invoice,
                              items,
                              customerName: customerName,
                            );

                        // Show print dialog
                        await Printing.layoutPdf(
                          onLayout: (_) => pdfBytes,
                          name:
                              'فاتورة #${invoice.invoiceNumber ?? invoice.id}',
                        );

                        // Show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم فتح نافذة الطباعة'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ في الطباعة: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('طباعة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
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

/// Helper function to show invoice preview
void showInvoicePreview(
  BuildContext context,
  Invoice invoice,
  List<InvoiceItem> items, {
  String customerName = 'عميل',
}) {
  showDialog(
    context: context,
    builder: (context) => InvoicePreviewDialog(
      invoice: invoice,
      items: items,
      customerName: customerName,
    ),
  );
}
