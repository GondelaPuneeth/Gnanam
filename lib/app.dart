import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gnanam/providers/theme_provider.dart';
import 'package:gnanam/screens/splash_screen.dart';
import 'package:gnanam/screens/settings_screen.dart';
import 'package:gnanam/theme/app_theme.dart';

class GnanamApp extends ConsumerWidget {
  const GnanamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Gnanam',
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