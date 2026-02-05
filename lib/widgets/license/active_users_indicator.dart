import 'package:flutter/material.dart';

// Simplified Active Users Indicator widget to keep builds green.
class ActiveUsersIndicator extends StatelessWidget {
  final int activeUsers;
  final int maxUsers;
  final int utilizationPercent;

  const ActiveUsersIndicator({
    super.key,
    this.activeUsers = 0,
    this.maxUsers = 1,
    this.utilizationPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = (utilizationPercent >= 80)
        ? Colors.orange
        : (utilizationPercent >= 50 ? Colors.yellow : Colors.green);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المستخدمين النشطين',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.people, color: Colors.blue, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (utilizationPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              valueColor: AlwaysStoppedAnimation<Color?>(color),
            ),
            const SizedBox(height: 8),
            Text(
              '$activeUsers من $maxUsers مستخدم',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
