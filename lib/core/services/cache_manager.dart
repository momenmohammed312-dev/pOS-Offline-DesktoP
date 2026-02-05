import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

/// Cache Manager for POS System
/// مدير التخزين المؤقت لنظام نقاط البيع
class AppCacheManager {
  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;
  AppCacheManager._internal();

  // Product cache
  static final Map<int, Product> _productCache = {};
  static final Map<String, Product> _productBarcodeCache = {};
  static DateTime? _productCacheTimestamp;
  static const Duration _productCacheExpiry = Duration(minutes: 30);

  // Customer cache
  static final Map<String, Customer> _customerCache = {};
  static DateTime? _customerCacheTimestamp;
  static const Duration _customerCacheExpiry = Duration(minutes: 15);

  // Supplier cache
  static final Map<int, EnhancedSupplier> _supplierCache = {};
  static DateTime? _supplierCacheTimestamp;
  static const Duration _supplierCacheExpiry = Duration(minutes: 15);

  // Category cache
  static final Set<String> _categoryCache = {};
  static DateTime? _categoryCacheTimestamp;
  static const Duration _categoryCacheExpiry = Duration(hours: 1);

  // Statistics cache
  static Map<String, dynamic>? _statisticsCache;
  static DateTime? _statisticsCacheTimestamp;
  static const Duration _statisticsCacheExpiry = Duration(minutes: 5);

  // Product cache methods
  static Product? getCachedProduct(int id) {
    if (_isProductCacheExpired()) {
      _clearProductCache();
      return null;
    }
    return _productCache[id];
  }

  static Product? getCachedProductByBarcode(String barcode) {
    if (_isProductCacheExpired()) {
      _clearProductCache();
      return null;
    }
    return _productBarcodeCache[barcode];
  }

  static void cacheProduct(Product product) {
    _productCache[product.id] = product;
    if (product.barcode != null && product.barcode!.isNotEmpty) {
      _productBarcodeCache[product.barcode!] = product;
    }
    _productCacheTimestamp = DateTime.now();
  }

  static void cacheProducts(List<Product> products) {
    for (final product in products) {
      _productCache[product.id] = product;
      if (product.barcode != null && product.barcode!.isNotEmpty) {
        _productBarcodeCache[product.barcode!] = product;
      }
    }
    _productCacheTimestamp = DateTime.now();
  }

  static void invalidateProductCache() {
    _productCache.clear();
    _productBarcodeCache.clear();
    _productCacheTimestamp = null;
  }

  static bool _isProductCacheExpired() {
    if (_productCacheTimestamp == null) return true;
    return DateTime.now().difference(_productCacheTimestamp!) >
        _productCacheExpiry;
  }

  // Customer cache methods
  static Customer? getCachedCustomer(String idOrPhone) {
    if (_isCustomerCacheExpired()) {
      _clearCustomerCache();
      return null;
    }
    return _customerCache[idOrPhone];
  }

