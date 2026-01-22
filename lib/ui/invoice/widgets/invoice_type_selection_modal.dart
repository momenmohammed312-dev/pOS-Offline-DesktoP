import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum InvoiceType { cash, credit }

class InvoiceTypeSelectionModal extends StatelessWidget {
  final Function(InvoiceType) onSelectType;

  const InvoiceTypeSelectionModal({super.key, required this.onSelectType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر نوع الفاتورة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Gap(8),
              Text(
                'اختر نوع الفاتورة التي تريد إنشاءها',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Gap(32),
              Row(
                children: [
                  // Cash Option
                  Expanded(
                    child: InkWell(
                      onTap: () => onSelectType(InvoiceType.cash),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const Gap(12),
                            Text(
                              'نقدي',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'دفع فوري\nإيصال حراري',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  // Credit Option
                  Expanded(
                    child: InkWell(
                      onTap: () => onSelectType(InvoiceType.credit),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.15,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 48,
                              color: theme.colorScheme.secondary,
                            ),
                            const Gap(12),
                            Text(
                              'آجل',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'دفع على الحساب\nفاتورة A4',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
