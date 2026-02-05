import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// Test Data Generator for POS System
/// مولد بيانات اختبار لنظام POS
void main() async {
  print('=== POS Test Data Generator ===');
  print('إنشاء بيانات اختبار للنظام...\n');

  // إنشاء منتجات اختبار
  await generateTestProducts();
  
  // إنشاء عملاء اختبار
  await generateTestCustomers();
  
  // إنشاء موردين اختبار
  await generateTestSuppliers();
  
  // إنشاء فواتير مبيعات اختبار
  await generateTestSalesInvoices();
  
  // إنشاء فواتير مشتريات اختبار
  await generateTestPurchaseInvoices();

  print('\n✅ تم إنشاء بيانات الاختبار بنجاح!');
  print('\nالملفات التي تم إنشاؤها:');
  print('📄 test_products.json - منتجات اختبار');
  print('📄 test_customers.json - عملاء اختبار');
  print('📄 test_suppliers.json - موردين اختبار');
  print('📄 test_sales_invoices.json - فواتير مبيعات اختبار');
  print('📄 test_purchase_invoices.json - فواتير مشتريات اختبار');
}

Future<void> generateTestProducts() async {
  final products = [
    {
      'name': 'لابتوس ديل',
      'nameEn': 'Dell Laptop',
      'barcode': '1234567890123',
      'category': 'أجهزة إلكترونية',
      'categoryEn': 'Electronics',
      'price': 3500.00,
      'cost': 2800.00,
      'stock': 25,
      'minStock': 5,
      'description': 'لابتوس ديل أسود 15 بوصة',
      'image': 'laptop.jpg'
    },
    {
      'name': 'ماوس لوجيتك',
      'nameEn': 'Logitech Mouse',
      'barcode': '2345678901234',
      'category': 'إكسسوارات',
      'categoryEn': 'Accessories',
      'price': 85.00,
      'cost': 60.00,
      'stock': 100,
      'minStock': 20,
      'description': 'ماوس لاسلكي من لوجيتك',
      'image': 'mouse.jpg'
    },
    {
      'name': 'كيبورد ميكانيكي',
      'nameEn': 'Mechanical Keyboard',
      'barcode': '3456789012345',
      'category': 'إكسسوارات',
      'categoryEn': 'Accessories',
      'price': 250.00,
      'cost': 180.00,
      'stock': 45,
      'minStock': 10,
      'description': 'كيبورد ميكانيكي RGB',
      'image': 'keyboard.jpg'
    },
    {
      'name': 'شاشة سامسونج 24"',
      'nameEn': 'Samsung Monitor 24"',
      'barcode': '4567890123456',
      'category': 'أجهزة إلكترونية',
      'categoryEn': 'Electronics',
      'price': 1200.00,
      'cost': 950.00,
      'stock': 15,
      'minStock': 3,
      'description': 'شاشة LED سامسونج 24 بوصة',
      'image': 'monitor.jpg'
    },
    {
      'name': 'طابعة HP',
      'nameEn': 'HP Printer',
      'barcode': '5678901234567',
      'category': 'طابعات',
      'categoryEn': 'Printers',
      'price': 450.00,
      'cost': 350.00,
      'stock': 8,
      'minStock': 2,
      'description': 'طابعة HP ليزر ملونة',
      'image': 'printer.jpg'
    },
    {
      'name': 'هارد خارجي 1TB',
      'nameEn': 'External Hard Drive 1TB',
      'barcode': '6789012345678',
      'category': 'تخزين',
      'categoryEn': 'Storage',
      'price': 180.00,
      'cost': 120.00,
      'stock': 60,
      'minStock': 15,
      'description': 'هارد خارجي USB 3.0 سعة 1 تيرا',
      'image': 'harddrive.jpg'
    },
    {
      'name': 'كاميرا ويب لوجيتك',
      'nameEn': 'Logitech Webcam',
      'barcode': '7890123456789',
      'category': 'إكسسوارات',
      'categoryEn': 'Accessories',
      'price': 120.00,
      'cost': 85.00,
      'stock': 35,
      'minStock': 8,
      'description': 'كاميرا ويب HD 1080p',
      'image': 'webcam.jpg'
    },
    {
      'name': 'سماعات بلوتوث',
      'nameEn': 'Bluetooth Headphones',
      'barcode': '8901234567890',
      'category': 'صوتيات',
      'categoryEn': 'Audio',
      'price': 95.00,
      'cost': 65.00,
      'stock': 50,
      'minStock': 12,
      'description': 'سماعات بلوتوث لاسلكية',
      'image': 'headphones.jpg'
    },
    {
      'name': 'USB فلاش 32GB',
      'nameEn': 'USB Flash 32GB',
      'barcode': '9012345678901',
      'category': 'تخزين',
      'categoryEn': 'Storage',
      'price': 25.00,
      'cost': 15.00,
      'stock': 200,
      'minStock': 50,
      'description': 'فلاش USB 3.0 سعة 32 جيجا',
      'image': 'usb.jpg'
    },
    {
      'name': 'ماك بوك برو',
      'nameEn': 'MacBook Pro',
      'barcode': '0123456789012',
      'category': 'أجهزة إلكترونية',
      'categoryEn': 'Electronics',
      'price': 8500.00,
      'cost': 7200.00,
      'stock': 5,
      'minStock': 1,
      'description': 'ماك بوك برو 13 بوصة M2',
      'image': 'macbook.jpg'
    }
  ];

  await _saveToFile('test_products.json', products);
  print('💾 تم إنشاء ${products.length} منتج اختبار');
}

