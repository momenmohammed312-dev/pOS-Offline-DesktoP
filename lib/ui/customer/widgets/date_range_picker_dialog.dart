import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:pos_offline_desktop/l10n/app_localizations.dart';

class DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final Function(DateTime, DateTime)? onDateRangeSelected;

  const DateRangePickerDialog({
    super.key,
    this.initialFromDate,
    this.initialToDate,
    this.onDateRangeSelected,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate =
        widget.initialFromDate ?? DateTime(now.year, now.month, now.day);
    _toDate = widget.initialToDate ?? DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              l10n.select_date_range,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(16),

            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.from_date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _fromDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _fromDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_fromDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.to_date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _toDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              _toDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_toDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Quick Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _fromDate = DateTime(now.year, now.month, 1);
                      _toDate = DateTime(now.year, now.month, now.day);
                    });
                  },
                  child: Text(l10n.last_30_days),
                ),
                OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _fromDate = DateTime(now.year, now.month, now.day - 30);
                      _toDate = DateTime(now.year, now.month, now.day);
                    });
                  },
                  child: Text(l10n.last_month),
                ),
                OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _fromDate = DateTime(now.year - 1, now.month, now.day);
                      _toDate = DateTime(now.year - 1, now.month, now.day);
                    });
                  },
                  child: Text(l10n.last_year),
                ),
              ],
            ),

            const Gap(24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const Gap(16),
                ElevatedButton(
                  onPressed: () {
                    if (_fromDate.isBefore(_toDate) ||
                        _fromDate.isAfter(_toDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid date range')),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    widget.onDateRangeSelected?.call(_fromDate, _toDate);
                  },
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
