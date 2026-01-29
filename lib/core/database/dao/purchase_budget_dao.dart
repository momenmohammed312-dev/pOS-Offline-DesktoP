import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/purchase_budget_tables.dart';

part 'purchase_budget_dao.g.dart';

@DriftAccessor(
  tables: [PurchaseBudgets, BudgetCategories, BudgetTransactions, BudgetAlerts],
)
class PurchaseBudgetDao extends DatabaseAccessor<AppDatabase>
    with _$PurchaseBudgetDaoMixin {
  PurchaseBudgetDao(super.db);

  // Budget operations
  Future<List<PurchaseBudget>> getAllBudgets() =>
      select(db.purchaseBudgets).get();

  Stream<List<PurchaseBudget>> watchAllBudgets() =>
      select(db.purchaseBudgets).watch();

  Future<List<PurchaseBudget>> getActiveBudgets() => (select(
    db.purchaseBudgets,
  )..where((tbl) => tbl.status.equals('active'))).get();

  Future<PurchaseBudget?> getBudgetById(int id) => (select(
    db.purchaseBudgets,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<void> insertBudget(PurchaseBudgetsCompanion budget) =>
      into(db.purchaseBudgets).insert(budget);

  Future<void> updateBudget(PurchaseBudget budget) =>
      update(db.purchaseBudgets).replace(budget);

  Future<void> deleteBudget(int id) =>
      (delete(db.purchaseBudgets)..where((tbl) => tbl.id.equals(id))).go();

  // Budget Category operations
  Future<List<BudgetCategory>> getCategoriesByBudget(int budgetId) => (select(
    db.budgetCategories,
  )..where((tbl) => tbl.budgetId.equals(budgetId))).get();

  Future<void> insertCategory(BudgetCategoriesCompanion category) =>
      into(db.budgetCategories).insert(category);

  Future<void> updateCategory(BudgetCategory category) =>
      update(db.budgetCategories).replace(category);

  Future<void> deleteCategory(int id) =>
      (delete(db.budgetCategories)..where((tbl) => tbl.id.equals(id))).go();

  // Budget Transaction operations
  Future<List<BudgetTransaction>> getTransactionsByBudget(int budgetId) =>
      (select(db.budgetTransactions)
            ..where((tbl) => tbl.budgetId.equals(budgetId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.transactionDate)]))
          .get();

  Future<void> insertTransaction(BudgetTransactionsCompanion transaction) =>
      into(db.budgetTransactions).insert(transaction);

  // Budget Alert operations
  Future<List<BudgetAlert>> getAlertsByBudget(int budgetId) =>
      (select(db.budgetAlerts)..where(
            (tbl) => tbl.budgetId.equals(budgetId) & tbl.isActive.equals(true),
          ))
          .get();

  Future<void> insertAlert(BudgetAlertsCompanion alert) =>
      into(db.budgetAlerts).insert(alert);

  Future<void> updateAlert(BudgetAlert alert) =>
      update(db.budgetAlerts).replace(alert);

  // Advanced budget operations
  Future<void> createBudgetWithCategories({
    required String budgetName,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    required double totalBudget,
    required String budgetType,
    required List<BudgetCategoriesCompanion> categories,
    String? notes,
  }) async {
    return transaction(() async {
      // Insert budget
      final budgetId = await into(db.purchaseBudgets).insert(
        PurchaseBudgetsCompanion.insert(
          budgetName: budgetName,
          description: Value(description),
          startDate: startDate,
          endDate: endDate,
          totalBudget: totalBudget,
          remainingAmount: totalBudget,
          budgetType: budgetType,
          notes: Value(notes),
        ),
      );

      // Insert categories
      for (final category in categories) {
        await into(
          db.budgetCategories,
        ).insert(category.copyWith(budgetId: Value(budgetId)));
      }

      // Create default alerts
      await _createDefaultAlerts(budgetId);
    });
  }

  Future<void> _createDefaultAlerts(int budgetId) async {
    final alerts = [
      BudgetAlertsCompanion.insert(
        budgetId: budgetId,
        alertType: 'threshold',
        thresholdPercentage: 80.0,
        alertLevel: 'warning',
        notificationMethod: 'in_app',
      ),
      BudgetAlertsCompanion.insert(
        budgetId: budgetId,
        alertType: 'threshold',
        thresholdPercentage: 95.0,
        alertLevel: 'critical',
        notificationMethod: 'in_app',
      ),
      BudgetAlertsCompanion.insert(
        budgetId: budgetId,
        alertType: 'overspend',
        thresholdPercentage: 100.0,
        alertLevel: 'critical',
        notificationMethod: 'in_app',
      ),
    ];

    for (final alert in alerts) {
      await into(db.budgetAlerts).insert(alert);
    }
  }

  Future<void> recordPurchaseTransaction({
    required int budgetId,
    required int purchaseId,
    required double amount,
    required String purchaseNumber,
    int? categoryId,
  }) async {
    return transaction(() async {
      // Insert transaction
      await insertTransaction(
        BudgetTransactionsCompanion.insert(
          budgetId: budgetId,
          categoryId: Value(categoryId),
          purchaseId: Value(purchaseId),
          transactionType: 'purchase',
          amount: amount,
          description: 'شراء - $purchaseNumber',
          referenceNumber: Value(purchaseNumber),
          transactionDate: DateTime.now(),
        ),
      );

      // Update budget spent amount
      final budget = await getBudgetById(budgetId);
      if (budget != null) {
        final newSpentAmount = budget.spentAmount + amount;
        final newRemainingAmount = budget.totalBudget - newSpentAmount;

        await updateBudget(
          budget.copyWith(
            spentAmount: newSpentAmount,
            remainingAmount: newRemainingAmount,
            updatedAt: DateTime.now(),
          ),
        );

        // Update category if provided
        if (categoryId != null) {
          final category = await (select(
            db.budgetCategories,
          )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();

          if (category != null) {
            final newCategorySpent = category.spentAmount + amount;
            final newCategoryRemaining =
                category.allocatedAmount - newCategorySpent;

            await updateCategory(
              category.copyWith(
                spentAmount: newCategorySpent,
                remainingAmount: newCategoryRemaining,
              ),
            );
          }
        }

        // Check for alerts
        await _checkBudgetAlerts(budgetId, newSpentAmount, budget.totalBudget);
      }
    });
  }

  Future<void> _checkBudgetAlerts(
    int budgetId,
    double spentAmount,
    double totalBudget,
  ) async {
    final alerts = await getAlertsByBudget(budgetId);
    final spentPercentage = totalBudget > 0
        ? (spentAmount / totalBudget) * 100
        : 0.0;

    for (final alert in alerts) {
      if (alert.alertType == 'threshold' &&
          spentPercentage >= alert.thresholdPercentage) {
        await _triggerAlert(alert, spentPercentage);
      } else if (alert.alertType == 'overspend' && spentAmount > totalBudget) {
        await _triggerAlert(alert, spentPercentage);
      }
    }
  }

  Future<void> _triggerAlert(BudgetAlert alert, double spentPercentage) async {
    // Update last triggered time
    await updateAlert(
      alert.copyWith(
        lastTriggered: Value(DateTime.now()),
        updatedAt: DateTime.now(),
      ),
    );

    // Here you would implement actual notification logic
    // For now, we just log the alert
    developer.log(
      'Budget Alert Triggered: ${alert.alertLevel} - ${spentPercentage.toStringAsFixed(1)}% spent',
    );
  }

  // Budget statistics and reporting
  Future<Map<String, dynamic>> getBudgetStatistics() async {
    final budgets = await getAllBudgets();
    final activeBudgets = await getActiveBudgets();

    final totalBudgets = budgets.fold(0.0, (sum, b) => sum + b.totalBudget);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final totalRemaining = budgets.fold(
      0.0,
      (sum, b) => sum + b.remainingAmount,
    );

    final overspentBudgets = budgets
        .where((b) => b.spentAmount > b.totalBudget)
        .length;
    final nearLimitBudgets = budgets.where((b) {
      final percentage = b.totalBudget > 0
          ? (b.spentAmount / b.totalBudget) * 100
          : 0.0;
      return percentage >= 80 && percentage < 100;
    }).length;

    return {
      'totalBudgets': budgets.length,
      'activeBudgets': activeBudgets.length,
      'totalBudgetAmount': totalBudgets,
      'totalSpentAmount': totalSpent,
      'totalRemainingAmount': totalRemaining,
      'overspentBudgets': overspentBudgets,
      'nearLimitBudgets': nearLimitBudgets,
      'averageSpentPercentage': totalBudgets > 0
          ? (totalSpent / totalBudgets) * 100
          : 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getBudgetPerformanceReport() async {
    final budgets = await getAllBudgets();

    return budgets.map((budget) {
      final spentPercentage = budget.totalBudget > 0
          ? (budget.spentAmount / budget.totalBudget) * 100
          : 0.0;

      final daysRemaining = budget.endDate.difference(DateTime.now()).inDays;
      final status = _getBudgetStatus(budget, spentPercentage);

      return {
        'budget': budget,
        'spentPercentage': spentPercentage,
        'daysRemaining': daysRemaining,
        'status': status,
        'isOverBudget': budget.spentAmount > budget.totalBudget,
        'isNearLimit': spentPercentage >= 80 && spentPercentage < 100,
      };
    }).toList();
  }

  String _getBudgetStatus(PurchaseBudget budget, double spentPercentage) {
    if (budget.status == 'completed') return 'مكتمل';
    if (budget.status == 'cancelled') return 'ملغي';
    if (budget.spentAmount > budget.totalBudget) return 'تجاوز الميزانية';
    if (spentPercentage >= 95) return 'قريب من النفاد';
    if (spentPercentage >= 80) return 'تحذير';
    if (spentPercentage >= 50) return 'متوسط';
    return 'آمن';
  }

  Future<List<Map<String, dynamic>>> getCategorySpendingReport(
    int budgetId,
  ) async {
    final categories = await getCategoriesByBudget(budgetId);

    return categories.map((category) {
      final spentPercentage = category.allocatedAmount > 0
          ? (category.spentAmount / category.allocatedAmount) * 100
          : 0.0;

      return {
        'category': category,
        'spentPercentage': spentPercentage,
        'isOverBudget': category.spentAmount > category.allocatedAmount,
        'isNearLimit': spentPercentage >= 80 && spentPercentage < 100,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> getMonthlySpendingTrend(int budgetId) async {
    final transactions = await getTransactionsByBudget(budgetId);
    final now = DateTime.now();

    // Group transactions by month
    final Map<String, double> monthlySpending = {};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] = 0.0;
    }

    for (final transaction in transactions) {
      final monthKey =
          '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}';
      if (monthlySpending.containsKey(monthKey)) {
        monthlySpending[monthKey] =
            (monthlySpending[monthKey] ?? 0.0) + transaction.amount;
      }
    }

    return {
      'monthlySpending': monthlySpending,
      'totalTransactions': transactions.length,
      'averageMonthlySpending': monthlySpending.values.isNotEmpty
          ? monthlySpending.values.reduce((a, b) => a + b) /
                monthlySpending.values.length
          : 0.0,
    };
  }

  // Budget management operations
  Future<void> adjustBudgetAmount(
    int budgetId,
    double newAmount,
    String reason,
  ) async {
    return transaction(() async {
      final budget = await getBudgetById(budgetId);
      if (budget == null) {
        throw Exception('الميزانية غير موجودة');
      }

      final oldAmount = budget.totalBudget;
      final difference = newAmount - oldAmount;

      await updateBudget(
        budget.copyWith(
          totalBudget: newAmount,
          remainingAmount: budget.remainingAmount + difference,
          updatedAt: DateTime.now(),
        ),
      );

      // Record adjustment transaction
      await insertTransaction(
        BudgetTransactionsCompanion.insert(
          budgetId: budgetId,
          transactionType: 'adjustment',
          amount: difference,
          description: 'تعديل الميزانية: $reason',
          transactionDate: DateTime.now(),
        ),
      );
    });
  }

  Future<void> transferBudgetAmount(
    int fromBudgetId,
    int toBudgetId,
    double amount,
    String reason,
  ) async {
    return transaction(() async {
      // Reduce source budget
      await adjustBudgetAmount(
        fromBudgetId,
        (await getBudgetById(fromBudgetId))!.totalBudget - amount,
        'تحويل للميزانية: $reason',
      );

      // Increase target budget
      await adjustBudgetAmount(
        toBudgetId,
        (await getBudgetById(toBudgetId))!.totalBudget + amount,
        'تحويل من الميزانية: $reason',
      );

      // Record transfer transaction
      await insertTransaction(
        BudgetTransactionsCompanion.insert(
          budgetId: fromBudgetId,
          transactionType: 'transfer',
          amount: -amount,
          description: 'تحويل للميزانية $toBudgetId: $reason',
          transactionDate: DateTime.now(),
        ),
      );

      await insertTransaction(
        BudgetTransactionsCompanion.insert(
          budgetId: toBudgetId,
          transactionType: 'transfer',
          amount: amount,
          description: 'تحويل من الميزانية $fromBudgetId: $reason',
          transactionDate: DateTime.now(),
        ),
      );
    });
  }

  Future<void> closeBudget(int budgetId, String reason) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('الميزانية غير موجودة');
    }

    await updateBudget(
      budget.copyWith(status: 'completed', updatedAt: DateTime.now()),
    );

    // Deactivate all alerts
    final alerts = await getAlertsByBudget(budgetId);
    for (final alert in alerts) {
      await updateAlert(
        alert.copyWith(isActive: false, updatedAt: DateTime.now()),
      );
    }
  }

  Future<void> cancelBudget(int budgetId, String reason) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('الميزانية غير موجودة');
    }

    await updateBudget(
      budget.copyWith(status: 'cancelled', updatedAt: DateTime.now()),
    );

    // Deactivate all alerts
    final alerts = await getAlertsByBudget(budgetId);
    for (final alert in alerts) {
      await updateAlert(
        alert.copyWith(isActive: false, updatedAt: DateTime.now()),
      );
    }
  }
}
