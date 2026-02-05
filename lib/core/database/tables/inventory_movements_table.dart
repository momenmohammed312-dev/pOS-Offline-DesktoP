import 'package:drift/drift.dart';
import 'product_table.dart';

/// Table for tracking inventory movements
/// جدول تتبع حركات المخزون
@DataClassName('InventoryMovement')
class InventoryMovements extends Table {
  /// Primary key
  /// المفتاح الأساسي
  IntColumn get id => integer().autoIncrement()();

  /// Product reference
  /// مرجع المنتج
  IntColumn get productId => integer().references(Products, #id)();

  /// Movement type: 'purchase', 'sale', 'adjustment', 'return', 'transfer'
  /// نوع الحركة: شراء، بيع، تعديل، مرتجع، نقل
  TextColumn get movementType => text()();

  /// Quantity moved (positive for in, negative for out)
  /// الكمية المتحركة (موجبة للداخل، سالبة للخارج)
  IntColumn get quantity => integer()();

  /// Unit cost at time of movement
  /// التكلفة الوحدوية وقت الحركة
  RealColumn get unitCost => real()();

  /// Total value of movement
  /// القيمة الإجمالية للحركة
  RealColumn get totalValue => real()();

  /// Date and time of movement
  /// تاريخ ووقت الحركة
  DateTimeColumn get movementDate => dateTime()();

  /// Reference document (invoice number, adjustment ID, etc.)
  /// المستند المرجعي (رقم الفاتورة، معرف التعديل، إلخ)
  TextColumn get reference => text()();

  /// Reference type: 'purchase_invoice', 'sale_invoice', 'manual_adjustment'
  /// نوع المرجع: فاتورة شراء، فاتورة بيع، تعديل يدوي
  TextColumn get referenceType => text()();

  /// Previous quantity before this movement
  /// الكمية السابقة قبل هذه الحركة
  IntColumn get previousQuantity => integer()();

  /// New quantity after this movement
  /// الكمية الجديدة بعد هذه الحركة
  IntColumn get newQuantity => integer()();

  /// User who performed the movement
  /// المستخدم الذي قام بالحركة
  TextColumn get performedBy => text().nullable()();

  /// Notes about the movement
  /// ملاحظات عن الحركة
  TextColumn get notes => text().nullable()();

  /// Created timestamp
  /// وقت الإنشاء
  DateTimeColumn get createdAt => dateTime()();

  /// Updated timestamp
  /// وقت التحديث
  DateTimeColumn get updatedAt => dateTime()();
}
