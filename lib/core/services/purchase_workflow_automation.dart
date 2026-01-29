import 'dart:developer' as developer;

import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../database/dao/enhanced_purchase_dao.dart';
import '../database/dao/purchase_budget_dao.dart';
import '../database/dao/product_dao.dart';
import 'notification_service.dart';

/// Service for automating purchase workflows and budget management
class PurchaseWorkflowAutomation {
  final AppDatabase _database;
  final EnhancedPurchaseDao _purchaseDao;
  late final PurchaseBudgetDao _budgetDao;
  late final ProductDao _productDao;
  final NotificationService _notificationService;

  PurchaseWorkflowAutomation(this._database)
    : _purchaseDao = EnhancedPurchaseDao(_database),
      _notificationService = NotificationService() {
    _budgetDao = PurchaseBudgetDao(_database);
    _productDao = ProductDao(_database);
  }

  /// Automated purchase order creation based on inventory levels
  Future<void> createRecurringPurchaseOrder({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    required String frequency, // daily, weekly, monthly
    required int priority,
  }) async {
    try {
      developer.log(
        'Creating recurring purchase order for supplier $supplierId',
      );

      // Get supplier information
      final supplier = await _purchaseDao.getSupplierById(supplierId);
      if (supplier == null) {
        _notificationService.addNotification(
          title: 'Purchase Order Failed',
          message: 'Supplier with ID $supplierId not found',
          type: NotificationType.purchase,
        );
        return;
      }

      // Create purchase invoice instead of purchase order (using existing system)
      final purchaseNumber = 'AUTO-${DateTime.now().millisecondsSinceEpoch}';
      final subtotal = items.fold<double>(0.0, (sum, item) {
        return sum + (item['quantity'] as int) * (item['unitPrice'] as double);
      });

      // Create purchase items
      final purchaseItems = items.asMap().entries.map((entry) {
        final item = entry.value;
        return EnhancedPurchaseItemsCompanion(
          productId: drift.Value(item['productId'] as int),
          productName: drift.Value(item['productName'] as String),
          productBarcode: item['productBarcode'] != null
              ? drift.Value(item['productBarcode'] as String)
              : const drift.Value.absent(),
          unit: drift.Value(item['unit'] as String),
          quantity: drift.Value(item['quantity'] as int),
          unitPrice: drift.Value(item['unitPrice'] as double),
          totalPrice: drift.Value(
            (item['quantity'] as int) * (item['unitPrice'] as double),
          ),
          sortOrder: drift.Value(entry.key),
        );
      }).toList();

      // Save the automated purchase
      await _purchaseDao.createCompletePurchase(
        purchaseNumber: purchaseNumber,
        supplierId: supplierId,
        supplierName: supplier.businessName,
        supplierPhone: supplier.phone,
        purchaseDate: DateTime.now(),
        subtotal: subtotal,
        totalAmount: subtotal,
        isCreditPurchase: true, // Automated purchases are typically on credit
        previousBalance: supplier.currentBalance,
        paidAmount: 0.0,
        remainingAmount: subtotal,
        paymentMethod: 'credit',
        notes:
            'Automated purchase order - Frequency: $frequency, Priority: $priority',
        items: purchaseItems,
      );

      _notificationService.addNotification(
        title: 'Automated Purchase Created',
        message:
            'Purchase order $purchaseNumber created for ${supplier.businessName}',
        type: NotificationType.purchase,
      );

      developer.log(
        'Automated purchase order created: $purchaseNumber for supplier $supplierId',
      );
    } catch (e) {
      developer.log('Error creating recurring purchase order: $e');
      _notificationService.addNotification(
        title: 'Purchase Order Error',
        message: 'Failed to create automated purchase order: $e',
        type: NotificationType.system,
      );
    }
  }

  /// Automated budget monitoring and alerts
  Future<void> monitorBudgetAlerts() async {
    try {
      final budgets = await _budgetDao.getAllBudgets();

      for (final budget in budgets) {
        final spentPercentage = budget.totalBudget > 0
            ? (budget.spentAmount / budget.totalBudget) * 100
            : 0.0;

        if (spentPercentage >= 80.0) {
          await _triggerBudgetAlert(budget, spentPercentage);
        }
      }
    } catch (e) {
      developer.log('Error monitoring budget alerts: $e');
    }
  }

  Future<void> _triggerBudgetAlert(
    dynamic budget,
    double spentPercentage,
  ) async {
    developer.log(
      'Budget Alert: ${budget.budgetName} - ${spentPercentage.toStringAsFixed(1)}% spent',
    );

    // Implement actual notification system
    String alertLevel = 'Warning';
    if (spentPercentage >= 100.0) {
      alertLevel = 'Critical';
    } else if (spentPercentage >= 90.0) {
      alertLevel = 'High';
    }

    _notificationService.addNotification(
      title: 'Budget Alert - $alertLevel',
      message:
          'Budget "${budget.budgetName}" is ${spentPercentage.toStringAsFixed(1)}% spent (${budget.spentAmount.toStringAsFixed(2)} of ${budget.totalBudget.toStringAsFixed(2)} ج.م)',
      type: NotificationType.budget,
    );
  }

