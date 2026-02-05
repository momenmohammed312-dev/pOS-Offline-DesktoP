import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../database/dao/enhanced_purchase_dao.dart';

/// Service for handling purchase operations with automatic inventory updates
/// خدمة معالجة المشتريات مع التحديث التلقائي للمخزون
class PurchaseService {
  final AppDatabase _db;
  late final EnhancedPurchaseDao _purchaseDao;

  PurchaseService(this._db) {
    _purchaseDao = EnhancedPurchaseDao(_db);
  }

  /// Create a complete purchase with automatic inventory update
  /// إنشاء فاتورة شراء كاملة مع تحديث تلقائي للمخزون
  Future<int> createPurchase({
    required int supplierId,
    required String supplierName,
    required String supplierPhone,
    required List<PurchaseItemData> items,
    required bool isCreditPurchase,
    required double paidAmount,
    String? notes,
  }) async {
    try {
      // Calculate totals
      double subtotal = 0;
      for (final item in items) {
        subtotal += (item.unitPrice * item.quantity);
      }

      final totalAmount = subtotal; // Can add tax/discount later
      final remainingAmount = totalAmount - paidAmount;

      // Get current supplier balance
      final supplier = await _purchaseDao.getSupplierById(supplierId);
      final previousBalance = supplier?.currentBalance ?? 0.0;

      final purchaseNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch}';

      // Convert items to EnhancedPurchaseItemsCompanion
      final enhancedItems = items
          .map(
            (item) => EnhancedPurchaseItemsCompanion.insert(
              purchaseId: 0, // Will be replaced in createCompletePurchase
              productId: item.productId,
              productName: item.productName,
              productBarcode: Value(item.productBarcode),
              unit: item.unit,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.unitPrice * item.quantity,
              sortOrder: Value(0),
            ),
          )
          .toList();

      // Create complete purchase with inventory update
      final purchaseId = await _purchaseDao.createCompletePurchase(
        purchaseNumber: purchaseNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        supplierPhone: supplierPhone,
        purchaseDate: DateTime.now(),
        subtotal: subtotal,
        totalAmount: totalAmount,
        isCreditPurchase: isCreditPurchase,
        previousBalance: previousBalance,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        paymentMethod: isCreditPurchase ? 'credit' : 'cash',
        notes: notes,
        items: enhancedItems,
      );

      debugPrint(
        'Purchase created successfully: $purchaseNumber (ID: $purchaseId)',
      );
      return purchaseId;
    } catch (e) {
      debugPrint('Error creating purchase: $e');
      rethrow;
    }
  }

  /// Get purchase by ID
  Future<EnhancedPurchase?> getPurchaseById(int purchaseId) async {
    return await _purchaseDao.getPurchaseById(purchaseId);
  }

  /// Get all purchases
  Future<List<EnhancedPurchase>> getAllPurchases() async {
    return await _purchaseDao.getAllPurchases();
  }

  /// Get purchases by supplier
  Future<List<EnhancedPurchase>> getPurchasesBySupplier(int supplierId) async {
    return await _purchaseDao.getPurchasesBySupplier(supplierId);
  }

  /// Get purchase items
  Future<List<EnhancedPurchaseItem>> getPurchaseItems(int purchaseId) async {
    return await _purchaseDao.getItemsByPurchase(purchaseId);
  }
}

/// Data class for purchase item
/// فئة بيانات لعنصر المشتريات
class PurchaseItemData {
  final int productId;
  final String productName;
  final String? productBarcode;
  final String unit;
  final int quantity;
  final double unitPrice;

  PurchaseItemData({
    required this.productId,
    required this.productName,
    this.productBarcode,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => unitPrice * quantity;
}
