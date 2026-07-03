import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gnanam/theme/theme_notifier.dart';

class GradeNotifier extends StateNotifier<int?> {
  final SharedPreferences _prefs;

  GradeNotifier(this._prefs) : super(_loadGrade(_prefs));

  static int? _loadGrade(SharedPreferences prefs) {
    return prefs.getInt('selected_grade');
  }

  void setGrade(int grade) {
    state = grade;
    _prefs.setInt('selected_grade', grade);
  }

  void clearGrade() {
    state = null;
    _prefs.remove('selected_grade');
  }
}

final gradeProvider = StateNotifierProvider<GradeNotifier, int?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return GradeNotifier(prefs);
});