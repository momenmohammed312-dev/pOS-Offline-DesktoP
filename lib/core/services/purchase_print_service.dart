import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../database/dao/enhanced_purchase_dao.dart';
import 'unified_print_service.dart' as ups;
import 'dart:io';

/// Service for handling purchase-related printing operations
class PurchasePrintService {
  final EnhancedPurchaseDao _purchaseDao;

  PurchasePrintService(AppDatabase database)
      : _purchaseDao = EnhancedPurchaseDao(database);

  /// Print purchase report
  Future<void> printPurchaseReport(Map<String, dynamic> reportData) async {
    try {
      await ups.UnifiedPrintService.printToThermalPrinter(
        documentType: ups.DocumentType.purchaseReport,
        data: reportData,
      );
    } catch (e) {
      debugPrint('Error printing purchase report: $e');
      rethrow;
    }
  }

  /// Print supplier statement
  Future<void> printSupplierStatement(int supplierId) async {
    try {
      final supplier = await _purchaseDao.getSupplierById(supplierId);
      if (supplier == null) {
        throw Exception('Supplier not found');
      }

      // Get supplier transactions (purchases and payments)
      final purchases = await _purchaseDao.getPurchasesBySupplier(supplierId);
      
      // Prepare supplier data for printing
      final supplierData = {
        'supplierName': supplier.businessName,
        'supplierPhone': supplier.phone,
        'currentBalance': supplier.currentBalance,
        'transactions': purchases.map((p) => {
          'date': p.purchaseDate.toIso8601String(),
          'type': 'purchase',
          'description': 'فاتورة توريد #${p.purchaseNumber}',
          'amount': p.totalAmount,
          'balance': p.remainingAmount,
        }).toList(),
      };

      await ups.UnifiedPrintService.printToThermalPrinter(
        documentType: ups.DocumentType.supplierStatement,
        data: supplierData,
      );
      
    } catch (e) {
      debugPrint('Error printing supplier statement: $e');
      rethrow;
    }
  }

  /// Print purchase analytics
  Future<void> printPurchaseAnalytics(Map<String, dynamic> analyticsData) async {
    try {
      await ups.UnifiedPrintService.printToThermalPrinter(
        documentType: ups.DocumentType.purchaseReport,
        data: analyticsData,
      );
    } catch (e) {
      debugPrint('Error printing purchase analytics: $e');
      rethrow;
    }
  }

  /// Export purchase data to PDF
  Future<File> exportPurchaseToPdf(Map<String, dynamic> purchaseData) async {
    try {
      return await ups.UnifiedPrintService.exportToPDFFile(
        documentType: ups.DocumentType.purchaseInvoice,
        data: purchaseData,
        fileName: 'purchase_invoice_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('Error exporting purchase to PDF: $e');
      rethrow;
    }
  }

  /// Print purchase invoice
  Future<void> printPurchaseInvoice(int purchaseId) async {
    try {
      final purchase = await _purchaseDao.getPurchaseById(purchaseId);
      if (purchase == null) {
        throw Exception('Purchase invoice not found');
      }

      final items = await _purchaseDao.getItemsByPurchase(purchaseId);
      
      // Convert to InvoiceData format for UnifiedPrintService
      final invoiceData = ups.InvoiceData(
        invoice: ups.Invoice(
          id: purchase.id,
          invoiceNumber: purchase.purchaseNumber,
          customerName: purchase.supplierName, // For purchase, this is supplier name
          customerPhone: purchase.supplierPhone ?? '',
          customerZipCode: '',
          customerState: '',
          invoiceDate: purchase.purchaseDate,
          subtotal: purchase.subtotal,
          isCreditAccount: purchase.paymentMethod == 'credit',
          previousBalance: 0.0, // Would need to fetch from supplier ledger
          totalAmount: purchase.totalAmount,
          notes: purchase.notes,
        ),
        items: items.map((item) => ups.InvoiceItem(
          id: item.id,
          invoiceId: purchase.id,
          description: item.productName,
          unit: item.unit,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
        )).toList(),
      );
      
      await ups.UnifiedPrintService.printToThermalPrinter(
        documentType: ups.DocumentType.purchaseInvoice,
        data: invoiceData,
      );
      
    } catch (e) {
      debugPrint('Error printing purchase invoice: $e');
      rethrow;
    }
  }
}
