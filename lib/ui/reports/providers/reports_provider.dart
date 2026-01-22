import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/dao/ledger_dao.dart';
import '../../../core/database/dao/purchase_dao.dart';

// Data models for reports
class ReportFilter {
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? customerId;
  final String? supplierId;
  final String? productId;
  final String? status;
  final Map<String, dynamic> additionalFilters;

  const ReportFilter({
    this.fromDate,
    this.toDate,
    this.customerId,
    this.supplierId,
    this.productId,
    this.status,
    this.additionalFilters = const {},
  });

  ReportFilter copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    String? customerId,
    String? supplierId,
    String? productId,
    String? status,
    Map<String, dynamic>? additionalFilters,
  }) {
    return ReportFilter(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      productId: productId ?? this.productId,
      status: status ?? this.status,
      additionalFilters: additionalFilters ?? this.additionalFilters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'customerId': customerId,
      'supplierId': supplierId,
      'productId': productId,
      'status': status,
      ...additionalFilters,
    };
  }
}

class ReportSummary {
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;
  final int totalCount;
  final Map<String, dynamic> additionalSummary;

  const ReportSummary({
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.totalCount,
    this.additionalSummary = const {},
  });
}

// State class for reports
class ReportsState {
  final List<Map<String, dynamic>> data;
  final ReportFilter? currentFilter;
  final ReportSummary? summary;
  final bool isLoading;
  final String? error;

  const ReportsState({
    this.data = const [],
    this.currentFilter,
    this.summary,
    this.isLoading = false,
    this.error,
  });

