import 'package:drift/drift.dart';

class PurchaseItems extends Table {
  TextColumn get id => text()(); // UUID or timestamp-based ID

  TextColumn get purchaseId => text()(); // Reference to purchase

  TextColumn get productId => text()(); // Reference to product

  IntColumn get quantity => integer()(); // Quantity purchased

  RealColumn get unitPrice => real()(); // Price per unit

  RealColumn get totalPrice =>
      real()(); // Total price for this item (quantity * unitPrice)

  TextColumn get unit => text()(); // Unit of measurement (piece, kg, etc.)

  IntColumn get cartonQuantity =>
      integer().nullable()(); // Number of cartons (if applicable)

  RealColumn get cartonPrice =>
      real().nullable()(); // Price per carton (if applicable)

  RealColumn get discount =>
      real().withDefault(const Constant(0.0))(); // Discount amount

  RealColumn get tax => real().withDefault(const Constant(0.0))(); // Tax amount

  DateTimeColumn get createdAt => dateTime()(); // When item was added

  // For tracking original quantities before purchase
  IntColumn get originalStock =>
      integer().nullable()(); // Stock quantity before this purchase

  IntColumn get newStock =>
      integer().nullable()(); // Stock quantity after this purchase
}
