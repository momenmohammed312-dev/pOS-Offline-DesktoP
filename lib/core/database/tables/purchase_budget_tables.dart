import 'package:drift/drift.dart';
import 'enhanced_purchase_tables.dart';

@DataClassName('PurchaseBudget')
class PurchaseBudgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get budgetName => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get totalBudget => real()();
  RealColumn get spentAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real()();
  TextColumn get budgetType => text()(); // monthly, quarterly, yearly, project
  TextColumn get status => text().withDefault(
    const Constant('active'),
  )(); // active, completed, cancelled
  IntColumn get departmentId =>
      integer().nullable()(); // For department-specific budgets
  IntColumn get managerId => integer().nullable()(); // Budget manager
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BudgetCategory')
class BudgetCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId =>
      integer().references(PurchaseBudgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryName => text()();
  RealColumn get allocatedAmount => real()();
  RealColumn get spentAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real()();
  TextColumn get categoryType =>
      text()(); // materials, services, equipment, maintenance
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BudgetTransaction')
class BudgetTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId =>
      integer().references(PurchaseBudgets, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId =>
      integer().references(BudgetCategories, #id).nullable()();
  IntColumn get purchaseId =>
      integer().references(EnhancedPurchases, #id).nullable()();
  TextColumn get transactionType => text()(); // purchase, adjustment, transfer
  RealColumn get amount => real()();
  TextColumn get description => text()();
  TextColumn get referenceNumber =>
      text().nullable()(); // Purchase number, etc.
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get userId => integer().nullable()(); // Who made the transaction
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BudgetAlert')
class BudgetAlerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId =>
      integer().references(PurchaseBudgets, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId =>
      integer().references(BudgetCategories, #id).nullable()();
  TextColumn get alertType => text()(); // threshold, overspend, deadline
  RealColumn get thresholdPercentage => real()(); // e.g., 80.0 for 80%
  TextColumn get alertLevel => text()(); // info, warning, critical
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get notificationMethod => text()(); // email, sms, in_app
  DateTimeColumn get lastTriggered => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
