import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(_loadThemeMode(_prefs)) {
    _saveThemeMode(state);
  }

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _saveThemeMode(ThemeMode themeMode) {
    final themeModeString = themeMode.toString().split('.').last;
    _prefs.setString('theme_mode', themeModeString);
  }

  void setThemeMode(ThemeMode themeMode) {
    state = themeMode;
    _saveThemeMode(themeMode);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});