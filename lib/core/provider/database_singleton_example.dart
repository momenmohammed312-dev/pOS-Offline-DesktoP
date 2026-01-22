import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

// مثال صحيح للاستخدام المزود الواحد
class ReportsPageExample extends ConsumerStatefulWidget {
  const ReportsPageExample({super.key});

  @override
  ConsumerState<ReportsPageExample> createState() => _ReportsPageExampleState();
}

class _ReportsPageExampleState extends ConsumerState<ReportsPageExample> {
  late AppDatabase _db;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // الطريقة الصحيحة: الحصول على المزود من الـ Provider
    _db = ref.read(databaseProvider);
    _loadReportsData();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    try {
      // استخدام المزود لقراءة البيانات - استدعاء دالة موجودة
      final invoices = await _db.select(_db.invoices).get();

      if (invoices.isEmpty) {
        setState(() {
          _error = 'لا توجد تقارير';
        });
      } else {
        setState(() {
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل البيانات: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // إغلاق المزود عند انتهاء الصفحة (سيتم تلقائياً في onDispose)
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال التقارير'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'نظام التقارير المتقدم',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else
              const Text('تم تحميل البيانات بنجاح'),
          ],
        ),
      ),
    );
  }
}
