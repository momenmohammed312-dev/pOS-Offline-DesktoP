import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/widgets/universal_invoice_layout.dart';
import 'package:pos_offline_desktop/core/services/invoice_print_export_service.dart';

/// Universal Invoice Test Application
/// Tests all export methods to ensure identical formatting
void main() {
  runApp(
    const MaterialApp(
      title: 'Universal Invoice Test',
      home: InvoiceTestPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class InvoiceTestPage extends StatelessWidget {
  const InvoiceTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Create sample data that matches reference image exactly
    final sampleInvoiceData = InvoiceData(
      invoice: Invoice(
        id: 2453,
        invoiceNumber: '0002453',
        invoiceType: 'quote', // This shows "عرض أسعار"
        customerName: 'إسم العميل التجاري',
        customerPhone: '01234567890',
        customerZipCode: '12345',
        customerState: 'المدينة',
        projectName: null,
        invoiceDate: DateTime(2026, 1, 22),
        saleDate: DateTime(2026, 1, 22),
        subtotal: 325.0,
        isCreditAccount: false,
        previousBalance: 0.0,
        totalAmount: 325.0,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      items: [
        InvoiceItem(
          id: 1,
          invoiceId: 2453,
          description: 'إسم المنتج التجاري 1',
          quantity: 3,
          unitPrice: 50.0,
          totalPrice: 150.0,
          sortOrder: 0,
        ),
        InvoiceItem(
          id: 2,
          invoiceId: 2453,
          description: 'إسم المنتج التجاري',
          quantity: 7,
          unitPrice: 25.0,
          totalPrice: 175.0,
          sortOrder: 1,
        ),
      ],
      storeInfo: StoreInfo(
        storeName: 'إسم المحل التجاري',
        phone: '01234567890',
        zipCode: '12345',
        state: 'المدينة',
        taxNumber: null,
        logoPath: null,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Invoice Test'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Print to PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: () async {
              await _testPrintToPDF(context, sampleInvoiceData);
            },
            tooltip: 'Print to PDF',
          ),
          // Export to PDF file
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              await _testExportToPDF(context, sampleInvoiceData);
            },
            tooltip: 'Export PDF',
          ),
          // Print to physical printer
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () async {
              await _testPrintToPhysicalPrinter(context, sampleInvoiceData);
            },
            tooltip: 'Print to Printer',
          ),
          // Export to Image
          IconButton(
            icon: const Icon(Icons.image, color: Colors.white),
            onPressed: () async {
              await _testExportToImage(context, sampleInvoiceData);
            },
            tooltip: 'Export as Image',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Invoice Preview
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: UniversalInvoiceLayout(invoiceData: sampleInvoiceData),
                ),
              ),
              const SizedBox(height: 20),

              // Test Results
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧪 Export Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'All export methods should produce IDENTICAL formatting:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      _buildTestResult('✅ PDF Preview', 'Opens print dialog'),
                      _buildTestResult('✅ PDF Export', 'Saves PDF file'),
                      _buildTestResult('✅ Physical Print', 'Sends to printer'),
                      _buildTestResult('✅ Image Export', 'Creates PNG image'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestResult(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testPrintToPDF(
    BuildContext context,
    InvoiceData invoiceData,
  ) async {
    try {
      await InvoicePrintExportService.printToPDF(invoiceData);
      _showSuccessMessage(context, 'PDF preview opened successfully');
    } catch (e) {
      _showErrorMessage(context, 'PDF preview failed: $e');
    }
  }

  Future<void> _testExportToPDF(
    BuildContext context,
    InvoiceData invoiceData,
  ) async {
    try {
      final file = await InvoicePrintExportService.exportToPDFFile(invoiceData);
      _showSuccessMessage(context, 'PDF exported: ${file.path}');
    } catch (e) {
      _showErrorMessage(context, 'PDF export failed: $e');
    }
  }

  Future<void> _testPrintToPhysicalPrinter(
    BuildContext context,
    InvoiceData invoiceData,
  ) async {
    try {
      await InvoicePrintExportService.printToPhysicalPrinter(invoiceData);
      _showSuccessMessage(context, 'Sent to printer successfully');
    } catch (e) {
      _showErrorMessage(context, 'Print failed: $e');
    }
  }

  Future<void> _testExportToImage(
    BuildContext context,
    InvoiceData invoiceData,
  ) async {
    try {
      final file = await InvoicePrintExportService.exportToImage(
        context,
        invoiceData,
      );
      _showSuccessMessage(context, 'Image exported: ${file.path}');
    } catch (e) {
      _showErrorMessage(context, 'Image export failed: $e');
    }
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
