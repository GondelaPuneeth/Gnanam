import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemma_edge/providers/grade_provider.dart';
import 'package:gemma_edge/providers/theme_provider.dart';
import 'package:gemma_edge/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grade = ref.watch(gradeProvider) ?? 1;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Account Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Account',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Grade'),
                      subtitle: Text('Currently Grade $grade'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to grade selection
                      },
                    ),
                    ListTile(
                      title: const Text('Name'),
                      subtitle: const Text('Student Name'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Edit name
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Appearance Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: const Text('Choose light, dark, or system theme'),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeMode,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            ref.read(themeProvider.notifier).setThemeMode(value);
                          }
                        },
                      ),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text('Font Size'),
                      subtitle: const Text('Adjust text size'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Adjust font size
                      },
                    ),
                    ListTile(
                      title: const Text('Math Rendering Size'),
                      subtitle: const Text('Adjust math equation size'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Adjust math size
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // AI Model Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'AI Model',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Current Tier'),
                      subtitle: Text(
                        grade >= 1 && grade <= 4
                            ? 'Spark (Grades 1-4)'
                            : grade >= 5 && grade <= 8
                                ? 'Scholar (Grades 5-8)'
                                : 'Sage (Grades 9-12)',
                      ),
                      trailing: const Icon(Icons.info_outline),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text('Download Pro Version'),
                      subtitle: const Text('Get access to more advanced models'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Download pro version
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Storage Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Storage',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Model Size'),
                      subtitle: const Text('2.3 GB'),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text('Cache Size'),
                      subtitle: const Text('156 MB'),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text('Clear Cache'),
                      onTap: () {
                        // Clear cache
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Privacy Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Privacy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const ListTile(
                      title: Text('All on-device'),
                      subtitle: Text(
                        'Your data never leaves your device. No internet required for learning.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // About Section
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const ListTile(
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    ListTile(
                      title: const Text('Licenses'),
                      onTap: () {
                        // Show licenses
                      },
                    ),
                    ListTile(
                      title: const Text('Contact'),
                      onTap: () {
                        // Contact support
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}