import 'package:drift/drift.dart';

class LedgerTransactions extends Table {
  TextColumn get id => text()(); // UUID primary key
  TextColumn get entityType => text()(); // 'Customer' | 'Supplier'
  TextColumn get refId => text()(); // Customer/Supplier ID
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text()();
  RealColumn get debit =>
      real().withDefault(const Constant(0.0))(); // increases balance
  RealColumn get credit =>
      real().withDefault(const Constant(0.0))(); // decreases balance
  TextColumn get origin =>
      text()(); // 'sale' | 'purchase' | 'payment' | 'opening' | 'reversal'
  TextColumn get paymentMethod =>
      text().nullable()(); // 'cash' | 'instapay' | 'bank' | 'wallet'
  TextColumn get receiptNumber => text().nullable()();
  TextColumn get lockBatch => text().nullable()(); // daily close marker
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
