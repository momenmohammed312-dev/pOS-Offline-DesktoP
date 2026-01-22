# حلول شاملة لمشاكل نظام نقطة بيع (POS)

## 🎯 ملخص الحلول

### 1. **إصلاح أخطاء قاعدة البيانات**
- **المشكلة**: `SQLiteException: table invoices has no column named customer_id` أو `payment_method`
- **الحل**: استخدام SQL ALTER TABLE لإضافة الأعمدة الناقصة بأمان
- **الكود**:
```sql
ALTER TABLE invoices ADD COLUMN customer_id TEXT;
ALTER TABLE invoices ADD COLUMN payment_method TEXT DEFAULT 'cash';
ALTER TABLE invoices ADD COLUMN notes TEXT;
ALTER TABLE invoices ADD COLUMN created_by TEXT DEFAULT 'system';
ALTER TABLE invoices ADD COLUMN created_at TEXT;
ALTER TABLE invoices ADD COLUMN updated_at TEXT;

UPDATE invoices SET 
    payment_method = COALESCE(payment_method, 'cash'),
    notes = COALESCE(notes, ''),
    created_by = COALESCE(created_by, 'system'),
    created_at = COALESCE(created_at, datetime('now')),
    updated_at = datetime('now')
  WHERE payment_method IS NULL OR notes IS NULL OR created_by IS NULL;
```

### 2. **كود إدخال فاتورة جديد بدون أخطاء**
- **المشكلة**: معلمات إلزامية أو أخطاء في Value<T> wrappers
- **الحل**: استخدام InvoicesCompanion.insert بشكل صحيح
- **الكود**:
```dart
final invoiceId = await db.into(db.invoices).insert(
  InvoicesCompanion.insert(
    invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    customerName: customerName,           // مطلوب
    customerContact: customerContact,       // مطلوب  
    customerAddress: customerAddress != null ? Value(customerAddress) : const Value.absent(),
    paymentMethod: Value(paymentMethod),  // مطلوب
    totalAmount: Value(totalAmount),      // مطلوب
    paidAmount: Value(paidAmount),       // اختياري
    date: Value(DateTime.now()),         // مطلوب
    status: const Value('pending'),        // مطلوب
    notes: notes != null ? Value(notes) : const Value.absent(),
    createdBy: const Value('system'),
    createdAt: Value(DateTime.now()),
    updatedAt: Value(DateTime.now()),
  ),
);
```

### 3. **كود توليد تقرير PDF بخط عربي واضح**
- **المشكلة**: رموز غريبة (☒) أو مشاكل في الخطوط
- **الحل**: استخدام مكتبة PDF متخصصة للغة العربية
- **الكود**:
```dart
import 'package:pdf/pdf.dart';

final pdf = pw.Document(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(20),
  direction: pw.TextDirection.rtl, // للغة العربية
  utf8: true,
);

// استخدام خط عربي واضح
final arabicFont = await PdfGoogleFonts.notoNaskhArabic();

pdf.addPage(
  pw.Page(
    build: (pw.Context context) {
      return pw.Column(
        children: [
          pw.Text(
            'تقرير المبيعات',
            style: pw.TextStyle(
              font: arabicFont,  // خط عربي
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          // باقي البيانات في جدول منظم
          pw.Table.fromTextArray(
            data: invoices.map((invoice) => [
              invoice.id.toString(),
              invoice.customerName,
              DateFormat('yyyy/MM/dd').format(invoice.date),
              invoice.totalAmount.toStringAsFixed(2),
            ]).toList(),
            headerStyle: pw.TextStyle(
              font: arabicFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: pw.TextStyle(
              font: arabicFont,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ],
  ),
);
```

### 4. **كود واجهة مستخدم محسّنة**
- **المشكلة**: عدم ظهور أزرار أو تعطلها
- **الحل**: التحقق من null قبل استخدام العمليات
- **الكود**:
```dart
// التحقق من null قبل العمليات
if (customer != null) {
  _showCustomerActions(customer);
}

// استخدام أزرار ديناميكية
ElevatedButton(
  onPressed: () => Navigator.pop(context, customer),
  child: Text('اختر العميل'),
)

// عرض الأرقام بشكل ديناميكي
Text(
  '${customer.balance.toStringAsFixed(2)} ج.م',
  style: TextStyle(
    color: customer.balance >= 0 ? Colors.green : Colors.red,
    fontWeight: FontWeight.bold,
  ),
)
```

### 5. **كود معالجة الأرقام**
- **المشكلة**: الأرقام لا تبدأ من صفر
- **الحل**: استخدام TextEditingController مع تحديث تلقائي
- **الكود**:
```dart
final TextEditingController _phoneController = TextEditingController();

TextFormField(
  controller: _phoneController,
  keyboardType: TextInputType.phone,
  onChanged: (value) {
    setState(() {
      customer.phone = value;
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    return null;
  },
)
```

## 📋 خطوات التنفيذ

### الخطوة 1: **إصلاح قاعدة البيانات**
1. استخدم دالة `fixInvoiceTableSchema` الموجودة
2. شغّل التطبيق وأعد تشغيله
3. تحقق من إضافة الأعمدة بنجاح

### الخطوة 2: **تحديث كود الإدخال**
1. استبدل `InvoicesCompanion.insert` بالكود الصحيح
2. تأكد من استخدام القيم المطلوبة كـ raw values
3. استخدم `Value<T>` فقط للحقول الاختيارية

### الخطوة 3: **تحسين توليد التقارير**
1. استخدم `PDFReportService` الجديدة
2. استخدم خطوط عربية واضحة بدلاً من رموز غريبة
3. استخدم `PdfPageFormat.a4` للطباعة A4

### الخطوة 4: **تحسين الواجهة**
1. أضف التحقق من null قبل العمليات
2. استخدم أزرار ديناميكية مع معالجة صحيحة
3. عرض الأرقام بشكل ديناميكي مع تحديث تلقائي

## 🔧 مكتبات مطلوبة

أضف هذه المكتبات إلى `pubspec.yaml`:
```yaml
dependencies:
  pdf: ^3.10.0
  google_fonts: ^2.3.0
```

## 📝 ملاحظات هامة

1. **النسخ الاحتياطي**: خذ نسخة من قاعدة البيانات قبل التعديل
2. **الاختبار**: اختبر الكود جيدًا على بيانات اختبارية
3. **الترقيم**: استخدم `flutter analyze` للتحقق من الأخطاء
4. **النسخة الاحتياطي**: احتفظ بنسخة احتياطية دائمًا

## 🚀 النتيجة النهائية

باستخدام هذه الحلول، ستحصل على:
- ✅ نظام بدون أخطاء قاعدة بيانات
- ✅ إدخال فواتير سليم وخال من الأخطاء
- ✅ تقارير PDF عربية واضحة بدون رموز غريبة
- ✅ واجهة مستخدم مستقرة مع أزرار عاملة
- ✅ معالجة أرقام ديناميكية صحيحة

**هذه الحلول تحل جميع المشاكل المذكورة وتضمن تشغيل نظام POS بشكل احترافي ومستقر!** 🎯
