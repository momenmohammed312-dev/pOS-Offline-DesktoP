// database/dao/product_dao.dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<Product>> getAllProducts() => select(products).get();
  Stream<List<Product>> watchAllProducts() => select(products).watch();
  Future insertProduct(Insertable<Product> product) =>
      into(products).insert(product);
  Future updateProduct(Insertable<Product> product) =>
      update(products).replace(product);
  // Total products count
  Future<int> getTotalProductCount() async {
    final countExp = products.id.count(); // or any column
    final query = selectOnly(products)..addColumns([countExp]);

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  Future deleteProduct(Insertable<Product> product) =>
      delete(products).delete(product);

  /// Search products by name or SKU/code using LIKE.
  Future<List<Product>> searchProducts(String query) {
    final q = query.trim();
    if (q.isEmpty) return getAllProducts();

    return (select(products)..where((p) => p.name.like('%$q%'))).get();
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String? category) {
    if (category == null || category == 'all') {
      return getAllProducts();
    }
    return (select(products)..where((p) => p.category.equals(category))).get();
  }

  /// Search products by barcode
  Future<Product?> getProductByBarcode(String barcode) {
    return (select(
      products,
    )..where((p) => p.barcode.equals(barcode))).getSingleOrNull();
  }

  /// Get all unique categories
  Future<List<String>> getUniqueCategories() {
    final query = selectOnly(products)
      ..addColumns([products.category])
      ..where(products.category.isNotNull())
      ..groupBy([products.category]);

    return query.map((row) => row.read(products.category)!).get();
  }

  /// Filter products by category and unit
  Future<List<Product>> filterProducts({
    String? category,
    String? unit,
    String? searchQuery,
  }) {
    var query = select(products);

    if (category != null && category != 'all') {
      query = query..where((p) => p.category.equals(category));
    }

    if (unit != null && unit != 'all') {
      query = query..where((p) => p.unit.equals(unit));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query..where((p) => p.name.like('%$searchQuery%'));
    }

    return query.get();
  }
}
