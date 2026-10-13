import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Preferencia de tema guardada localmente (no es información sensible).
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._prefs) : _mode = _read(_prefs);

  final SharedPreferences? _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _prefs?.setString(PrefsKeys.themeMode, mode.name);
    notifyListeners();
  }

  static ThemeMode _read(SharedPreferences? prefs) {
    final stored = prefs?.getString(PrefsKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.light,
    );
  }
}
