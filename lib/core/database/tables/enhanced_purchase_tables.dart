import 'package:drift/drift.dart';
import 'product_table.dart';

@DataClassName('EnhancedSupplier')
class EnhancedSuppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get businessName => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().unique()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get zipCode => text()();
  TextColumn get state => text()();
  TextColumn get taxNumber => text().nullable()();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  BoolColumn get isCreditAccount =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('EnhancedPurchase')
class EnhancedPurchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseNumber => text()();
  IntColumn get supplierId => integer().references(EnhancedSuppliers, #id)();
  TextColumn get supplierName => text()();
  TextColumn get supplierPhone => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get tax => real().withDefault(const Constant(0.0))();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  BoolColumn get isCreditPurchase =>
      boolean().withDefault(const Constant(false))();
  RealColumn get previousBalance => real().withDefault(const Constant(0.0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text()(); // 'cash', 'credit', 'partial'
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('EnhancedPurchaseItem')
class EnhancedPurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(
    EnhancedPurchases,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get productBarcode => text().nullable()();
  TextColumn get unit => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SupplierPayment')
class SupplierPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().references(EnhancedSuppliers, #id)();
  IntColumn get purchaseId =>
      integer().references(EnhancedPurchases, #id).nullable()();
  TextColumn get paymentNumber => text()();
  DateTimeColumn get paymentDate => dateTime()();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()(); // 'cash', 'bank_transfer', 'check'
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
