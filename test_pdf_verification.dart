import 'package:flutter/material.dart';
import 'package:pos_offline_desktop/core/services/arabic_pdf_test.dart';
import 'package:pos_offline_desktop/core/services/export_service.dart';

void main() {
  runApp(const PDFVerificationApp());
}

class PDFVerificationApp extends StatelessWidget {
  const PDFVerificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Verification',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PDFVerificationScreen(),
    );
  }
}

class PDFVerificationScreen extends StatelessWidget {
  const PDFVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Verification Tests'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PDF Functionality Verification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'اختبار وظائف PDF',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Test Arabic PDF
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.text_fields,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Arabic PDF Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('اختبار الخط العربي في PDF'),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ArabicPdfTest.testArabicPdf();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Test Arabic PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Export Service PDF
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.table_chart, size: 48, color: Colors.blue),
                    const SizedBox(height: 10),
                    const Text(
                      'Export Service PDF Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('اختبار خدمة التصدير PDF'),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final exportService = ExportService();
                          await exportService.exportToPDF(
                            title: 'تقرير اختبار',
                            data: [
                              {
                                'id': '1',
                                'name': 'منتج اختبار',
                                'price': 100.50,
                                'date': '2024/01/10',
                              },
                              {
                                'id': '2',
                                'name': 'منتج آخر',
                                'price': 250.75,
                                'date': '2024/01/11',
                              },
                            ],
                            headers: ['الرقم', 'الاسم', 'السعر', 'التاريخ'],
                            columns: ['id', 'name', 'price', 'date'],
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('Test Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Enhanced Statement Generator
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enhanced Statement Generator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('مولد الكشفات الحسابية المحسن'),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Test basic PDF generation with export service
                          final exportService = ExportService();
                          await exportService.exportToPDF(
                            title: 'تقرير اختبار',
                            data: [
                              {
                                'id': '1',
                                'name': 'منتج اختبار',
                                'price': 100.50,
                                'date': '2024/01/10',
                              },
                              {
                                'id': '2',
                                'name': 'منتج آخر',
                                'price': 250.75,
                                'date': '2024/01/11',
                              },
                            ],
                            headers: ['الرقم', 'الاسم', 'السعر', 'التاريخ'],
                            columns: ['id', 'name', 'price', 'date'],
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.account_balance),
                      label: const Text('Test Statement Generator'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
