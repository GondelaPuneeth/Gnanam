import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/providers/grade_provider.dart';
import 'package:gnanam/providers/theme_provider.dart';
import 'package:gnanam/providers/settings_provider.dart';
import 'package:gnanam/theme/app_theme.dart';
import 'package:gnanam/screens/chat_history_screen.dart';
import 'package:gnanam/screens/progress_screen.dart';
import 'package:gnanam/screens/quiz_screen.dart';
import 'package:gnanam/features/quiz/quiz_generator.dart';

class DrawerMenu extends ConsumerWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grade = ref.watch(gradeProvider) ?? 1;
    final primaryColor = AppTheme.getPrimaryColorForGrade(grade);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  settings.studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grade $grade Student',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('Chat History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('Saved Lessons'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen(bookmarkedOnly: true)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('My Progress'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: const Text('Practice Tests'),
            onTap: () {
              Navigator.pop(context);
              _showQuizDialog(context, ref, grade);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Gnanam',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Gnanam AI Tutor\nAll learning happens on-device.',
                children: [
                  const SizedBox(height: 16),
                  const Text('An offline AI tutor for Indian students, powered by Gemma 2.'),
                ],
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Theme'),
                Switch(
                  value: ref.watch(themeProvider) == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuizDialog(BuildContext context, WidgetRef ref, int grade) {
    String selectedSubject = 'Math';
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Generate Quiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                items: ['Math', 'Science', 'English', 'History', 'Social Science']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedSubject = v ?? 'Math'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g., Fractions, Photosynthesis...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (topicController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a topic')),
                  );
                  return;
                }
                Navigator.pop(ctx);

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating quiz...'),
                        SizedBox(height: 4),
                        Text('This may take a moment', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );

                try {
                  final generator = ref.read(quizGeneratorProvider);
                  final quiz = await generator.generateQuiz(
                    subject: selectedSubject,
                    topic: topicController.text.trim(),
                    grade: grade,
                  );

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate quiz: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}