Future<void> generateTestCustomers() async {
  final customers = [
    {
      'name': 'أحمد محمد',
      'nameEn': 'Ahmed Mohamed',
      'phone': '01234567890',
      'email': 'ahmed@example.com',
      'address': 'القاهرة، مصر',
      'addressEn': 'Cairo, Egypt',
      'balance': 1500.00,
      'creditLimit': 5000.00,
      'isActive': true
    },
    {
      'name': 'فاطمة علي',
      'nameEn': 'Fatima Ali',
      'phone': '02345678901',
      'email': 'fatima@example.com',
      'address': 'الرياض، السعودية',
      'addressEn': 'Riyadh, Saudi Arabia',
      'balance': 800.00,
      'creditLimit': 3000.00,
      'isActive': true
    },
    {
      'name': 'محمد عبدالله',
      'nameEn': 'Mohamed Abdallah',
      'phone': '03456789012',
      'email': 'mohamed@example.com',
      'address': 'دبي، الإمارات',
      'addressEn': 'Dubai, UAE',
      'balance': 2200.00,
      'creditLimit': 10000.00,
      'isActive': true
    },
    {
      'name': 'مريم حسن',
      'nameEn': 'Mariam Hassan',
      'phone': '04567890123',
      'email': 'mariam@example.com',
      'address': 'القاهرة، مصر',
      'addressEn': 'Cairo, Egypt',
      'balance': 0.00,
      'creditLimit': 2000.00,
      'isActive': true
    },
    {
      'name': 'خالد سعيد',
      'nameEn': 'Khaled Said',
      'phone': '05678901234',
      'email': 'khaled@example.com',
      'address': 'جدة، السعودية',
      'addressEn': 'Jeddah, Saudi Arabia',
      'balance': 3500.00,
      'creditLimit': 8000.00,
      'isActive': true
    }
  ];

  await _saveToFile('test_customers.json', customers);
  print('💾 تم إنشاء ${customers.length} عميل اختبار');
}

Future<void> generateTestSuppliers() async {
  final suppliers = [
    {
      'name': 'شركة التقنية المتقدمة',
      'nameEn': 'Advanced Technology Co.',
      'phone': '01098765432',
      'email': 'info@advancedtech.com',
      'address': 'القاهرة، مصر',
      'addressEn': 'Cairo, Egypt',
      'contactPerson': 'أيمن سامي',
      'contactPersonEn': 'Ayman Samy',
      'balance': 12000.00,
      'isActive': true
    },
    {
      'name': 'مؤسسة الإلكترونيات الحديثة',
      'nameEn': 'Modern Electronics Est.',
      'phone': '02098765432',
      'email': 'sales@modernelectronics.com',
      'address': 'الرياض، السعودية',
      'addressEn': 'Riyadh, Saudi Arabia',
      'contactPerson': 'سالم أحمد',
      'contactPersonEn': 'Salem Ahmed',
      'balance': 8500.00,
      'isActive': true
    },
    {
      'name': 'شركة المستوردون الموثوقون',
      'nameEn': 'Trusted Importers Ltd.',
      'phone': '03098765432',
      'email': 'import@trusted.com',
      'address': 'دبي، الإمارات',
      'addressEn': 'Dubai, UAE',
      'contactPerson': 'راشد محمد',
      'contactPersonEn': 'Rashid Mohamed',
      'balance': 15000.00,
      'isActive': true
    }
  ];

  await _saveToFile('test_suppliers.json', suppliers);
  print('💾 تم إنشاء ${suppliers.length} مورد اختبار');
}

