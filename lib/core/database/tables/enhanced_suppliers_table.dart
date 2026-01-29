import 'package:drift/drift.dart';

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
