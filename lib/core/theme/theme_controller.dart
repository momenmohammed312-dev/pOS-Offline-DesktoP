import 'package:flutter/material.dart';
import 'report_theme.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  bool _isReportThemeActive = false;
  ThemeData? _previousTheme;

  bool get isReportThemeActive => _isReportThemeActive;

  void activateReportTheme(BuildContext context) {
    if (!_isReportThemeActive) {
      _previousTheme = Theme.of(context);
      _isReportThemeActive = true;
      notifyListeners();
    }
  }

  void deactivateReportTheme() {
    if (_isReportThemeActive) {
      _isReportThemeActive = false;
      _previousTheme = null;
      notifyListeners();
    }
  }

  ThemeData getCurrentTheme(BuildContext context) {
    return _isReportThemeActive ? ReportTheme.reportTheme : Theme.of(context);
  }

  ThemeData? get previousTheme => _previousTheme;
}
