import 'package:drift/drift.dart';
import 'invoice_table.dart';

@DataClassName('CreditPayment')
class CreditPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Invoices, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMethod => text().withLength(min: 1, max: 50)();
}
