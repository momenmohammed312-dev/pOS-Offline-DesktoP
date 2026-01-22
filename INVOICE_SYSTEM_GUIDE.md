# 📋 دليل نظام الفواتير - Invoice System Guide

## 🛠️ أولاً: تعديل جدول الفواتير في Drift
### ✅ الحالة الحالية - Current Status
```dart
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()(); // Primary key
  TextColumn get invoiceNumber => text().withLength(min: 1, max: 255)();
  TextColumn get customerId => text().nullable()(); // Link to customer table
  TextColumn get customerName => text().withLength(min: 1, max: 255)();
  TextColumn get customerContact => text().withLength(min: 1, max: 255)(); // مطلوب الآن
  TextColumn get customerAddress => text().nullable()();
  TextColumn get paymentMethod => text().nullable()(); // مهم جداً
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  
  @override
  Set<Column> get primaryKey => {id}; // استخدام auto-increment
}
```

### 🔄 التحديثات المطلوبة - Required Updates
1. **customerContact** أصبح حقل مطلوب (required)
2. **primaryKey** يستخدم id بدلاً من invoiceNumber
3. **paymentMethod** مهم جداً للطباعة والتصدير

---

## 🔄 ثانياً: إضافة migration لقاعدة البيانات موجودة
### ✅ Migration Strategy
```dart
@override
int get schemaVersion => 10;

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      // إضافة الأعمدة الجديدة - Add new columns
      await m.addColumn(invoices, invoices.customerId);
      await m.addColumn(invoices, invoices.customerContact);
      await m.addColumn(invoices, invoices.paymentMethod);
    }
  },
);
```

---

## 🛠️ ثالثاً: إدخال الفاتورة بدون أخطاء
### ✅ الطريقة الصحيحة - Correct Method
```dart
// إنشاء فاتورة جديدة - Create new invoice
final invoiceId = await db.invoiceDao.insertInvoice(
  InvoicesCompanion.insert(
    invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    customerId: const Value('CUST001'),
    customerName: const Value('أحمد محمد'),
    customerContact: const Value('01234567890'), // مطلوب الآن
    customerAddress: const Value('القاهرة - المهندسين'),
    paymentMethod: const Value('cash'), // cash, credit, visa, bank
    totalAmount: const Value(1500.50),
    paidAmount: const Value(1500.50),
    date: Value(DateTime.now()),
    status: const Value('paid'),
  ),
);
```

### 🎯 أنواع العملاء - Customer Types
```dart
// عميل كاش - Cash Customer
await db.invoiceDao.insertInvoice(
  InvoicesCompanion.insert(
    paymentMethod: const Value('cash'),
    paidAmount: const Value(1500.50), // مدفوع بالكامل
    status: const Value('paid'),
  ),
);

// عميل آجل - Credit Customer  
await db.invoiceDao.insertInvoice(
  InvoicesCompanion.insert(
    paymentMethod: const Value('credit'),
    paidAmount: const Value(200.0), // مدفوع جزئياً
    status: const Value('partial'), // حالة جزئية
  ),
);
```

---

## 🖨️ رابعاً: طباعة الفاتورة أو تصديرها
### ✅ الطباعة الحرارية - Thermal Printing
```dart
await _printerService.printInvoice(
  invoice: {
    'id': invoice.id,
    'customerName': invoice.customerName,
    'date': invoice.date,
    'totalAmount': invoice.totalAmount,
    'paymentMethod': 'cash',
  },
  items: [],
  paymentMethod: 'cash',
  isThermal: true,
  ledgerDao: widget.db.ledgerDao,
);
```

### 📄 الطباعة A4 والتصدير PDF - A4 Printing & PDF Export
```dart
final font = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));

await exportService.exportToPDF(
  title: 'فاتورة - ${customer.name}',
  data: data,
  headers: ['رقم الفاتورة', 'العميل', 'التاريخ', 'الإجمالي'],
  columns: ['رقم الفاتورة', 'العميل', 'التاريخ', 'الإجمالي'],
  fileName: 'invoice_${customer.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
);

// استخدام الخط العربي - Use Arabic font
pw.Text('العميل: ${invoice.customerName}', style: pw.TextStyle(font: font)),
pw.Text('المبلغ: ${invoice.totalAmount} ج.م', style: pw.TextStyle(font: font)),
pw.Text('طريقة الدفع: ${invoice.paymentMethod}', style: pw.TextStyle(font: font)),
```

