import 'package:drift/drift.dart';

enum CustomerStatus {
  inactive(0),
  active(1);

  final int value;
  const CustomerStatus(this.value);

  static CustomerStatus fromInt(int? val) {
    if (val == 0) return CustomerStatus.inactive;
    return CustomerStatus.active;
  }
}

class Customers extends Table {
  TextColumn get id => text()(); // UUID primary key
  TextColumn get name => text().withLength(max: 255)();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get gstinNumber => text().nullable()();
  TextColumn get email => text().nullable()(); // New
  RealColumn get openingBalance => real().withDefault(
    const Constant(0.0),
  )(); // ignore: non_constant_identifier_names
  RealColumn get totalDebt => real().withDefault(
    const Constant(0.0),
  )(); // ignore: non_constant_identifier_names
  RealColumn get totalPaid => real().withDefault(
    const Constant(0.0),
  )(); // ignore: non_constant_identifier_names
  DateTimeColumn get createdAt =>
      dateTime().nullable()(); // ignore: non_constant_identifier_names
  DateTimeColumn get updatedAt =>
      dateTime().nullable()(); // ignore: non_constant_identifier_names
  TextColumn get notes => text().nullable()(); // New
  BoolColumn get isActive => boolean().withDefault(
    const Constant(true),
  )(); // ignore: non_constant_identifier_names
  IntColumn get status => integer().nullable().withDefault(
    const Constant(1),
  )(); // INTEGER for Enum indices (Active = 1, Inactive = 0)

  @override
  Set<Column> get primaryKey => {id};
}
