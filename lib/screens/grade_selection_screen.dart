import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/providers/grade_provider.dart';
import 'package:gnanam/screens/home_screen.dart';

class GradeSelectionScreen extends ConsumerWidget {
  const GradeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Grade'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Which grade are you in?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us tailor explanations to your level',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final grade = index + 1;
                  String tier;
                  Color gradientStart;
                  Color gradientEnd;

                  if (grade >= 1 && grade <= 4) {
                    tier = 'Spark';
                    gradientStart = const Color(0xFFFFB74D);
                    gradientEnd = const Color(0xFFFF8F00);
                  } else if (grade >= 5 && grade <= 8) {
                    tier = 'Scholar';
                    gradientStart = const Color(0xFF4DB6AC);
                    gradientEnd = const Color(0xFF00897B);
                  } else {
                    tier = 'Sage';
                    gradientStart = const Color(0xFF7E57C2);
                    gradientEnd = const Color(0xFF5E35B1);
                  }

                  return _GradeCard(
                    grade: grade,
                    tier: tier,
                    gradientStart: gradientStart,
                    gradientEnd: gradientEnd,
                    onTap: () {
                      ref.read(gradeProvider.notifier).setGrade(grade);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ).animate().scale(
                    delay: Duration(milliseconds: index * 50),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final int grade;
  final String tier;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback onTap;

  const _GradeCard({
    required this.grade,
    required this.tier,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$grade',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tier,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}