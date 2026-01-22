import 'package:drift/drift.dart';

class Suppliers extends Table {
  TextColumn get id => text()(); // UUID primary key
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status =>
      text().withDefault(const Constant('Active'))(); // Active/Inactive

  @override
  Set<Column> get primaryKey => {id};
}
