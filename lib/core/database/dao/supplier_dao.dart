import 'package:drift/drift.dart';

import '../tables/supplier_table.dart';
import '../app_database.dart';

part 'supplier_dao.g.dart';

@DriftAccessor(tables: [Suppliers])
class SupplierDao extends DatabaseAccessor<AppDatabase>
    with _$SupplierDaoMixin {
  SupplierDao(super.db);

  Future<List<Supplier>> getAllSuppliers() => select(suppliers).get();

  Future<Supplier?> getSupplierById(String id) =>
      (select(suppliers)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<List<Supplier>> getActiveSuppliers() =>
      (select(suppliers)..where((tbl) => tbl.status.equals('Active'))).get();

  Future<Supplier> insertSupplier(SuppliersCompanion supplier) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final supplierWithId = supplier.copyWith(id: Value(id));
    await into(suppliers).insert(supplierWithId);
    return await getSupplierById(id) ??
        (throw Exception('Failed to insert supplier'));
  }

  Future<bool> updateSupplier(SuppliersCompanion supplier) =>
      update(suppliers).replace(supplier);

  Future<int> deleteSupplier(String id) =>
      (delete(suppliers)..where((tbl) => tbl.id.equals(id))).go();

  Future<int> deactivateSupplier(String id) =>
      (update(suppliers)..where((tbl) => tbl.id.equals(id))).write(
        SuppliersCompanion(status: const Value('Inactive')),
      );

  Future<double> getSupplierBalance(String id) async {
    final transactions =
        await (select(db.ledgerTransactions)..where(
              (tbl) => tbl.entityType.equals('Supplier') & tbl.refId.equals(id),
            ))
            .get();

    return transactions.fold<double>(0.0, (sum, transaction) {
      return sum + transaction.credit - transaction.debit;
    });
  }

  Stream<int> watchSuppliersCount() {
    return customSelect(
      'SELECT COUNT(*) as count FROM suppliers',
      readsFrom: {suppliers},
    ).map((row) => row.read<int>('count')).watchSingle();
  }
}
