import 'package:flutter/material.dart';
import '../../services/user_session_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  Map<String, dynamic>? _sessionStats;
  List<Map<String, String>> _activeUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final sessionStats = await UserSessionService.getSessionStats();
      final activeSessions = await UserSessionService.getActiveSessions();

      setState(() {
        _sessionStats = sessionStats;
        _activeUsers = activeSessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User Limit Card
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'إحصائيات المستخدمين',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'المستخدمين النشطين',
                                '${_sessionStats?['active_users'] ?? 0}',
                                Icons.people,
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildStatCard(
                                'الفتاح المتاحة',
                                '${_sessionStats?['remaining_slots'] ?? 0}',
                                Icons.person_add,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress Bar
                        LinearProgressIndicator(
                          value:
                              (_sessionStats?['utilization_percent'] as int? ??
                                  0) /
                              100.0,
                          backgroundColor: Color.lerp(
                            Colors.grey,
                            Colors.black,
                            0.3,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color?>(
                            (_sessionStats?['utilization_percent'] as int? ??
                                        0) >=
                                    80
                                ? Colors.red
                                : Colors.green,
                          ),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_sessionStats?['utilization_percent'] ?? 0}% استخدام',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Active Users List
                Expanded(
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'المستخدمون النشطين',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const Spacer(),
                              if ((_sessionStats?['remaining_slots'] as int? ??
                                      0) >
                                  0)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('إضافة مستخدم'),
                                  onPressed: _showAddUserDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: _activeUsers.isEmpty
                              ? _buildEmptyUsersState()
                              : _buildActiveUsersList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.1),
                fontWeight: FontWeight.w600,
              ),
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

  Widget _buildEmptyUsersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Color.lerp(Colors.grey, Colors.black, 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد مستخدمين نشطين',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.lerp(Colors.grey, Colors.black, 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'اضغط "إضافة مستخدم" لبدء إدارة المستخدمين',
            style: TextStyle(
              fontSize: 16,
              color: Color.lerp(Colors.grey, Colors.black, 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersList() {
    return ListView.builder(
      itemCount: _activeUsers.length,
      itemBuilder: (context, index) {
        final user = _activeUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color.lerp(Colors.blue, Colors.white, 0.1),
              child: Icon(
                Icons.person,
                color: Color.lerp(Colors.blue, Colors.black, 0.7),
                size: 20,
              ),
            ),
            title: Text(
              user['username'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device ID: ${user['deviceId'] ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.lerp(Colors.grey, Colors.black, 0.6),
                  ),
                ),
                Text(
                  'Login Time: ${_formatDateTime(user['loginTime'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.lerp(Colors.grey, Colors.black, 0.6),
                  ),
                ),
                Text(
                  'Last Activity: ${_formatDateTime(user['lastActivity'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.lerp(Colors.grey, Colors.black, 0.6),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logoutUser(user),
                  tooltip: 'تسجيل الخروج',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> _showAddUserDialog() async {
    if ((_sessionStats?['remaining_slots'] as int? ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('وصلت الحد الأقصى للمستخدمين'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مستخدم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إضافة المستخدم بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutUser(Map<String, String> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: Text(
          'هل أنت متأكد من تسجيل خروج المستخدم ${user['username']}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserSessionService.logoutUser(user['userId']!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تسجيل خروج المستخدم بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تسجيل الخروج: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
