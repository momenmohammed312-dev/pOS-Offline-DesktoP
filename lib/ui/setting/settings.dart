import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pos_offline_desktop/l10n/l10n.dart';
import 'package:pos_offline_desktop/core/services/settings_service.dart';
import 'package:pos_offline_desktop/core/services/printer_service.dart';

// ignore_for_file: deprecated_member_use

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  CalendarThemeMode _calendarTheme = CalendarThemeMode.light;
  List<Map<String, dynamic>> _printers = [];
  String? _selectedThermalPrinter;
  String? _selectedA4Printer;

  @override
  void initState() {
    super.initState();
    SettingsService.getCalendarTheme().then((mode) {
      setState(() => _calendarTheme = mode);
    });
    // load printers and saved choices
    PrinterService.getAvailablePrinters().then((list) async {
      final thermal = await SettingsService.getThermalPrinter();
      final a4 = await SettingsService.getA4Printer();
      setState(() {
        _printers = list;
        _selectedThermalPrinter = thermal;
        _selectedA4Printer = a4;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(10),

          // Dark Mode Toggle
          SwitchListTile(
            title: Text(context.l10n.dark_mode),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
            secondary: const Icon(Icons.dark_mode),
          ),

          const SizedBox(height: 12),
          Text(
            'Calendar Theme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  SettingsService.setCalendarTheme(CalendarThemeMode.light);
                  setState(() => _calendarTheme = CalendarThemeMode.light);
                },
                child: Row(
                  children: [
                    Radio<CalendarThemeMode>(
                      value: CalendarThemeMode.light,
                      groupValue: _calendarTheme,
                      onChanged: (CalendarThemeMode? v) {
                        if (v == null) return;
                        SettingsService.setCalendarTheme(v);
                        setState(() => _calendarTheme = v);
                      },
                    ),
                    const Text('Light'),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  SettingsService.setCalendarTheme(CalendarThemeMode.gray);
                  setState(() => _calendarTheme = CalendarThemeMode.gray);
                },
                child: Row(
                  children: [
                    Radio<CalendarThemeMode>(
                      value: CalendarThemeMode.gray,
                      groupValue: _calendarTheme,
                      onChanged: (CalendarThemeMode? v) {
                        if (v == null) return;
                        SettingsService.setCalendarTheme(v);
                        setState(() => _calendarTheme = v);
                      },
                    ),
                    const Text('Gray'),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  SettingsService.setCalendarTheme(CalendarThemeMode.dark);
                  setState(() => _calendarTheme = CalendarThemeMode.dark);
                },
                child: Row(
                  children: [
                    Radio<CalendarThemeMode>(
                      value: CalendarThemeMode.dark,
                      groupValue: _calendarTheme,
                      onChanged: (CalendarThemeMode? v) {
                        if (v == null) return;
                        SettingsService.setCalendarTheme(v);
                        setState(() => _calendarTheme = v);
                      },
                    ),
                    const Text('Dark'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Default Invoice Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          FutureBuilder<String>(
            future: SettingsService.getDefaultInvoiceType(),
            builder: (context, snapshot) {
              final current = snapshot.data ?? 'cash';
              return Column(
                children: [
                  InkWell(
                    onTap: () async {
                      await SettingsService.setDefaultInvoiceType('cash');
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'cash',
                          groupValue: current,
                          onChanged: (String? v) async {
                            if (v == null) return;
                            await SettingsService.setDefaultInvoiceType(v);
                            setState(() {});
                          },
                        ),
                        const Text('Cash (نقدي)'),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await SettingsService.setDefaultInvoiceType('credit');
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'credit',
                          groupValue: current,
                          onChanged: (String? v) async {
                            if (v == null) return;
                            await SettingsService.setDefaultInvoiceType(v);
                            setState(() {});
                          },
                        ),
                        const Text('Credit (آجل)'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const Divider(height: 32),
          Text(
            'Printer Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(10),
          if (_printers.isEmpty) ...[
            const Text('No printers detected yet.'),
            const Gap(8),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedThermalPrinter,
              decoration: const InputDecoration(
                labelText: 'Default Thermal Printer',
                border: OutlineInputBorder(),
              ),
              items: _printers
                  .where((p) => p['type'] == 'Thermal')
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p['name'] as String,
                      child: Text(p['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (val) async {
                setState(() => _selectedThermalPrinter = val);
                await SettingsService.setThermalPrinter(val);
              },
            ),
            const Gap(8),
            DropdownButtonFormField<String>(
              initialValue: _selectedA4Printer,
              decoration: const InputDecoration(
                labelText: 'Default A4 Printer',
                border: OutlineInputBorder(),
              ),
              items: _printers
                  .where((p) => p['type'] == 'A4' || p['type'] == 'PDF')
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p['name'] as String,
                      child: Text(p['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (val) async {
                setState(() => _selectedA4Printer = val);
                await SettingsService.setA4Printer(val);
              },
            ),
            const Gap(12),
            ElevatedButton(
              onPressed: () async {
                // Refresh printer list
                final list = await PrinterService.getAvailablePrinters();
                setState(() => _printers = list);
              },
              child: const Text('Refresh Printers'),
            ),
            const Divider(height: 32),
          ],

          Text(
            context.l10n.other_settings,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(10),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.about),
            onTap: () {
              // Show about app info
              showAboutDialog(
                context: context,
                applicationName: 'POS System',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.store),
                children: [
                  const Text('This is a simple POS system built with Flutter.'),
                ],
              );
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(height: 32),
          Center(
            child: Text(
              "${context.l10n.version} 1.0.0",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
