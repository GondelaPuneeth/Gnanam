import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gnanam/features/quiz/quiz_generator.dart';
import 'package:gnanam/core/database/app_database.dart';
import 'package:gnanam/screens/quiz_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final Quiz quiz;
  final List<int?> userAnswers;
  final int timeSpentSeconds;

  const QuizResultsScreen({
    super.key,
    required this.quiz,
    required this.userAnswers,
    required this.timeSpentSeconds,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;
  bool _saved = false;

  int get correctCount {
    int count = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (widget.userAnswers[i] == widget.quiz.questions[i].correctIndex) {
        count++;
      }
    }
    return count;
  }

  double get percentage => widget.quiz.questions.isEmpty
      ? 0
      : (correctCount / widget.quiz.questions.length) * 100;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: percentage).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _saveResults();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveResults() async {
    if (_saved) return;
    _saved = true;
    final db = AppDatabase();

    // Save quiz attempt
    final answersMap = <String, dynamic>{};
    for (int i = 0; i < widget.userAnswers.length; i++) {
      answersMap['q$i'] = widget.userAnswers[i];
    }
    await db.insertQuizAttempt(
      quizId: widget.quiz.id,
      score: correctCount,
      totalQuestions: widget.quiz.questions.length,
      answersJson: jsonEncode(answersMap),
      timeSpentSeconds: widget.timeSpentSeconds,
    );

    // Update learning progress
    await db.updateProgress(
      subject: widget.quiz.subject,
      topic: widget.quiz.topic,
      grade: widget.quiz.grade,
      questionsAttempted: widget.quiz.questions.length,
      correctAnswers: correctCount,
    );

    // Record daily activity
    await db.recordStudyActivity(quizzesCompleted: 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mins = (widget.timeSpentSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (widget.timeSpentSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score circle
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _scoreAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: _scoreAnimation.value / 100,
                                strokeWidth: 12,
                                strokeCap: StrokeCap.round,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  percentage >= 70
                                      ? Colors.green
                                      : percentage >= 40
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_scoreAnimation.value.toInt()}%',
                                      style: theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$correctCount/${widget.quiz.questions.length}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      percentage >= 80
                          ? '🎉 Excellent!'
                          : percentage >= 60
                              ? '👍 Good Job!'
                              : percentage >= 40
                                  ? '📚 Keep Practicing!'
                                  : '💪 Don\'t Give Up!',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statChip(Icons.timer_outlined, '$mins:$secs', 'Time', theme),
                        const SizedBox(width: 16),
                        _statChip(Icons.school_outlined, widget.quiz.subject, 'Subject', theme),
                        const SizedBox(width: 16),
                        _statChip(Icons.trending_up, widget.quiz.difficulty, 'Level', theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Question review
            Text('Question Review', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ...List.generate(widget.quiz.questions.length, (i) {
              final q = widget.quiz.questions[i];
              final userAns = widget.userAnswers[i];
              final isCorrect = userAns == q.correctIndex;
              final labels = ['A', 'B', 'C', 'D'];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCorrect ? Colors.green.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isCorrect ? Colors.green : Colors.red,
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Q${i + 1}: ${q.questionText.length > 50 ? '${q.questionText.substring(0, 50)}...' : q.questionText}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    isCorrect
                        ? 'Correct ✓'
                        : 'Your answer: ${labels[userAns ?? 0]} • Correct: ${labels[q.correctIndex]}',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  children: [
                    if (!isCorrect && q.explanation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.tertiary),
                                  const SizedBox(width: 8),
                                  Text('Explanation', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(q.explanation, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(quiz: widget.quiz),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Back to Chat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

