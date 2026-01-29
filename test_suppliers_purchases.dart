import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'lib/core/database/app_database.dart';
import 'lib/core/database/dao/enhanced_purchase_dao.dart';

/// سكريبت اختبار شامل لنظام الموردين والمشتريات
Future<void> main() async {
  debugPrint('=' * 60);
  debugPrint('اختبار نظام الموردين والمشتريات');
  debugPrint('=' * 60);
  debugPrint('');

  AppDatabase? database;
  try {
    // إنشاء قاعدة البيانات
    debugPrint('📦 جاري إنشاء قاعدة البيانات...');
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(
      dbFolder.path,
      'pos_offline_desktop_database',
      'pos_offline_desktop_database.sqlite',
    );

    // التأكد من وجود المجلد
    final dbDir = Directory(p.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    database = AppDatabase(
      LazyDatabase(() async {
        return NativeDatabase(File(dbPath));
      }),
    );

    debugPrint('✅ تم إنشاء قاعدة البيانات بنجاح');
    debugPrint('   المسار: $dbPath');
    debugPrint('');

    // اختبار 1: التحقق من وجود الجداول
    debugPrint('🔍 اختبار 1: التحقق من وجود الجداول...');
    await _testTablesExist(database);
    debugPrint('');

    // اختبار 2: إضافة مورد جديد
    debugPrint('👤 اختبار 2: إضافة مورد جديد...');
    final supplierId = await _testAddSupplier(database);
    debugPrint('');

    // اختبار 3: قراءة الموردين
    debugPrint('📋 اختبار 3: قراءة قائمة الموردين...');
    await _testGetSuppliers(database);
    debugPrint('');

    // اختبار 4: إضافة عملية شراء
    debugPrint('🛒 اختبار 4: إضافة عملية شراء...');
    final purchaseId = await _testAddPurchase(database, supplierId);
    debugPrint('');

    // اختبار 5: قراءة المشتريات
    debugPrint('📊 اختبار 5: قراءة قائمة المشتريات...');
    await _testGetPurchases(database);
    debugPrint('');

    // اختبار 6: تحديث رصيد المورد
    debugPrint('💰 اختبار 6: تحديث رصيد المورد...');
    await _testUpdateSupplierBalance(database, supplierId);
    debugPrint('');

    // اختبار 7: إضافة دفعة للمورد
    debugPrint('💳 اختبار 7: إضافة دفعة للمورد...');
    await _testAddPayment(database, supplierId);
    debugPrint('');

    // اختبار 8: الإحصائيات
    debugPrint('📈 اختبار 8: حساب الإحصائيات...');
    await _testStatistics(database);
    debugPrint('');

    // اختبار 9: البحث عن الموردين
    debugPrint('🔎 اختبار 9: البحث عن الموردين...');
    await _testSearchSuppliers(database);
    debugPrint('');

    // اختبار 10: الحصول على مشتريات مورد معين
    debugPrint('📦 اختبار 10: الحصول على مشتريات مورد معين...');
    await _testGetPurchasesBySupplier(database, supplierId);
    debugPrint('');

    debugPrint('=' * 60);
    debugPrint('✅ جميع الاختبارات اكتملت بنجاح!');
    debugPrint('=' * 60);
  } catch (e, stackTrace) {
    debugPrint('');
    debugPrint('❌ خطأ في الاختبار:');
    debugPrint('   الخطأ: $e');
    debugPrint('   StackTrace: $stackTrace');
    debugPrint('');
  } finally {
    await database?.close();
    debugPrint('🔒 تم إغلاق قاعدة البيانات');
  }
}

Future<void> _testTablesExist(AppDatabase db) async {
  try {
    // محاولة الوصول للجداول
    final dao = EnhancedPurchaseDao(db);

    // محاولة قراءة من جدول الموردين
    final suppliers = await dao.getAllSuppliers();
    debugPrint('   ✅ جدول الموردين المحسّن (enhanced_suppliers) موجود ويعمل');
    debugPrint('      عدد الموردين الحالي: ${suppliers.length}');

    // محاولة قراءة من جدول المشتريات
    final purchases = await dao.getAllPurchases();
    debugPrint('   ✅ جدول المشتريات المحسّن (enhanced_purchases) موجود ويعمل');
    debugPrint('      عدد المشتريات الحالي: ${purchases.length}');
  } catch (e) {
    debugPrint('   ❌ خطأ في الوصول للجداول: $e');
    rethrow;
  }
}

Future<int> _testAddSupplier(AppDatabase db) async {
  try {
    final dao = EnhancedPurchaseDao(db);

    final supplier = EnhancedSuppliersCompanion.insert(
      businessName: 'مورد تجريبي ${DateTime.now().millisecondsSinceEpoch}',
      phone: '010${DateTime.now().millisecondsSinceEpoch % 10000000}',
      contactPerson: Value('أحمد محمد'),
      address: Value('القاهرة - مصر'),
      email: Value('test@example.com'),
      zipCode: '12345',
      state: 'القاهرة',
      currentBalance: Value(0.0),
      isCreditAccount: Value(true),
    );

    await dao.insertSupplier(supplier);

    // الحصول على المورد المضاف
    final allSuppliers = await dao.getAllSuppliers();
    final addedSupplier = allSuppliers.last;

    debugPrint('   ✅ تم إضافة المورد بنجاح');
    debugPrint('      ID: ${addedSupplier.id}');
    debugPrint('      الاسم: ${addedSupplier.businessName}');
    debugPrint('      الهاتف: ${addedSupplier.phone}');
    debugPrint('      الرصيد: ${addedSupplier.currentBalance} ج.م');

    return addedSupplier.id;
  } catch (e) {
    debugPrint('   ❌ خطأ في إضافة المورد: $e');
    rethrow;
  }
}

Future<void> _testGetSuppliers(AppDatabase db) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final suppliers = await dao.getAllSuppliers();

    debugPrint('   ✅ تم قراءة قائمة الموردين بنجاح');
    debugPrint('      العدد الإجمالي: ${suppliers.length}');

    if (suppliers.isNotEmpty) {
      debugPrint('      أول 3 موردين:');
      for (var i = 0; i < suppliers.length && i < 3; i++) {
        final s = suppliers[i];
        debugPrint('         ${i + 1}. ${s.businessName} - ${s.phone}');
      }
    }
  } catch (e) {
    debugPrint('   ❌ خطأ في قراءة الموردين: $e');
    rethrow;
  }
}