  ReportsState copyWith({
    List<Map<String, dynamic>>? data,
    ReportFilter? currentFilter,
    ReportSummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return ReportsState(
      data: data ?? this.data,
      currentFilter: currentFilter ?? this.currentFilter,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  T when<T>({
    required T Function() loading,
    required T Function(Object error, dynamic stack) error,
    required T Function() data,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error.toString(), StackTrace.current);
    } else {
      return data();
    }
  }
}

// Notifier class for managing reports state
class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier() : super(const ReportsState());

  Future<void> loadReportData({
    required String reportType,
    required AppDatabase db,
    ReportFilter? filter,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      List<Map<String, dynamic>> data = [];
      ReportSummary? summary;

      switch (reportType) {
        case 'sales':
          data = await _loadSalesData(db, filter);
          summary = _calculateSalesSummary(data);
          break;
        case 'customers':
          data = await _loadCustomersData(db, filter);
          summary = _calculateCustomersSummary(data);
          break;
        case 'suppliers':
          data = await _loadSuppliersData(db, filter);
          summary = _calculateSuppliersSummary(data);
          break;
        case 'products':
          data = await _loadProductsData(db, filter);
          summary = _calculateProductsSummary(data);
          break;
        case 'financial':
          data = await _loadFinancialData(db, filter);
          summary = _calculateFinancialSummary(data);
          break;
        default:
          throw Exception('نوع التقرير غير مدعوم: $reportType');
      }

      state = state.copyWith(
        data: data,
        summary: summary,
        currentFilter: filter,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilters(ReportFilter filter) async {
    // This would typically reload data with new filters
    // For now, just update the filter state
    state = state.copyWith(currentFilter: filter);
  }

  void refresh() {
    // This would typically reload current data
    state = state.copyWith(isLoading: true);
    // Simulate refresh
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(isLoading: false);
    });
  }

  // Private methods for loading different report types
  Future<List<Map<String, dynamic>>> _loadSalesData(
    AppDatabase db,
    ReportFilter? filter,
  ) async {
    var query = db.select(db.invoices);

    // Apply filters
    if (filter?.customerId != null) {
      query = query..where((tbl) => tbl.customerId.equals(filter!.customerId!));
    }
    if (filter?.status != null) {
      query = query..where((tbl) => tbl.status.equals(filter!.status!));
    }

    final invoices = await query.get();

    return invoices
        .map(
          (invoice) => {
            'id': invoice.id,
            'invoiceNumber': invoice.invoiceNumber ?? 'N/A',
            'customerName': invoice.customerName,
            'customerContact': invoice.customerContact,
            'date': invoice.date.toIso8601String(),
            'totalAmount': invoice.totalAmount,
            'paidAmount': invoice.paidAmount,
            'unpaidAmount': invoice.totalAmount - invoice.paidAmount,
            'status': invoice.status,
            'paymentMethod': invoice.paymentMethod,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadCustomersData(
    AppDatabase db,
    ReportFilter? filter,
  ) async {
    var query = db.select(db.customers);

    // Apply filters
    if (filter?.customerId != null) {
      query = query..where((tbl) => tbl.id.equals(filter!.customerId!));
    }

    final customers = await query.get();
    final List<Map<String, dynamic>> result = [];

    for (final customer in customers) {
      // Get customer's running balance from ledger transactions
      final ledgerDao = LedgerDao(db);
      final balance = await ledgerDao.getCustomerBalance(customer.id);

      // Get customer's invoice count
      final invoiceQuery = db.select(db.invoices)
        ..where((tbl) => tbl.customerId.equals(customer.id));
      final invoiceCount = await invoiceQuery.get();
      final count = invoiceCount.length;

      result.add({
        'id': customer.id,
        'name': customer.name,
        'contact': customer.phone,
        'address': customer.address,
        'balance': balance,
        'totalInvoices': count,
        'status': customer.status,
        'createdAt': customer.createdAt?.toIso8601String() ?? '',
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _loadSuppliersData(
    AppDatabase db,
    ReportFilter? filter,
  ) async {
    var query = db.select(db.suppliers);

    // Apply filters
    if (filter?.supplierId != null) {
      query = query..where((tbl) => tbl.id.equals(filter!.supplierId!));
    }

    final suppliers = await query.get();
    final List<Map<String, dynamic>> result = [];

    for (final supplier in suppliers) {
      // Get supplier's running balance from ledger transactions
      final ledgerDao = LedgerDao(db);
      final balance = await ledgerDao.getSupplierBalance(supplier.id);

      // Get supplier's transaction count from purchases
      final purchaseDao = PurchaseDao(db);
      final supplierPurchases = await purchaseDao.getPurchasesBySupplier(
        supplier.id,
      );
      final transactionCount = supplierPurchases.length;

      result.add({
        'id': supplier.id,
        'name': supplier.name,
        'contact': supplier.phone,
        'address': supplier.address,
        'balance': balance,
        'totalPurchases': transactionCount,
        'status': supplier.status,
        'createdAt': supplier.createdAt.toIso8601String(),
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _loadProductsData(
    AppDatabase db,
    ReportFilter? filter,
  ) async {
    var query = db.select(db.products);

    // Apply filters
    if (filter?.productId != null) {
      query = query
        ..where((tbl) => tbl.id.equals(int.parse(filter!.productId!)));
    }

    final products = await query.get();
    final List<Map<String, dynamic>> result = [];

    for (final product in products) {
      // Calculate total sold from invoice items
      final soldQuery = db.select(db.invoiceItems)
        ..where((tbl) => tbl.productId.equals(product.id));
      final soldItems = await soldQuery.get();
      final totalSold = soldItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      result.add({
        'id': product.id.toString(),
        'name': product.name,
        'category':
            product.unit ?? 'قطعة', // Using unit as category placeholder
        'quantity': product.quantity,
        'price': product.price,
        'totalValue': product.quantity * product.price,
        'totalSold': totalSold,
        'remaining': product.quantity - totalSold,
        'status': product.status,
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _loadFinancialData(
    AppDatabase db,
    ReportFilter? filter,
  ) async {
    final List<Map<String, dynamic>> result = [];

    // Get income from invoices
    var invoiceQuery = db.select(db.invoices);

    final invoices = await invoiceQuery.get();
    for (final invoice in invoices) {
      result.add({
        'id': 'inv_${invoice.id}',
        'type': 'دخل',
        'description': 'فاتورة رقم ${invoice.invoiceNumber ?? 'N/A'}',
        'amount': invoice.totalAmount,
        'date': invoice.date.toIso8601String(),
        'reference': invoice.invoiceNumber ?? 'N/A',
      });
    }

    // Get expenses
    var expenseQuery = db.select(db.expenses);

    final expenses = await expenseQuery.get();
    for (final expense in expenses) {
      result.add({
        'id': 'exp_${expense.id}',
        'type': 'مصروف',
        'description': expense.description,
        'amount': -expense.amount, // Negative for expenses
        'date': expense.date.toIso8601String(),
        'reference': expense.category,
      });
    }

    // Sort by date
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return result;
  }

  // Summary calculation methods
  ReportSummary _calculateSalesSummary(List<Map<String, dynamic>> data) {
    final totalAmount = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['totalAmount'] as double? ?? 0.0),
    );
    final paidAmount = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['paidAmount'] as double? ?? 0.0),
    );

    return ReportSummary(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      unpaidAmount: totalAmount - paidAmount,
      totalCount: data.length,
    );
  }

  ReportSummary _calculateCustomersSummary(List<Map<String, dynamic>> data) {
    final totalBalance = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['balance'] as double? ?? 0.0),
    );

    return ReportSummary(
      totalAmount: totalBalance.abs(),
      paidAmount: data
          .where((item) => (item['balance'] as double? ?? 0.0) <= 0)
          .length
          .toDouble(),
      unpaidAmount: data
          .where((item) => (item['balance'] as double? ?? 0.0) > 0)
          .length
          .toDouble(),
      totalCount: data.length,
    );
  }

  ReportSummary _calculateSuppliersSummary(List<Map<String, dynamic>> data) {
    final totalBalance = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['balance'] as double? ?? 0.0),
    );

    return ReportSummary(
      totalAmount: totalBalance.abs(),
      paidAmount: data.length.toDouble(),
      unpaidAmount: 0.0,
      totalCount: data.length,
    );
  }

  ReportSummary _calculateProductsSummary(List<Map<String, dynamic>> data) {
    final totalValue = data.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item['quantity'] as int? ?? 0) * (item['price'] as double? ?? 0.0)),
    );

    return ReportSummary(
      totalAmount: totalValue,
      paidAmount: data.fold<double>(
        0.0,
        (sum, item) => sum + (item['totalSold'] as int? ?? 0).toDouble(),
      ),
      unpaidAmount: data.fold<double>(
        0.0,
        (sum, item) => sum + (item['quantity'] as int? ?? 0).toDouble(),
      ),
      totalCount: data.length,
    );
  }

  ReportSummary _calculateFinancialSummary(List<Map<String, dynamic>> data) {
    final totalIncome = data
        .where((item) => (item['type'] as String? ?? '') == 'دخل')
        .fold<double>(
          0.0,
          (sum, item) => sum + (item['amount'] as double? ?? 0.0),
        );
    final totalExpenses = data
        .where((item) => (item['type'] as String? ?? '') == 'مصروف')
        .fold<double>(
          0.0,
          (sum, item) => sum + (item['amount'] as double? ?? 0.0).abs(),
        );

    return ReportSummary(
      totalAmount: totalIncome,
      paidAmount: totalExpenses,
      unpaidAmount: totalIncome - totalExpenses,
      totalCount: data.length,
    );
  }
}

// Provider definition
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((
  ref,
) {
  return ReportsNotifier();
});
