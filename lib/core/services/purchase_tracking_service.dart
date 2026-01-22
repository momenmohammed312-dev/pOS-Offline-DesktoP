import 'dart:developer';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/dao/purchase_dao.dart';

class PurchaseTrackingService {
  final AppDatabase db;
  final PurchaseDao purchaseDao;

  PurchaseTrackingService(this.db) : purchaseDao = PurchaseDao(db);

  /// Record a purchase that updates product quantities
  Future<String> recordPurchase({
    String? supplierId,
    required String description,
    required List<PurchaseItemData> items,
    String paymentMethod = 'cash',
    double paidAmount = 0.0,
    String? notes,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.unitPrice * item.quantity),
      );

      // Generate purchase invoice number
      final invoiceNumber = 'PUR${DateTime.now().millisecondsSinceEpoch}';

      // Convert items to map format
      final itemsMap = items
          .map(
            (item) => {
              'productId': item.productId,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'unit': item.unit,
              'cartonQuantity': item.cartonQuantity,
              'cartonPrice': item.cartonPrice,
              'discount': item.discount,
              'tax': item.tax,
            },
          )
          .toList();

      // Insert purchase with items
      final purchaseId = await purchaseDao.insertPurchaseWithItems(
        supplierId: supplierId,
        invoiceNumber: invoiceNumber,
        description: description,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        paymentMethod: paymentMethod,
        status: 'completed',
        purchaseDate: DateTime.now(),
        notes: notes,
        items: itemsMap,
      );

      log('Purchase recorded successfully: $purchaseId');
      return purchaseId;
    } catch (e) {
      log('Error recording purchase: $e');
      rethrow;
    }
  }

  /// Update original invoice quantities when a purchase is made
  Future<void> updateInvoiceQuantitiesFromPurchase(String purchaseId) async {
    try {
      final purchaseItems = await purchaseDao.getPurchaseItems(purchaseId);

      for (final purchaseItem in purchaseItems) {
        // Get the product to update its stock
        final product =
            await (db.select(
                  db.products,
                )..where((p) => p.id.equals(int.parse(purchaseItem.productId))))
                .getSingleOrNull();

        if (product != null) {
          // Update product quantity with new stock from purchase
          await db.productDao.updateProduct(
            ProductsCompanion(
              id: Value(product.id),
              name: Value(product.name),
              quantity: Value(purchaseItem.newStock ?? product.quantity),
              price: Value(product.price),
              unit: Value(product.unit),
              category: Value(product.category),
              barcode: Value(product.barcode),
              cartonQuantity: Value(product.cartonQuantity),
              cartonPrice: Value(product.cartonPrice),
              status: Value(product.status),
            ),
          );

          log(
            'Updated product ${product.name} quantity to ${purchaseItem.newStock}',
          );
        }
      }
    } catch (e) {
      log('Error updating invoice quantities from purchase: $e');
      rethrow;
    }
  }

  /// Get purchase history for a product
  Future<List<PurchaseItem>> getProductPurchaseHistory(int productId) async {
    try {
      // Get all purchase items for this product
      final allPurchaseItems = await (db.select(
        db.purchaseItems,
      )..where((pi) => pi.productId.equals(productId.toString()))).get();

      // Get purchase details for each item
      final purchaseHistory = <PurchaseItem>[];
      for (final item in allPurchaseItems) {
        final purchase = await purchaseDao.getPurchaseById(item.purchaseId);
        if (purchase != null && !purchase.isDeleted) {
          purchaseHistory.add(item);
        }
      }

      return purchaseHistory;
    } catch (e) {
      log('Error getting purchase history for product $productId: $e');
      rethrow;
    }
  }

  /// Get current stock with purchase tracking info
  Future<Map<String, dynamic>> getProductStockInfo(int productId) async {
    try {
      final product = await (db.select(
        db.products,
      )..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      final purchaseHistory = await getProductPurchaseHistory(productId);

      // Calculate total purchased quantity
      final totalPurchased = purchaseHistory.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      return {
        'product': product,
        'currentStock': product.quantity,
        'totalPurchased': totalPurchased,
        'purchaseCount': purchaseHistory.length,
        'lastPurchase': purchaseHistory.isNotEmpty
            ? purchaseHistory.first.createdAt
            : null,
      };
    } catch (e) {
      log('Error getting stock info for product $productId: $e');
      rethrow;
    }
  }
}

class PurchaseItemData {
  final int productId;
  final int quantity;
  final double unitPrice;
  final String unit;
  final int? cartonQuantity;
  final double? cartonPrice;
  final double discount;
  final double tax;

  PurchaseItemData({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.unit,
    this.cartonQuantity,
    this.cartonPrice,
    this.discount = 0.0,
    this.tax = 0.0,
  });
}
