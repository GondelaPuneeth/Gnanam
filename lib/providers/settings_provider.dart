import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gnanam/theme/theme_notifier.dart';

class UserSettings {
  final String studentName;
  final double fontSize;
  final String hfToken;
  final double mathFontScale;

  UserSettings({
    required this.studentName,
    required this.fontSize,
    required this.hfToken,
    this.mathFontScale = 1.0,
  });

  UserSettings copyWith({
    String? studentName,
    double? fontSize,
    String? hfToken,
    double? mathFontScale,
  }) {
    return UserSettings(
      studentName: studentName ?? this.studentName,
      fontSize: fontSize ?? this.fontSize,
      hfToken: hfToken ?? this.hfToken,
      mathFontScale: mathFontScale ?? this.mathFontScale,
    );
  }
}

class SettingsNotifier extends Notifier<UserSettings> {
  static const _nameKey = 'settings_student_name';
  static const _fontSizeKey = 'settings_font_size';
  static const _hfTokenKey = 'settings_hf_token';
  static const _mathFontScaleKey = 'settings_math_font_scale';

  @override
  UserSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return UserSettings(
      studentName: prefs.getString(_nameKey) ?? 'Student Name',
      fontSize: prefs.getDouble(_fontSizeKey) ?? 16.0,
      hfToken: prefs.getString(_hfTokenKey) ?? '',
      mathFontScale: prefs.getDouble(_mathFontScaleKey) ?? 1.0,
    );
  }

  void updateName(String name) {
    state = state.copyWith(studentName: name);
    ref.read(sharedPreferencesProvider).setString(_nameKey, name);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
    ref.read(sharedPreferencesProvider).setDouble(_fontSizeKey, size);
  }

  void updateHfToken(String token) {
    state = state.copyWith(hfToken: token);
    ref.read(sharedPreferencesProvider).setString(_hfTokenKey, token);
  }

  void updateMathFontScale(double scale) {
    state = state.copyWith(mathFontScale: scale);
    ref.read(sharedPreferencesProvider).setDouble(_mathFontScaleKey, scale);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(() {
  return SettingsNotifier();
});
