import 'package:flutter/material.dart';
import '../../services/local_backup_service.dart';
import '../../services/auto_backup_trigger.dart';

class BackupManagementScreen extends StatefulWidget {
  const BackupManagementScreen({super.key});

  @override
  State<BackupManagementScreen> createState() => _BackupManagementScreenState();
}

class _BackupManagementScreenState extends State<BackupManagementScreen> {
  List<BackupInfo> _backups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);

    try {
      final backups = await LocalBackupService.getAvailableBackups();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading backups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة النسخ الاحتياطية'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Actions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingBackup
                              ? null
                              : _createManualBackup,
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء نسخة احتياطية'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingBackup ? null : _forceBackupNow,
                          icon: const Icon(Icons.backup),
                          label: const Text('نسخة فورية'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Backup Stats
                FutureBuilder(
                  future: AutoBackupTrigger.getBackupStats(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final stats = snapshot.data!;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إحصائيات النسخ الاحتياطية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatCard(
                                  'إجمالي النسخ',
                                  '${stats['total_backups'] ?? 0}',
                                  Icons.archive,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  'نسخة تلقائية',
                                  '${stats['automatic_backups'] ?? 0}',
                                  Icons.schedule,
                                  Colors.green,
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  'نسخة يدوية',
                                  '${stats['manual_backups'] ?? 0}',
                                  Icons.person,
                                  Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatCard(
                                  'حجم الإجمالي',
                                  '${stats['total_size_mb'] ?? 0} ميجابايت',
                                  Icons.storage,
                                  Colors.purple,
                                ),
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  'المعاملات',
                                  '${stats['transaction_count'] ?? 0}',
                                  Icons.receipt_long,
                                  Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'النسخة التالية: ${stats['next_daily_backup'] ?? 'غير محدد'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (stats['is_running'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 8,
                                          height: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'النظام التلقائي نشط',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Backups List
                Expanded(
                  child: _backups.isEmpty
                      ? _buildEmptyState()
                      : _buildBackupsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBackups,
        tooltip: 'تحديث القائمة',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.lerp(color, Colors.black, 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.backup_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'لا توجد نسخ احتياطية',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'اضغط "إنشاء نسخة احتياطية" لبدء عمل نسخ احتياطية',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList() {
    return ListView.builder(
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final backup = _backups[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getBackupTypeColor(backup.type),
              child: Icon(
                _getBackupTypeIcon(backup.type),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              backup.fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.createdString,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  backup.sizeString,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getBackupTypeColor(
                          backup.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getBackupTypeText(backup.type),
                        style: TextStyle(
                          fontSize: 10,
                          color: Color.lerp(
                            _getBackupTypeColor(backup.type),
                            Colors.black,
                            0.8,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _exportBackup(backup),
                  tooltip: 'تصدير',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () => _restoreBackup(backup),
                  tooltip: 'استعادة',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteBackup(backup),
                  tooltip: 'حذف',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackupTypeColor(String type) {
    switch (type) {
      case 'auto':
        return Colors.blue;
      case 'manual':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getBackupTypeIcon(String type) {
    switch (type) {
      case 'auto':
        return Icons.schedule;
      case 'manual':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  String _getBackupTypeText(String type) {
    switch (type) {
      case 'auto':
        return 'تلقائي';
      case 'manual':
        return 'يدوي';
      default:
        return 'غير معروف';
    }
  }

  Future<void> _createManualBackup() async {
    setState(() => _isCreatingBackup = true);

    try {
      final backupPath = await AutoBackupTrigger.forceBackup(
        description: 'manual_backup_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _forceBackupNow() async {
    setState(() => _isCreatingBackup = true);

    try {
      final backupPath = await AutoBackupTrigger.forceBackup(
        description: 'forced_backup_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء نسخة فورية بنجاح'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في النسخة الفورية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _exportBackup(BackupInfo backup) async {
    // This would typically open a file picker to save the backup
    // For now, just show the backup path
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير النسخة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مسار النسخة:'),
            const SizedBox(height: 8),
            SelectableText(
              backup.filePath,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة النسخة'),
        content: Text(
          'هل أنت متأكد من استعادة هذه النسخة؟ سيتم استبدال البيانات الحالية بالبيانات من هذه النسخة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await LocalBackupService.restoreFromBackup(
          backup.filePath,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'تم استعادة النسخة بنجاح' : 'فشلت استعادة النسخة',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }

        await _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في استعادة النسخة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النسخة'),
        content: Text(
          'هل أنت متأكد من حذف هذه النسخة؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await LocalBackupService.deleteBackup(backup.filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'تم حذف النسخة بنجاح' : 'فشل حذف النسخة'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }

        await _loadBackups();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف النسخة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