  /// Automated supplier performance monitoring
  Future<void> monitorSupplierPerformance() async {
    try {
      final suppliers = await _purchaseDao.getAllSuppliers();

      for (final supplier in suppliers) {
        final purchases = await _purchaseDao.getPurchasesBySupplier(
          supplier.id,
        );

        // Implement returns tracking using existing purchase data
        // For now, just monitor purchase activity and returns based on negative quantities
        final totalPurchases = purchases.fold(
          0.0,
          (sum, p) => sum + p.totalAmount,
        );

        // Calculate returns (simplified: purchases with negative amounts or specific notes)
        final returns = purchases.where(
          (p) =>
              p.notes?.toLowerCase().contains('return') == true ||
              p.notes?.toLowerCase().contains('مرتجع') == true,
        );
        final totalReturns = returns.fold(0.0, (sum, r) => sum + r.totalAmount);

        // Check for high activity (could indicate need for better terms)
        if (totalPurchases > 10000.0) {
          await _triggerSupplierPerformanceAlert(
            supplier,
            'high_activity',
            totalPurchases,
          );
        }
      }
    } catch (e) {
      developer.log('Error monitoring supplier performance: $e');
    }
  }

  Future<void> _triggerSupplierPerformanceAlert(
    dynamic supplier,
    String alertType,
    double value,
  ) async {
    developer.log(
      'Supplier Performance Alert: ${supplier.businessName} - $alertType: ${value.toStringAsFixed(2)}',
    );

    // Implement actual notification system
    String alertMessage = '';
    switch (alertType) {
      case 'high_activity':
        alertMessage =
            'High purchase activity detected: ${value.toStringAsFixed(2)} ج.م in total purchases. Consider negotiating better terms.';
        break;
      case 'late_payments':
        alertMessage =
            'Payment delays detected. Current balance: ${value.toStringAsFixed(2)} ج.م';
        break;
      case 'quality_issues':
        alertMessage =
            'Quality issues detected. Returns: ${value.toStringAsFixed(2)} ج.م';
        break;
      default:
        alertMessage =
            'Supplier performance alert: $alertType - ${value.toStringAsFixed(2)}';
    }

    _notificationService.addNotification(
      title: 'Supplier Performance Alert',
      message: '${supplier.businessName}: $alertMessage',
      type: NotificationType.supplier,
    );
  }

  /// Automated inventory level monitoring
  Future<void> monitorInventoryLevels() async {
    try {
      final products = await _productDao.getAllProducts();

      for (final product in products) {
        // Check if product is running low (assuming stock is stored in product)
        // Note: This is a simplified implementation
        if (product.quantity < 10) {
          // Assuming quantity field exists
          await _triggerInventoryAlert(product, product.quantity);
        }
      }
    } catch (e) {
      developer.log('Error monitoring inventory levels: $e');
    }
  }

  Future<void> _triggerInventoryAlert(dynamic product, int currentStock) async {
    developer.log(
      'Inventory Alert: ${product.name} - Current stock: $currentStock',
    );

    // Implement actual notification system and automatic purchase order creation
    String alertLevel = 'Low Stock';
    if (currentStock <= 0) {
      alertLevel = 'Out of Stock';
    } else if (currentStock <= 5) {
      alertLevel = 'Critical Stock';
    }

    _notificationService.addNotification(
      title: 'Inventory Alert - $alertLevel',
      message:
          'Product "${product.name}" is running low. Current stock: $currentStock units',
      type: NotificationType.inventory,
    );

    // For critical stock levels, suggest creating a purchase order
    if (currentStock <= 5) {
      _notificationService.addNotification(
        title: 'Action Required',
        message:
            'Consider creating a purchase order for "${product.name}" immediately',
        type: NotificationType.purchase,
      );
    }
  }

  /// Automated purchase invoice processing
  Future<void> processPurchaseInvoices() async {
    try {
      final purchases = await _purchaseDao.getAllPurchases();

      for (final purchase in purchases) {
        // Check if purchase needs processing (e.g., payment due, inventory update)
        // Note: EnhancedPurchase doesn't have status field, so we check other conditions
        if (purchase.purchaseNumber.isEmpty) {
          await _processPurchaseInvoice(purchase);
        }
      }
    } catch (e) {
      developer.log('Error processing purchase invoices: $e');
    }
  }

  Future<void> _processPurchaseInvoice(dynamic purchase) async {
    developer.log('Processing purchase invoice: ${purchase.id}');

    // TODO: Implement actual invoice processing logic
    // For now, just log the processing
  }

  /// Run all automated workflows
  Future<void> runAllAutomations() async {
    try {
      await monitorBudgetAlerts();
      await monitorSupplierPerformance();
      await monitorInventoryLevels();
      await processPurchaseInvoices();

      developer.log('All purchase workflow automations completed successfully');
    } catch (e) {
      developer.log('Error running purchase workflow automations: $e');
    }
  }
}