Future<void> generateTestSalesInvoices() async {
  final invoices = [];
  final random = Random();
  final now = DateTime.now();
  
  final customerNames = [
    'أحمد محمد',
    'فاطمة علي',
    'محمد سعيد',
    'نورا خالد',
    'عمر حسن'
  ];

  for (int i = 1; i <= 15; i++) {
    final invoiceDate = now.subtract(Duration(days: random.nextInt(30)));
    final isCredit = random.nextBool();
    final customerIndex = random.nextInt(5);
    
    final invoice = <String, dynamic>{
      'invoiceNumber': 'SALE-${now.year}-${i.toString().padLeft(4, '0')}',
      'customerId': customerIndex + 1,
      'customerName': customerNames[customerIndex],
      'invoiceDate': invoiceDate.toIso8601String(),
      'paymentType': isCredit ? 'credit' : 'cash',
      'items': <Map<String, dynamic>>[],
      'subtotal': 0.0,
      'discount': 0.0,
      'tax': 0.0,
      'total': 0.0,
      'paid': 0.0,
      'remaining': 0.0
    };

    // إضافة عناصر عشوائية للفاتورة
    final itemCount = random.nextInt(3) + 1;
    double subtotal = 0.0;

    for (int j = 0; j < itemCount; j++) {
      final productIndex = random.nextInt(10);
      final quantity = random.nextInt(3) + 1;
      final price = [3500.0, 85.0, 250.0, 1200.0, 450.0, 180.0, 120.0, 95.0, 25.0, 8500.0][productIndex];
      final productName = [
        'لابتوس ديل', 'ماوس لوجيتك', 'كيبورد ميكانيكي', 'شاشة سامسونج 24"',
        'طابعة HP', 'هارد خارجي 1TB', 'كاميرا ويب لوجيتك', 'سماعات بلوتوث',
        'USB فلاش 32GB', 'ماك بوك برو'
      ][productIndex];

      final itemTotal = price * quantity;
      subtotal += itemTotal;

      invoice['items']?.add({
        'productId': productIndex + 1,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'total': itemTotal
      }) ?? [];
    }

    invoice['subtotal'] = subtotal;
    invoice['discount'] = isCredit ? subtotal * 0.05 : 0.0; // خصم 5% للآجل
    invoice['tax'] = 0.0; // لا ضريبة في الاختبار
    invoice['total'] = subtotal - invoice['discount'];

    if (isCredit) {
      invoice['paid'] = 0.0;
      invoice['remaining'] = invoice['total'];
    } else {
      invoice['paid'] = invoice['total'];
      invoice['remaining'] = 0.0;
    }

    invoices.add(invoice);
  }

  await _saveToFile('test_sales_invoices.json', invoices);
  print('💾 تم إنشاء ${invoices.length} فاتورة مبيعات اختبار');
}

Future<void> generateTestPurchaseInvoices() async {
  final invoices = [];
  final random = Random();
  final now = DateTime.now();

  for (int i = 1; i <= 8; i++) {
    final invoiceDate = now.subtract(Duration(days: random.nextInt(20)));
    final isCredit = random.nextBool();
    final supplierIndex = random.nextInt(3);
    
    final invoice = <String, dynamic>{
      'invoiceNumber': 'PUR-${now.year}-${i.toString().padLeft(4, '0')}',
      'supplierId': supplierIndex + 1,
      'supplierName': [
        'شركة التقنية المتقدمة', 'مؤسسة الإلكترونيات الحديثة', 'شركة المستوردون الموثوقون'
      ][supplierIndex],
      'invoiceDate': invoiceDate.toIso8601String(),
      'paymentType': isCredit ? 'credit' : 'cash',
      'subtotal': 0.0,
      'discount': 0.0,
      'tax': 0.0,
      'total': 0.0,
      'paid': 0.0,
      'remaining': 0.0,
      'items': <Map<String, dynamic>>[]
    };

    // إضافة عناصر عشوائية للفاتورة
    final itemCount = random.nextInt(4) + 1;
    double subtotal = 0.0;

    for (int j = 0; j < itemCount; j++) {
      final productIndex = random.nextInt(10);
      final quantity = random.nextInt(10) + 5; // كميات أكبر في المشتريات
      final cost = [2800.0, 60.0, 180.0, 950.0, 350.0, 120.0, 85.0, 65.0, 15.0, 7200.0][productIndex];
      final productName = [
        'لابتوس ديل', 'ماوس لوجيتك', 'كيبورد ميكانيكي', 'شاشة سامسونج 24"',
        'طابعة HP', 'هارد خارجي 1TB', 'كاميرا ويب لوجيتك', 'سماعات بلوتوث',
        'USB فلاش 32GB', 'ماك بوك برو'
      ][productIndex];

      final itemTotal = cost * quantity;
      subtotal += itemTotal;

      invoice['items']?.add({
        'productId': productIndex + 1,
        'productName': productName,
        'quantity': quantity,
        'cost': cost,
        'total': itemTotal
      }) ?? [];
    }

    invoice['subtotal'] = subtotal;
    invoice['discount'] = subtotal * 0.1; // خصم 10% في المشتريات
    invoice['tax'] = 0.0;
    invoice['total'] = subtotal - invoice['discount'];

    if (isCredit) {
      invoice['paid'] = subtotal * 0.3; // دفع 30% مقدم
      invoice['remaining'] = invoice['total'] - invoice['paid'];
    } else {
      invoice['paid'] = invoice['total'];
      invoice['remaining'] = 0.0;
    }

    invoices.add(invoice);
  }

  await _saveToFile('test_purchase_invoices.json', invoices);
  print('💾 تم إنشاء ${invoices.length} فاتورة مشتريات اختبار');
}

Future<void> _saveToFile(String filename, List<dynamic> data) async {
  final file = File(filename);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(data),
    encoding: utf8,
  );
}
