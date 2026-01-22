import 'package:drift/drift.dart';

/// Fixed Invoice table with all required columns
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()(); // Primary key

  TextColumn get invoiceNumber => text().withLength(min: 1, max: 255)();

  TextColumn get customerId =>
      text().nullable()(); // Link to customer table for credit customers

  TextColumn get customerName => text().withLength(min: 1, max: 255)();

  TextColumn get customerContact => text().nullable()();

  TextColumn get customerAddress => text().nullable()();

  TextColumn get paymentMethod => text().withLength(
    min: 1,
    max: 50,
  )(); // 'cash' | 'credit' | 'visa' | 'bank'

  RealColumn get totalAmount => real().withDefault(const Constant(0))();

  RealColumn get paidAmount =>
      real().withDefault(const Constant(0))(); // Track partial payments

  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();

  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .withDefault(
        const Constant('pending'),
      )(); // 'pending' | 'paid' | 'partial'

  TextColumn get notes => text().nullable()(); // Additional notes field

  TextColumn get createdBy => text()
      .withLength(min: 1, max: 100)
      .withDefault(const Constant('system'))(); // Track who created the invoice

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id}; // Use auto-increment id as primary key
}