  static void cacheCustomer(Customer customer) {
    _customerCache[customer.id.toString()] = customer;
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      _customerCache[customer.phone!] = customer;
    }
    _customerCacheTimestamp = DateTime.now();
  }

  static void cacheCustomers(List<Customer> customers) {
    for (final customer in customers) {
      _customerCache[customer.id.toString()] = customer;
      if (customer.phone != null && customer.phone!.isNotEmpty) {
        _customerCache[customer.phone!] = customer;
      }
    }
    _customerCacheTimestamp = DateTime.now();
  }

  static void invalidateCustomerCache() {
    _customerCache.clear();
    _customerCacheTimestamp = null;
  }

  static bool _isCustomerCacheExpired() {
    if (_customerCacheTimestamp == null) return true;
    return DateTime.now().difference(_customerCacheTimestamp!) >
        _customerCacheExpiry;
  }

  // Supplier cache methods
  static EnhancedSupplier? getCachedSupplier(int id) {
    if (_isSupplierCacheExpired()) {
      _clearSupplierCache();
      return null;
    }
    return _supplierCache[id];
  }

  static void cacheSupplier(EnhancedSupplier supplier) {
    _supplierCache[supplier.id] = supplier;
    _supplierCacheTimestamp = DateTime.now();
  }

  static void cacheSuppliers(List<EnhancedSupplier> suppliers) {
    for (final supplier in suppliers) {
      _supplierCache[supplier.id] = supplier;
    }
    _supplierCacheTimestamp = DateTime.now();
  }

  static void invalidateSupplierCache() {
    _supplierCache.clear();
    _supplierCacheTimestamp = null;
  }

  static bool _isSupplierCacheExpired() {
    if (_supplierCacheTimestamp == null) return true;
    return DateTime.now().difference(_supplierCacheTimestamp!) >
        _supplierCacheExpiry;
  }

  // Category cache methods
  static Set<String> getCachedCategories() {
    if (_isCategoryCacheExpired()) {
      _clearCategoryCache();
      return {};
    }
    return _categoryCache;
  }

  static void cacheCategories(Set<String> categories) {
    _categoryCache.clear();
    _categoryCache.addAll(categories);
    _categoryCacheTimestamp = DateTime.now();
  }

  static void addCategory(String category) {
    _categoryCache.add(category);
    _categoryCacheTimestamp = DateTime.now();
  }

  static void invalidateCategoryCache() {
    _categoryCache.clear();
    _categoryCacheTimestamp = null;
  }

  static bool _isCategoryCacheExpired() {
    if (_categoryCacheTimestamp == null) return true;
    return DateTime.now().difference(_categoryCacheTimestamp!) >
        _categoryCacheExpiry;
  }

  // Statistics cache methods
  static Map<String, dynamic>? getCachedStatistics() {
    if (_isStatisticsCacheExpired()) {
      _clearStatisticsCache();
      return null;
    }
    return _statisticsCache;
  }

  static void cacheStatistics(Map<String, dynamic> statistics) {
    _statisticsCache = Map.from(statistics);
    _statisticsCacheTimestamp = DateTime.now();
  }

  static void invalidateStatisticsCache() {
    _statisticsCache = null;
    _statisticsCacheTimestamp = null;
  }

  static bool _isStatisticsCacheExpired() {
    if (_statisticsCacheTimestamp == null) return true;
    return DateTime.now().difference(_statisticsCacheTimestamp!) >
        _statisticsCacheExpiry;
  }

  // General cache management
  static void invalidateAllCaches() {
    invalidateProductCache();
    invalidateCustomerCache();
    invalidateSupplierCache();
    invalidateCategoryCache();
    invalidateStatisticsCache();
  }

  static Map<String, dynamic> getCacheStats() {
    return {
      'productCacheSize': _productCache.length,
      'productCacheAge': _productCacheTimestamp != null
          ? DateTime.now().difference(_productCacheTimestamp!).inMinutes
          : null,
      'customerCacheSize': _customerCache.length,
      'customerCacheAge': _customerCacheTimestamp != null
          ? DateTime.now().difference(_customerCacheTimestamp!).inMinutes
          : null,
      'supplierCacheSize': _supplierCache.length,
      'supplierCacheAge': _supplierCacheTimestamp != null
          ? DateTime.now().difference(_supplierCacheTimestamp!).inMinutes
          : null,
      'categoryCacheSize': _categoryCache.length,
      'categoryCacheAge': _categoryCacheTimestamp != null
          ? DateTime.now().difference(_categoryCacheTimestamp!).inMinutes
          : null,
      'statisticsCacheAge': _statisticsCacheTimestamp != null
          ? DateTime.now().difference(_statisticsCacheTimestamp!).inMinutes
          : null,
    };
  }

  static Future<void> warmupCaches(AppDatabase db) async {
    try {
      debugPrint('Warming up caches...');

      // Warm up product cache
      if (_isProductCacheExpired()) {
        final products = await db.productDao.getAllProducts();
        cacheProducts(products);
        debugPrint('Warmed up product cache with ${products.length} items');
      }

      // Warm up customer cache
      if (_isCustomerCacheExpired()) {
        final customers = await db.customerDao.getAllCustomers();
        cacheCustomers(customers);
        debugPrint('Warmed up customer cache with ${customers.length} items');
      }

      // Warm up supplier cache
      if (_isSupplierCacheExpired()) {
        final suppliers = await db.enhancedPurchaseDao.getAllSuppliers();
        cacheSuppliers(suppliers);
        debugPrint('Warmed up supplier cache with ${suppliers.length} items');
      }

      // Warm up category cache
      if (_isCategoryCacheExpired()) {
        final products = await db.productDao.getAllProducts();
        final categories = products
            .map((p) => p.category ?? 'غير مصنف')
            .toSet();
        cacheCategories(categories);
        debugPrint('Warmed up category cache with ${categories.length} items');
      }

      debugPrint('Cache warmup completed successfully');
    } catch (e) {
      debugPrint('Error during cache warmup: $e');
    }
  }

  // Cache cleanup for memory management
  static void performCacheCleanup() {
    final stats = getCacheStats();

    // If caches are too old, invalidate them
    if (_isProductCacheExpired()) _clearProductCache();
    if (_isCustomerCacheExpired()) _clearCustomerCache();
    if (_isSupplierCacheExpired()) _clearSupplierCache();
    if (_isCategoryCacheExpired()) _clearCategoryCache();
    if (_isStatisticsCacheExpired()) _clearStatisticsCache();

    debugPrint('Cache cleanup completed. Stats: $stats');
  }

  // Clear cache methods
  static void _clearProductCache() {
    _productCache.clear();
    _productBarcodeCache.clear();
    _productCacheTimestamp = null;
  }

  static void _clearCustomerCache() {
    _customerCache.clear();
    _customerCacheTimestamp = null;
  }

  static void _clearSupplierCache() {
    _supplierCache.clear();
    _supplierCacheTimestamp = null;
  }

  static void _clearCategoryCache() {
    _categoryCache.clear();
    _categoryCacheTimestamp = null;
  }

  static void _clearStatisticsCache() {
    _statisticsCache = null;
    _statisticsCacheTimestamp = null;
  }

  // Periodic cache maintenance
  static Timer? _maintenanceTimer;

  static void startPeriodicMaintenance() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      performCacheCleanup();
    });
    debugPrint('Started periodic cache maintenance');
  }

  static void stopPeriodicMaintenance() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
    debugPrint('Stopped periodic cache maintenance');
  }
}
