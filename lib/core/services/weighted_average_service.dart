import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class WeightedAverageService {
  final AppDatabase _database;

  WeightedAverageService(this._database);

  /// Calculate weighted average cost for a product
  /// Formula: (OldQuantity × OldCost + NewQuantity × NewCost) / (OldQuantity + NewQuantity)
  Future<double> calculateWeightedAverageCost({
    required int productId,
    required double oldQuantity,
    required double oldCost,
    required double newQuantity,
    required double newCost,
  }) async {
    if (oldQuantity + newQuantity == 0) return 0.0;

    final totalCost = (oldQuantity * oldCost) + (newQuantity * newCost);
    final totalQuantity = oldQuantity + newQuantity;

    return totalCost / totalQuantity;
  }

  /// Update product cost when adding new purchase
  Future<void> updateProductCostOnPurchase({
    required int productId,
    required double newQuantity,
    required double newUnitCost,
  }) async {
    try {
      // Get current product data
      final product = await (_database.select(
        _database.products,
      )..where((p) => p.id.equals(productId))).getSingleOrNull();

      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      final oldQuantity = product.quantity.toDouble();
      final oldCost =
          product.price; // Use price as cost since costPrice doesn't exist

      // Calculate new weighted average cost
      final newAverageCost = await calculateWeightedAverageCost(
        productId: productId,
        oldQuantity: oldQuantity,
        oldCost: oldCost,
        newQuantity: newQuantity,
        newCost: newUnitCost,
      );

      // Update product with new price (using price field as average cost)
      await (_database.update(_database.products)
            ..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(price: drift.Value(newAverageCost)));
    } catch (e) {
      throw Exception('Error updating product cost on purchase: $e');
    }
  }

  /// Update product cost when adjusting inventory
  Future<void> updateProductCostOnAdjustment({
    required int productId,
    required double adjustmentQuantity,
    required double adjustmentCost,
    String? notes,
  }) async {
    try {
      // Get current product data
      final product = await (_database.select(
        _database.products,
      )..where((p) => p.id.equals(productId))).getSingleOrNull();

      if (product == null) {
        throw Exception('Product not found: $productId');
      }

      final oldQuantity = product.quantity.toDouble();
      final oldCost =
          product.price; // Use price as cost since costPrice doesn't exist

      // Calculate new weighted average cost
      final newAverageCost = await calculateWeightedAverageCost(
        productId: productId,
        oldQuantity: oldQuantity,
        oldCost: oldCost,
        newQuantity: adjustmentQuantity,
        newCost: adjustmentCost,
      );

      // Update product with new cost and quantity
      await (_database.update(
        _database.products,
      )..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(
          price: drift.Value(newAverageCost),
          quantity: drift.Value((oldQuantity + adjustmentQuantity).toInt()),
        ),
      );
    } catch (e) {
      throw Exception('Error updating product cost on adjustment: $e');
    }
  }

  /// Get product cost history
  Future<List<Map<String, dynamic>>> getProductCostHistory(
    int productId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // For now, return empty list since we don't have cost history table
      // This can be implemented later with inventory movements table
      return [];
    } catch (e) {
      throw Exception('Error getting product cost history: $e');
    }
  }

  /// Recalculate all product average costs
  Future<void> recalculateAllProductAverageCosts() async {
    try {
      final products = await (_database.select(_database.products)).get();

      for (final product in products) {
        // For now, just use current price as average cost
        // This can be enhanced later with actual purchase history
        await (_database.update(_database.products)
              ..where((p) => p.id.equals(product.id)))
            .write(ProductsCompanion(price: drift.Value(product.price)));
      }
    } catch (e) {
      throw Exception('Error recalculating product average costs: $e');
    }
  }

  /// Record inventory movement
  Future<void> recordInventoryMovement({
    required int productId,
    required String movementType,
    required double quantity,
    required double unitCost,
    required String reference,
    required String referenceType,
    required double previousQuantity,
    required double newQuantity,
    String? notes,
    String? performedBy,
  }) async {
    try {
      final movement = InventoryMovementsCompanion.insert(
        productId: productId,
        movementType: movementType,
        quantity: quantity.toInt(),
        unitCost: unitCost,
        totalValue: quantity * unitCost,
        movementDate: DateTime.now(),
        reference: reference,
        referenceType: referenceType,
        previousQuantity: previousQuantity.toInt(),
        newQuantity: newQuantity.toInt(),
        performedBy: drift.Value(performedBy ?? 'System'),
        notes: drift.Value(notes ?? ''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _database.into(_database.inventoryMovements).insert(movement);
    } catch (e) {
      throw Exception('Error recording inventory movement: $e');
    }
  }

  /// Get cost analysis report
  Future<Map<String, dynamic>> getCostAnalysisReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all products
      final products = await (_database.select(_database.products)).get();

      double totalValue = 0.0;
      int totalProducts = products.length;

      for (final product in products) {
        totalValue += product.quantity * product.price;
      }

      return {
        'totalProducts': totalProducts,
        'totalValue': totalValue,
        'averageCostPerProduct': totalProducts > 0
            ? totalValue / totalProducts
            : 0.0,
        'reportDate': DateTime.now(),
      };
    } catch (e) {
      throw Exception('Error generating cost analysis report: $e');
    }
  }
}
