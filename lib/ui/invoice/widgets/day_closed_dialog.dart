import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DayClosedDialog extends StatelessWidget {
  final VoidCallback onOpenDay;
  final VoidCallback onCancel;

  const DayClosedDialog({
    super.key,
    required this.onOpenDay,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block, color: Colors.red.shade600, size: 48),
              ),
              const Gap(20),
              const Text(
                'Day is Closed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Gap(12),
              const Text(
                'Open the day first',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onOpenDay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Open Day'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
