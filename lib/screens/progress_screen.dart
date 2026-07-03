import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/providers/progress_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overallStats = ref.watch(overallStatsProvider);
    final subjectProgress = ref.watch(subjectProgressProvider);
    final studyHistory = ref.watch(studyHistoryProvider);
    final recentQuizzes = ref.watch(recentQuizzesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(overallStatsProvider);
          ref.invalidate(subjectProgressProvider);
          ref.invalidate(studyHistoryProvider);
          ref.invalidate(recentQuizzesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SECTION 1: Overview Cards ──
              overallStats.when(
                data: (stats) => _buildOverviewCards(stats, theme),
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Error loading stats: $e'),
              ),
              const SizedBox(height: 24),

              // ── SECTION 2: Subject Progress ──
              Text('Subject Mastery', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              subjectProgress.when(
                data: (subjects) => subjects.isEmpty
                    ? _buildEmptyState('Complete quizzes to track your mastery!', Icons.school_outlined, theme)
                    : Column(children: subjects.map((s) => _buildSubjectCard(s, theme)).toList()),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),

              // ── SECTION 3: Weekly Activity ──
              Text('This Week', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              studyHistory.when(
                data: (history) => _buildWeeklyChart(history, theme),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 24),

              // ── SECTION 4: Recent Quizzes ──
              Text('Recent Quizzes', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              recentQuizzes.when(
                data: (quizzes) => quizzes.isEmpty
                    ? _buildEmptyState('No quizzes taken yet!', Icons.quiz_outlined, theme)
                    : Column(children: quizzes.map((q) => _buildQuizCard(q, theme)).toList()),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> stats, ThemeData theme) {
    final totalQ = (stats['total_questions'] as num?)?.toInt() ?? 0;
    final totalCorrect = (stats['total_correct'] as num?)?.toInt() ?? 0;
    final totalStudyTime = (stats['total_study_time_seconds'] as num?)?.toInt() ?? 0;
    final streak = (stats['streak'] as num?)?.toInt() ?? 0;
    final accuracy = totalQ > 0 ? ((totalCorrect / totalQ) * 100).round() : 0;
    final hours = totalStudyTime ~/ 3600;
    final mins = (totalStudyTime % 3600) ~/ 60;

    final cards = [
      _OverviewData('🔥', '$streak', 'Day Streak', const Color(0xFFFF6B35)),
      _OverviewData('📝', '$totalQ', 'Questions', const Color(0xFF4A90D9)),
      _OverviewData('✅', '$accuracy%', 'Accuracy', const Color(0xFF27AE60)),
      _OverviewData('⏱️', '${hours}h ${mins}m', 'Study Time', const Color(0xFF9B59B6)),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final card = cards[i];
          return Container(
            width: 130,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [card.color.withValues(alpha: 0.15), card.color.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: card.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(card.emoji, style: const TextStyle(fontSize: 22)),
                Text(card.value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(card.label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, ThemeData theme) {
    final name = subject['subject'] as String? ?? 'Unknown';
    final attempted = (subject['total_attempted'] as num?)?.toInt() ?? 0;
    final correct = (subject['total_correct'] as num?)?.toInt() ?? 0;
    final mastery = (subject['avg_mastery'] as num?)?.toDouble() ?? 0.0;
    final masteryPercent = (mastery * 100).clamp(0, 100).toInt();

    Color progressColor;
    if (masteryPercent >= 70) {
      progressColor = Colors.green;
    } else if (masteryPercent >= 40) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    final subjectIcons = {
      'Math': Icons.calculate_outlined,
      'Science': Icons.science_outlined,
      'English': Icons.menu_book_outlined,
      'History': Icons.history_edu_outlined,
      'Social Science': Icons.public_outlined,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(subjectIcons[name] ?? Icons.book_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '$masteryPercent%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: mastery,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$correct/$attempted correct',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> history, ThemeData theme) {
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekData = <int, int>{};

    // Map history data to weekday
    for (final entry in history) {
      final date = DateTime.tryParse(entry['date'] as String? ?? '');
      if (date == null) continue;
      final daysDiff = now.difference(date).inDays;
      if (daysDiff < 7) {
        final weekday = date.weekday; // 1=Monday
        final activity = (entry['messages_sent'] as num?)?.toInt() ?? 0;
        final quizzes = (entry['quizzes_completed'] as num?)?.toInt() ?? 0;
        weekData[weekday] = (weekData[weekday] ?? 0) + activity + quizzes * 5;
      }
    }

    final maxVal = weekData.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final value = weekData[weekday] ?? 0;
              final height = maxVal > 0 ? (value / maxVal) * 100 : 0.0;
              final isToday = now.weekday == weekday;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value > 0)
                    Text(
                      '$value',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 28,
                    height: height.clamp(4, 100).toDouble(),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: isToday
                            ? [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6)]
                            : [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withValues(alpha: 0.4)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, ThemeData theme) {
    final subject = quiz['subject'] as String? ?? 'Unknown';
    final topic = quiz['topic'] as String? ?? '';
    final createdAt = quiz['created_at'] as String? ?? '';
    final date = DateTime.tryParse(createdAt);
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.quiz_outlined, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(topic.isNotEmpty ? topic : subject, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$subject • $dateStr'),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewData {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  _OverviewData(this.emoji, this.value, this.label, this.color);
}
