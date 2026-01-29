import 'package:drift/drift.dart';
import 'product_table.dart';
import 'enhanced_purchase_tables.dart';

@DataClassName('PurchaseReturn')
class PurchaseReturns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get returnNumber => text()();
  IntColumn get originalPurchaseId =>
      integer().references(EnhancedPurchases, #id)();
  IntColumn get supplierId => integer().references(EnhancedSuppliers, #id)();
  TextColumn get supplierName => text()();
  TextColumn get supplierPhone => text()();
  DateTimeColumn get returnDate => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  TextColumn get returnReason => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, approved, rejected
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PurchaseReturnItem')
class PurchaseReturnItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId =>
      integer().references(PurchaseReturns, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get productBarcode => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  TextColumn get returnReason =>
      text()(); // damaged, expired, wrong_item, other
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('PurchaseRefund')
class PurchaseRefunds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId => integer().references(PurchaseReturns, #id)();
  IntColumn get supplierId => integer().references(EnhancedSuppliers, #id)();
  TextColumn get refundNumber => text()();
  DateTimeColumn get refundDate => dateTime()();
  RealColumn get refundAmount => real()();
  TextColumn get refundMethod => text()(); // cash, bank_transfer, check, credit
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
