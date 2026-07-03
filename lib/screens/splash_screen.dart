import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/providers/grade_provider.dart';
import 'package:gnanam/theme/theme_notifier.dart';
import 'package:gnanam/screens/home_screen.dart';
import 'package:gnanam/screens/onboarding_screen.dart';

import 'package:gnanam/inference/llm_service.dart';
import 'package:shimmer/shimmer.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _downloadProgress = 0.0;
  String _statusText = 'Initializing AI engine...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the widget tree to be fully built and animated before showing dialogs
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = ref.read(sharedPreferencesProvider);
    String? hfToken = prefs.getString('settings_hf_token');

    final llmService = ref.read(llmServiceProvider);
    
    // Listen to download progress
    llmService.downloadProgress.listen((progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
          if (progress < 1.0) {
            _statusText = 'Downloading Gemma model: ${(progress * 100).toStringAsFixed(1)}%';
          } else {
            _statusText = 'Loading model into memory...';
          }
        });
      }
    });

    if (hfToken == null || hfToken.isEmpty) {
      if (mounted) {
        setState(() => _statusText = 'Waiting for Hugging Face Token...');
      }
      hfToken = await _showTokenDialog();
      if (hfToken != null && hfToken.isNotEmpty) {
        await prefs.setString('settings_hf_token', hfToken);
      } else {
        if (mounted) {
          setState(() => _statusText = 'Token is required to continue.');
        }
        return; // Halt initialization
      }
    }

    bool isInstalled = false;
    while (!isInstalled) {
      try {
        setState(() => _statusText = 'Initializing AI engine...');
        await llmService.initialize(hfToken: hfToken);
        await llmService.installModel();
        isInstalled = true;
      } catch (e) {
        if (mounted) {
          setState(() => _statusText = 'Failed to load AI model.');
        }
        hfToken = await _showTokenDialog(error: e.toString());
        if (hfToken != null && hfToken.isNotEmpty) {
          await prefs.setString('settings_hf_token', hfToken);
        } else {
          if (mounted) {
            setState(() => _statusText = 'Token is required to continue.');
          }
          return; // Halt initialization
        }
      }
    }

    if (!mounted) return;

    // Check if user has completed onboarding
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brain icon with circuit lines
                    Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.primary,
                      highlightColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
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
                      'Gnanam',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 48),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).animate().fadeIn(duration: 800.ms),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 250,
                      child: LinearProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ).animate().fadeIn(duration: 1000.ms),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showTokenDialog({String? error}) async {
    String token = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hugging Face Token Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null) ...[
              Text(error, style: const TextStyle(color: Colors.red, fontSize: 12)),
              const SizedBox(height: 8),
            ],
            const Text(
              'Gnanam uses the Gemma 2 AI model, which requires you to accept its license on Hugging Face.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enter your Hugging Face Access Token to download the model.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'HF Access Token (hf_...)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => token = val,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(token),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}