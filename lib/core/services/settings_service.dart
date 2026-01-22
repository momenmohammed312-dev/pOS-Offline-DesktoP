import 'package:shared_preferences/shared_preferences.dart';

enum CalendarThemeMode { light, gray, dark }

class SettingsService {
  static const _calendarThemeKey = 'calendar_theme_mode';
  static const _defaultInvoiceTypeKey = 'default_invoice_type';
  static const _thermalPrinterKey = 'thermal_printer_name';
  static const _a4PrinterKey = 'a4_printer_name';

  static Future<CalendarThemeMode> getCalendarTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_calendarThemeKey) ?? 'light';
    switch (v) {
      case 'gray':
        return CalendarThemeMode.gray;
      case 'dark':
        return CalendarThemeMode.dark;
      case 'light':
      default:
        return CalendarThemeMode.light;
    }
  }

  static Future<void> setCalendarTheme(CalendarThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final v = switch (mode) {
      CalendarThemeMode.gray => 'gray',
      CalendarThemeMode.dark => 'dark',
      CalendarThemeMode.light => 'light',
    };
    await prefs.setString(_calendarThemeKey, v);
  }

  static Future<void> setDefaultInvoiceType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultInvoiceTypeKey, type);
  }

  static Future<String> getDefaultInvoiceType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultInvoiceTypeKey) ?? 'cash';
  }

  // Printer settings
  static Future<void> setThermalPrinter(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null) {
      await prefs.remove(_thermalPrinterKey);
    } else {
      await prefs.setString(_thermalPrinterKey, name);
    }
  }

  static Future<String?> getThermalPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_thermalPrinterKey);
  }

  static Future<void> setA4Printer(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null) {
      await prefs.remove(_a4PrinterKey);
    } else {
      await prefs.setString(_a4PrinterKey, name);
    }
  }

  static Future<String?> getA4Printer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_a4PrinterKey);
  }
}
