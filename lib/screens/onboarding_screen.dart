import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gemma_edge/screens/grade_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildOnboardingPage(
                context,
                title: 'Learn offline, anytime',
                description:
                    'No internet? No problem. GemmaEdge works completely offline so you can study anywhere.',
                illustration: Icons.wifi_off_outlined,
              ),
              _buildOnboardingPage(
                context,
                title: 'Your AI tutor adapts to your grade',
                description:
                    'Whether you\'re in primary, middle, or high school, GemmaEdge tailors explanations to your level.',
                illustration: Icons.school_outlined,
              ),
              _buildOnboardingPage(
                context,
                title: 'Practice math, science, and more',
                description:
                    'From algebra to chemistry, get detailed explanations with beautiful math rendering.',
                illustration: Icons.calculate_outlined,
              ),
            ],
          ),
          // Skip button
          if (_currentPage != 2)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: () {
                  _completeOnboarding();
                },
                child: const Text('Skip'),
              ),
            ),
          // Page indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
      child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          // Get Started button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage == 2) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(BuildContext context, {
    required String title,
    required String description,
    required IconData illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            illustration,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
    );
  }
}