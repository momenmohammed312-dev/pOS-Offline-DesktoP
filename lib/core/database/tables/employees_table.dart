import 'package:drift/drift.dart';

@DataClassName('Employee')
class Employees extends Table {
  TextColumn get id => text()(); // UUID primary key
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get position => text().withLength(min: 1, max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().nullable().withDefault(currentDateAndTime)();
  TextColumn get status => text().nullable().withDefault(
    const Constant('Active'),
  )(); // Active/Inactive

  @override
  Set<Column> get primaryKey => {id};
}
