import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemma_edge/providers/grade_provider.dart';
import 'package:gemma_edge/screens/home_screen.dart';
import 'package:gemma_edge/screens/onboarding_screen.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Simulate model loading delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user has completed onboarding
    final prefs = ref.read(sharedPreferencesProvider);
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    final selectedGrade = ref.read(gradeProvider);

    if (hasOnboarded && selectedGrade != null) {
      // Navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Navigate to onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brain icon with circuit lines
            Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.primary,
              highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Icon(
                Icons.auto_awesome,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 32),
            Text(
              'GemmaEdge',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 48),
            Text(
              'Loading AI model...',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ).animate().fadeIn(duration: 1000.ms),
          ],
        ),
      ),
    );
  }
}