Future<int> _testAddPurchase(AppDatabase db, int supplierId) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final supplier = await dao.getSupplierById(supplierId);

    if (supplier == null) {
      throw Exception('المورد غير موجود');
    }

    final purchaseNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch}';
    final subtotal = 1000.0;
    final tax = 140.0;
    final discount = 50.0;
    final totalAmount = subtotal + tax - discount;
    final paidAmount = 500.0;
    final remainingAmount = totalAmount - paidAmount;

    final purchase = EnhancedPurchasesCompanion.insert(
      purchaseNumber: purchaseNumber,
      supplierId: supplierId,
      supplierName: supplier.businessName,
      supplierPhone: supplier.phone,
      purchaseDate: DateTime.now(),
      subtotal: subtotal,
      tax: Value(tax),
      discount: Value(discount),
      totalAmount: totalAmount,
      isCreditPurchase: Value(true),
      previousBalance: Value(0.0),
      paidAmount: Value(paidAmount),
      remainingAmount: Value(remainingAmount),
      paymentMethod: 'partial',
      notes: Value('عملية شراء تجريبية'),
    );

    await dao.insertPurchase(purchase);

    // الحصول على المشتريات المضاف
    final allPurchases = await dao.getAllPurchases();
    final addedPurchase = allPurchases.last;

    debugPrint('   ✅ تم إضافة عملية الشراء بنجاح');
    debugPrint('      ID: ${addedPurchase.id}');
    debugPrint('      رقم الفاتورة: ${addedPurchase.purchaseNumber}');
    debugPrint('      المورد: ${addedPurchase.supplierName}');
    debugPrint('      المبلغ الإجمالي: ${addedPurchase.totalAmount} ج.م');
    debugPrint('      المدفوع: ${addedPurchase.paidAmount} ج.م');
    debugPrint('      المتبقي: ${addedPurchase.remainingAmount} ج.م');

    return addedPurchase.id;
  } catch (e) {
    debugPrint('   ❌ خطأ في إضافة عملية الشراء: $e');
    rethrow;
  }
}

Future<void> _testGetPurchases(AppDatabase db) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final purchases = await dao.getAllPurchases();

    debugPrint('   ✅ تم قراءة قائمة المشتريات بنجاح');
    debugPrint('      العدد الإجمالي: ${purchases.length}');

    if (purchases.isNotEmpty) {
      debugPrint('      آخر 3 مشتريات:');
      for (var i = 0; i < purchases.length && i < 3; i++) {
        final p = purchases[i];
        debugPrint(
          '         ${i + 1}. ${p.purchaseNumber} - ${p.totalAmount} ج.م',
        );
      }
    }
  } catch (e) {
    debugPrint('   ❌ خطأ في قراءة المشتريات: $e');
    rethrow;
  }
}

