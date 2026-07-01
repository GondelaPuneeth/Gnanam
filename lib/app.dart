import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemma_edge/providers/grade_provider.dart';
import 'package:gemma_edge/providers/theme_provider.dart';
import 'package:gemma_edge/screens/splash_screen.dart';
import 'package:gemma_edge/screens/settings_screen.dart';
import 'package:gemma_edge/theme/app_theme.dart';

class GemmaEdgeApp extends ConsumerWidget {
  const GemmaEdgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final grade = ref.watch(gradeProvider);

    return MaterialApp(
      title: 'GemmaEdge',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}