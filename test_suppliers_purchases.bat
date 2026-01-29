@echo off
echo ========================================
echo اختبار نظام الموردين والمشتريات
echo ========================================
echo.

echo [1/3] تحديث ملفات قاعدة البيانات...
dart run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo.
    echo ❌ فشل تحديث ملفات قاعدة البيانات
    echo    يرجى التأكد من تثبيت جميع الحزم: flutter pub get
    pause
    exit /b 1
)

echo.
echo [2/3] تشغيل الاختبارات...
dart run test_suppliers_purchases.dart
if %errorlevel% neq 0 (
    echo.
    echo ❌ فشل بعض الاختبارات
    pause
    exit /b 1
)

echo.
echo [3/3] ✅ اكتمل الاختبار بنجاح!
echo.
pause
