import 'package:drift/drift.dart';
import 'product_table.dart';
import 'enhanced_purchase_tables.dart';

@DataClassName('PurchaseOrder')
class PurchaseOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text()();
  IntColumn get supplierId => integer().references(EnhancedSuppliers, #id)();
  TextColumn get supplierName => text()();
  TextColumn get supplierPhone => text()();
  DateTimeColumn get orderDate => dateTime()();
  DateTimeColumn get expectedDeliveryDate => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  TextColumn get status => text().withDefault(
    const Constant('draft'),
  )(); // draft, sent, approved, received, cancelled
  TextColumn get priority => text().withDefault(
    const Constant('normal'),
  )(); // low, normal, high, urgent
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PurchaseOrderItem')
class PurchaseOrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId =>
      integer().references(PurchaseOrders, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get productBarcode => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  TextColumn get notes => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('PurchaseOrderStatus')
class PurchaseOrderStatuses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId =>
      integer().references(PurchaseOrders, #id, onDelete: KeyAction.cascade)();
  TextColumn get status =>
      text()(); // draft, sent, approved, received, cancelled
  TextColumn get notes => text().nullable()();
  DateTimeColumn get statusDate => dateTime()();
  IntColumn get userId => integer().nullable()(); // User who changed status
}