---

## 🎯 خامساً: أمثلة عملية متكاملة
### ✅ مثال إنشاء فاتورة كاملة
```dart
// 1. إنشاء الفاتورة
final invoiceId = await db.invoiceDao.insertInvoice(
  InvoicesCompanion.insert(
    invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    customerId: const Value('CUST001'),
    customerName: const Value('أحمد محمد'),
    customerContact: const Value('01234567890'),
    customerAddress: const Value('القاهرة - المهندسين'),
    paymentMethod: const Value('cash'),
    totalAmount: const Value(1500.50),
    paidAmount: const Value(1500.50),
    date: Value(DateTime.now()),
    status: const Value('paid'),
  ),
);

// 2. إضافة البنود (منتجات)
final items = [
  InvoiceItemsCompanion.insert(
    invoiceId: Value(invoiceId),
    productId: const Value('PROD001'),
    quantity: const Value(2),
    price: const Value(500.0),
  ),
];

for (final item in items) {
  await db.invoiceDao.insertInvoiceItem(item);
}

// 3. التحقق من الفاتورة
final createdInvoice = (await db.invoiceDao.getAllInvoices())
    .firstWhere((inv) => inv.id == invoiceId);

print('✅ فاتورة #: ${createdInvoice.invoiceNumber}');
print('👤 العميل: ${createdInvoice.customerName}');
print('💰 المبلغ: ${createdInvoice.totalAmount} ج.م');
print('📅 التاريخ: ${createdInvoice.date}');
print('📊 الحالة: ${createdInvoice.status}');
```

---

## 🚀 خطوات التنفيذ - Implementation Steps
### 1. تحديث قاعدة البيانات
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. تشغيل التطبيق
```bash
flutter run -d windows
```

### 3. التحقق من الخطأ
```bash
flutter analyze --no-pub
```

---

## 🎯 النتائج المتوقعة - Expected Results
- ✅ **لا توجد أخطاء compilation** - No compilation errors
- ✅ **الخط العربي يعمل** - Arabic font works correctly
- ✅ **الفواتير تنشأ وتطبع** - Invoices create and print properly
- ✅ **قاعدة البيانات محدثة** - Database schema updated

---

## 📞 استكشاف الأخطاء الشائعة - Common Issues Debugging

### ❌ خطأ: "No element"
**السبب**: استخدام `firstWhere` بدون `orElse`
**الحل**: 
```dart
final customer = _customers.cast<Customer?>().firstWhere(
  (c) => c?.id == invoice.customerId,
  orElse: () => null,
);
if (customer != null) {
  _exportInvoiceToPDF(invoice, customer);
}
```

### ❌ خطأ: Font fallback warnings
**السبب**: عدم تحديد خط عربي مناسب
**الحل**:
```dart
// في main.dart
theme: AppTheme.getLightTheme().copyWith(
  textTheme: AppTheme.getLightTheme().textTheme.apply(
    fontFamily: 'Arabic', // من pubspec.yaml
    bodyColor: Colors.white,
  ),
),
```

### ❌ خطأ: Value type mismatch
**السبب**: عدم استخدام `Value()` بشكل صحيح
**الحل**:
```dart
// استخدام InvoicesCompanion.insert للحقول المطلوبة
InvoicesCompanion.insert(
  customerName: const Value('أحمد محمد'), // نص مباشر
  customerContact: const Value('01234567890'), // مطلوب الآن
  paymentMethod: const Value('cash'), // مهم جداً
)
```

---

## 📞 ملاحظات هامة - Important Notes

1. **دائماً استخدم `InvoicesCompanion.insert`** للحقول المطلوبة
2. **تأكد من وجود العميل** قبل استخدام `firstWhere`
3. **استخدم الخط العربي المحدد** في `pubspec.yaml`
4. **تجنب التعديل المباشر** للبيانات الموجودة
5. **استخدم `mounted` checks** للعمليات غير المتزامنة

---

## ✅ الخلاصة - Summary
النظام الآن جاهز لإنشاء وإدارة الفواتير بشكل كامل وصحيح! 🎉
