import 'package:drift/drift.dart';

class Purchases extends Table {
  TextColumn get id => text()(); // UUID or timestamp-based ID

  TextColumn get supplierId => text().nullable()(); // Reference to supplier

  TextColumn get invoiceNumber => text()(); // Purchase invoice number

  TextColumn get description => text()(); // Purchase description

  RealColumn get totalAmount => real()(); // Total purchase amount

  RealColumn get paidAmount =>
      real().withDefault(const Constant(0.0))(); // Amount paid

  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))(); // cash, credit, etc.

  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, completed, cancelled

  DateTimeColumn get purchaseDate => dateTime()(); // Date of purchase

  DateTimeColumn get createdAt => dateTime()(); // When record was created

  TextColumn get notes => text().nullable()(); // Additional notes

  // For tracking
  TextColumn get createdBy =>
      text().nullable()(); // User who created the purchase

  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Soft delete flag
}
