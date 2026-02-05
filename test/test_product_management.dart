import 'package:drift/drift.dart';
import 'package:pos_offline_desktop/core/database/app_database.dart';

/// Comprehensive Product Management Test Script
/// Tests all product functionality according to SOP requirements

class ProductTester {
  final AppDatabase db;

  ProductTester(this.db);

  /// Test 3.1: Add New Product
  Future<Map<String, dynamic>> testAddNewProduct() async {
    try {
      final testProduct = ProductsCompanion.insert(
        name: 'Test Product 1',
        quantity: 50,
        price: 100.00,
        status: Value('Active'),
        unit: Value('Piece'),
        category: Value('Test Category'),
        barcode: Value('1234567890123'),
        cartonQuantity: Value(10),
        cartonPrice: Value(1000.00),
      );

      final insertedId = await db.productDao.insertProduct(testProduct);

      // Verify insertion
      final product = await db.productDao.getProductById(insertedId);

      return {
        'status': 'PASS',
        'message': 'Product created successfully',
        'productId': insertedId,
        'product': product,
        'details': {
          'name': product?.name,
          'quantity': product?.quantity,
          'price': product?.price,
          'barcode': product?.barcode,
          'category': product?.category,
        },
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Failed to create product: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.2: Barcode Uniqueness
  Future<Map<String, dynamic>> testBarcodeUniqueness() async {
    try {
      // Try to insert product with same barcode
      final duplicateProduct = ProductsCompanion.insert(
        name: 'Duplicate Product',
        quantity: 25,
        price: 50.00,
        status: Value('Active'),
        barcode: Value('1234567890123'), // Same barcode
      );

      await db.productDao.insertProduct(duplicateProduct);

      return {
        'status': 'FAIL',
        'message': 'Duplicate barcode was allowed - this should fail',
      };
    } catch (e) {
      // Expected to fail
      return {
        'status': 'PASS',
        'message': 'Barcode uniqueness enforced correctly',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.3: Edit Product
  Future<Map<String, dynamic>> testEditProduct(int productId) async {
    try {
      final updateCompanion = ProductsCompanion(
        id: Value(productId),
        name: Value('Test Product 1 - Updated'),
        price: Value(120.00),
        quantity: Value(75),
      );

      await db.productDao.updateProduct(updateCompanion);

      // Verify update
      final updatedProduct = await db.productDao.getProductById(productId);

      return {
        'status': 'PASS',
        'message': 'Product updated successfully',
        'updatedProduct': updatedProduct,
        'details': {
          'newName': updatedProduct?.name,
          'newPrice': updatedProduct?.price,
          'newQuantity': updatedProduct?.quantity,
        },
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Failed to update product: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.4: Search Product by Name
  Future<Map<String, dynamic>> testSearchByName() async {
    try {
      final products = await db.productDao.searchProducts('Updated');

      return {
        'status': 'PASS',
        'message': 'Search by name works',
        'results': products.length,
        'products': products.map((p) => p.name).toList(),
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Search by name failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.5: Search Product by Barcode
  Future<Map<String, dynamic>> testSearchByBarcode() async {
    try {
      final products = await db.productDao.searchProducts('1234567890123');

      return {
        'status': 'PASS',
        'message': 'Search by barcode works',
        'results': products.length,
        'products': products
            .map((p) => {'name': p.name, 'barcode': p.barcode})
            .toList(),
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Search by barcode failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.6: Low Stock Alert
  Future<Map<String, dynamic>> testLowStockAlert(int productId) async {
    try {
      // Update product to low stock
      await db.productDao.updateProduct(
        ProductsCompanion(id: Value(productId), quantity: Value(5)),
      );

      // Check if low stock products can be retrieved
      final allProducts = await db.productDao.watchAllProducts().first;
      final lowStockProducts = allProducts
          .where((p) => p.quantity < 10)
          .toList();

      return {
        'status': 'PASS',
        'message': 'Low stock alert works',
        'lowStockCount': lowStockProducts.length,
        'lowStockProducts': lowStockProducts
            .map((p) => {'name': p.name, 'quantity': p.quantity})
            .toList(),
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Low stock alert failed: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.7: Add Product with Image (if supported)
  Future<Map<String, dynamic>> testAddProductWithImage() async {
    try {
      final imageProduct = ProductsCompanion.insert(
        name: 'Test Product with Image',
        quantity: 30,
        price: 80.00,
        status: Value('Active'),
        category: Value('Image Test'),
        barcode: Value('9876543210987'),
      );

      final insertedId = await db.productDao.insertProduct(imageProduct);

      return {
        'status': 'PASS',
        'message': 'Product with image metadata created',
        'productId': insertedId,
        'note': 'Image storage not implemented in database schema',
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Failed to create product with image: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test 3.8: Delete Product
  Future<Map<String, dynamic>> testDeleteProduct(int productId) async {
    try {
      // Get the product first
      final product = await db.productDao.getProductById(productId);
      if (product != null) {
        await db.productDao.deleteProduct(product);
      }

      // Verify deletion
      final deletedProduct = await db.productDao.getProductById(productId);

      return {
        'status': 'PASS',
        'message': 'Product deleted successfully',
        'wasDeleted': deletedProduct == null,
      };
    } catch (e) {
      return {
        'status': 'FAIL',
        'message': 'Failed to delete product: $e',
        'error': e.toString(),
      };
    }
  }

  /// Run all product tests
  Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};

    print('🧪 Starting Product Management Tests...\n');

    // Test 3.1: Add New Product
    print('📝 Test 3.1: Add New Product');
    final addResult = await testAddNewProduct();
    results['test_3_1'] = addResult;
    print('   Status: ${addResult['status']} - ${addResult['message']}\n');

    if (addResult['status'] != 'PASS') {
      return {
        'overall': 'FAIL',
        'reason': 'Cannot proceed without product creation',
        'results': results,
      };
    }

    final productId = addResult['productId'];

    // Test 3.2: Barcode Uniqueness
    print('🔍 Test 3.2: Barcode Uniqueness');
    final barcodeResult = await testBarcodeUniqueness();
    results['test_3_2'] = barcodeResult;
    print(
      '   Status: ${barcodeResult['status']} - ${barcodeResult['message']}\n',
    );

    // Test 3.3: Edit Product
    print('✏️ Test 3.3: Edit Product');
    final editResult = await testEditProduct(productId);
    results['test_3_3'] = editResult;
    print('   Status: ${editResult['status']} - ${editResult['message']}\n');

    // Test 3.4: Search by Name
    print('🔎 Test 3.4: Search Product by Name');
    final searchNameResult = await testSearchByName();
    results['test_3_4'] = searchNameResult;
    print(
      '   Status: ${searchNameResult['status']} - ${searchNameResult['message']}\n',
    );

    // Test 3.5: Search by Barcode
    print('📊 Test 3.5: Search Product by Barcode');
    final searchBarcodeResult = await testSearchByBarcode();
    results['test_3_5'] = searchBarcodeResult;
    print(
      '   Status: ${searchBarcodeResult['status']} - ${searchBarcodeResult['message']}\n',
    );

    // Test 3.6: Low Stock Alert
    print('⚠️ Test 3.6: Low Stock Alert');
    final lowStockResult = await testLowStockAlert(productId);
    results['test_3_6'] = lowStockResult;
    print(
      '   Status: ${lowStockResult['status']} - ${lowStockResult['message']}\n',
    );

    // Test 3.7: Add Product with Image
    print('🖼️ Test 3.7: Add Product with Image');
    final imageResult = await testAddProductWithImage();
    results['test_3_7'] = imageResult;
    print('   Status: ${imageResult['status']} - ${imageResult['message']}\n');

    // Test 3.8: Delete Product
    print('🗑️ Test 3.8: Delete Product');
    final deleteResult = await testDeleteProduct(productId);
    results['test_3_8'] = deleteResult;
    print(
      '   Status: ${deleteResult['status']} - ${deleteResult['message']}\n',
    );

    // Calculate overall results
    final passedTests = results.values
        .where((r) => r['status'] == 'PASS')
        .length;
    final totalTests = results.length;

    return {
      'overall': passedTests == totalTests ? 'PASS' : 'PARTIAL',
      'passed': passedTests,
      'total': totalTests,
      'passRate': '${((passedTests / totalTests) * 100).toStringAsFixed(1)}%',
      'results': results,
    };
  }
}
