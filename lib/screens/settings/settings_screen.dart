import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // License Information
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('معلومات الرخصة'),
              subtitle: const Text('عرض وتفاصيل الرخصة الحالية'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/license-info'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Backup Management
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('إدارة النسخ الاحتياطية'),
              subtitle: const Text('إنشاء واستعادة النسخ الاحتياطية'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/backup-management'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // User Management
          Card(
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('إدارة المستخدمين'),
              subtitle: const Text('إدارة جلسات المستخدمين والصلاحيات'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/user-management'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Reports
          Card(
            child: ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('التقارير'),
              subtitle: const Text('عرض التقارير المالية'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/reports'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // System Information
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('معلومات النظام'),
              subtitle: const Text('معلومات الإصدار والنظام'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/system-info'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Support
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('الدعم الفني'),
              subtitle: const Text('الحصول على المساعدة'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/support'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Version
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'نظام نقاط البيع المحترف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'الإصدار:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '2.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'تاريخ البناء:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '2026',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'المطور:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'MO2 Development Team',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
