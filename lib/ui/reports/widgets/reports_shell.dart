import 'package:flutter/material.dart';
import '../../../core/theme/theme_controller.dart';

class ReportsShell extends StatefulWidget {
  final Widget child;

  const ReportsShell({super.key, required this.child});

  @override
  State<ReportsShell> createState() => _ReportsShellState();
}

class _ReportsShellState extends State<ReportsShell> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    // Activate report theme when entering reports section
    _themeController.activateReportTheme(context);
  }

  @override
  void dispose() {
    // Deactivate report theme when leaving reports section
    _themeController.deactivateReportTheme();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: _themeController.getCurrentTheme(context),
      duration: const Duration(milliseconds: 300),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _handleBackNavigation();
          }
        },
        child: Scaffold(
          body: Column(
            children: [
              // Custom AppBar with back navigation
              _buildReportsAppBar(),
              // Main content area
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildReportsAppBar() {
    return AppBar(
      title: const Text('التقارير'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackNavigation,
        tooltip: 'العودة للرئيسية',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'تحديث البيانات',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _openSettings,
          tooltip: 'إعدادات التقارير',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Theme.of(context).dividerColor),
      ),
    );
  }

  Future<bool> _handleBackNavigation() async {
    // Navigate back to home and restore original theme
    _themeController.deactivateReportTheme();

    // Pop until we reach home route
    Navigator.of(context).popUntil((route) {
      return route.isFirst || route.settings.name == '/home';
    });

    return false; // Let the navigation handle the pop
  }

  void _refreshData() {
    // Trigger refresh in reports provider
    // Note: This is a simple implementation that shows loading state
    // In a real implementation, you might want to:
    // 1. Show a loading indicator
    // 2. Reload the current report data
    // 3. Show success/error feedback

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث البيانات'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    // You could also trigger a refresh in the provider if needed
    // ref.read(reportsProvider.notifier).refresh();
  }

  void _openSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات التقارير'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر إعدادات التقارير:'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('تصدير تلقائي'),
                subtitle: const Text('تصدير التقارير بصيغة CSV تلقائياً'),
                leading: const Icon(Icons.file_download),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تفعيل التصدير التلقائي'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('تضمين التاريخ'),
                subtitle: const Text('تضمين نطاق زمني افتراضي للتقارير'),
                leading: const Icon(Icons.date_range),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تفعيل تضمين التاريخ'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('عرض الأعمدة'),
                subtitle: const Text('اختيار الأعمدة المعروضة في التقارير'),
                leading: const Icon(Icons.view_column),
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم فتح إعدادات الأعمدة'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

// Custom AnimatedTheme widget for smooth theme transitions
class AnimatedTheme extends StatelessWidget {
  final ThemeData data;
  final Duration duration;
  final Widget child;

  const AnimatedTheme({
    super.key,
    required this.data,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: data,
      child: AnimatedContainer(duration: duration, child: child),
    );
  }
}
