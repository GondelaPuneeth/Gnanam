import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/core/database/app_database.dart';

final overallStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await AppDatabase().getOverallStats();
});

final subjectProgressProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await AppDatabase().getProgressBySubject();
});

final studyHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await AppDatabase().getStudyHistory(days: 7);
});

final recentQuizzesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await AppDatabase().getQuizzes(limit: 10);
});