Future<void> _testUpdateSupplierBalance(AppDatabase db, int supplierId) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final supplier = await dao.getSupplierById(supplierId);

    if (supplier == null) {
      throw Exception('المورد غير موجود');
    }

    final newBalance = supplier.currentBalance + 500.0;
    final updatedSupplier = supplier.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );

    await dao.updateSupplier(updatedSupplier);

    final updated = await dao.getSupplierById(supplierId);
    debugPrint('   ✅ تم تحديث رصيد المورد بنجاح');
    debugPrint('      الرصيد القديم: ${supplier.currentBalance} ج.م');
    debugPrint('      الرصيد الجديد: ${updated?.currentBalance} ج.م');
  } catch (e) {
    debugPrint('   ❌ خطأ في تحديث رصيد المورد: $e');
    rethrow;
  }
}

Future<void> _testAddPayment(AppDatabase db, int supplierId) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final supplier = await dao.getSupplierById(supplierId);

    if (supplier == null) {
      throw Exception('المورد غير موجود');
    }

    final payment = SupplierPaymentsCompanion.insert(
      supplierId: supplierId,
      purchaseId: const Value.absent(),
      paymentNumber: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      paymentDate: DateTime.now(),
      amount: 200.0,
      paymentMethod: 'cash',
      referenceNumber: Value('REF-12345'),
    );

    await dao.insertPayment(payment);

    // تحديث رصيد المورد
    final updatedSupplier = supplier.copyWith(
      currentBalance: supplier.currentBalance - 200.0,
      updatedAt: DateTime.now(),
    );
    await dao.updateSupplier(updatedSupplier);

    debugPrint('   ✅ تم إضافة دفعة للمورد بنجاح');
    debugPrint('      المبلغ: 200.0 ج.م');
    debugPrint('      طريقة الدفع: نقدي');
    debugPrint(
      '      الرصيد بعد الدفعة: ${updatedSupplier.currentBalance} ج.م',
    );
  } catch (e) {
    debugPrint('   ❌ خطأ في إضافة الدفعة: $e');
    rethrow;
  }
}

Future<void> _testStatistics(AppDatabase db) async {
  try {
    final dao = EnhancedPurchaseDao(db);

    final totalCredit = await dao.getTotalCreditPurchases();
    final totalCash = await dao.getTotalCashPurchases();
    final topSuppliers = await dao.getTopSuppliersByBalance(5);

    debugPrint('   ✅ تم حساب الإحصائيات بنجاح');
    debugPrint(
      '      إجمالي المشتريات الآجلة: ${totalCredit.toStringAsFixed(2)} ج.م',
    );
    debugPrint(
      '      إجمالي المشتريات النقدية: ${totalCash.toStringAsFixed(2)} ج.م',
    );
    debugPrint('      عدد الموردين ذوي الديون: ${topSuppliers.length}');
  } catch (e) {
    debugPrint('   ❌ خطأ في حساب الإحصائيات: $e');
    rethrow;
  }
}

Future<void> _testSearchSuppliers(AppDatabase db) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final allSuppliers = await dao.getAllSuppliers();

    if (allSuppliers.isEmpty) {
      debugPrint('   ⚠️  لا يوجد موردين للبحث');
      return;
    }

    // البحث عن مورد معين
    final searchTerm = allSuppliers.first.businessName.substring(0, 3);
    final filtered = allSuppliers
        .where(
          (s) =>
              s.businessName.toLowerCase().contains(searchTerm.toLowerCase()) ||
              s.phone.contains(searchTerm),
        )
        .toList();

    debugPrint('   ✅ تم البحث عن الموردين بنجاح');
    debugPrint('      مصطلح البحث: "$searchTerm"');
    debugPrint('      عدد النتائج: ${filtered.length}');
  } catch (e) {
    debugPrint('   ❌ خطأ في البحث: $e');
    rethrow;
  }
}

Future<void> _testGetPurchasesBySupplier(AppDatabase db, int supplierId) async {
  try {
    final dao = EnhancedPurchaseDao(db);
    final purchases = await dao.getPurchasesBySupplier(supplierId);

    debugPrint('   ✅ تم الحصول على مشتريات المورد بنجاح');
    debugPrint('      عدد المشتريات: ${purchases.length}');

    if (purchases.isNotEmpty) {
      final total = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);
      debugPrint('      إجمالي المشتريات: ${total.toStringAsFixed(2)} ج.م');
    }
  } catch (e) {
    debugPrint('   ❌ خطأ في الحصول على مشتريات المورد: $e');
    rethrow;
  }
}
