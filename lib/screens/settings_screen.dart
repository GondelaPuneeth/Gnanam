import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gnanam/providers/grade_provider.dart';
import 'package:gnanam/providers/theme_provider.dart';
import 'package:gnanam/providers/settings_provider.dart';
import 'package:gnanam/screens/grade_selection_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _modelSize = 'Calculating...';
  String _cacheSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateStorageSizes();
  }

  Future<void> _calculateStorageSizes() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Calculate model size
      final modelsDir = Directory('${appDir.path}/models');
      int modelBytes = 0;
      if (await modelsDir.exists()) {
        await for (final entity in modelsDir.list(recursive: true)) {
          if (entity is File) {
            modelBytes += await entity.length();
          }
        }
      }

      // Calculate cache size
      final cacheDir = await getTemporaryDirectory();
      int cacheBytes = 0;
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            try {
              cacheBytes += await entity.length();
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        setState(() {
          _modelSize = _formatBytes(modelBytes);
          _cacheSize = _formatBytes(cacheBytes);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _modelSize = 'Unknown';
          _cacheSize = 'Unknown';
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final grade = ref.watch(gradeProvider) ?? 1;
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);

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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GradeSelectionScreen()),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Name'),
                      subtitle: Text(settings.studentName),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showEditDialog(
                          context: context,
                          title: 'Edit Name',
                          initialValue: settings.studentName,
                          onSave: (value) => ref.read(settingsProvider.notifier).updateName(value),
                        );
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
                      subtitle: Text('${settings.fontSize.round()}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showFontSizeDialog(context, ref, settings.fontSize);
                      },
                    ),
                    ListTile(
                      title: const Text('Math Rendering Size'),
                      subtitle: Text('Scale: ${settings.mathFontScale.toStringAsFixed(1)}x'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showMathScaleDialog(context, ref, settings.mathFontScale);
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
                      title: const Text('HuggingFace Token'),
                      subtitle: Text(settings.hfToken.isEmpty ? 'Not set' : '••••••••'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showEditDialog(
                          context: context,
                          title: 'HuggingFace Token',
                          initialValue: settings.hfToken,
                          onSave: (value) => ref.read(settingsProvider.notifier).updateHfToken(value),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text('Download Pro Version'),
                      subtitle: const Text('Get access to more advanced models'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pro version coming soon!')),
                        );
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
                      subtitle: Text(_modelSize),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text('Cache Size'),
                      subtitle: Text(_cacheSize),
                      onTap: () {},
                    ),
                    ListTile(
                      title: const Text('Clear Cache'),
                      trailing: const Icon(Icons.delete_outline),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear Cache'),
                            content: const Text('This will delete temporary files. Your model and chat data will not be affected.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            final cacheDir = await getTemporaryDirectory();
                            if (await cacheDir.exists()) {
                              await for (final entity in cacheDir.list()) {
                                try {
                                  if (entity is File) {
                                    await entity.delete();
                                  } else if (entity is Directory) {
                                    await entity.delete(recursive: true);
                                  }
                                } catch (_) {}
                              }
                            }
                            _calculateStorageSizes();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cache cleared!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error clearing cache: $e')),
                              );
                            }
                          }
                        }
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
                        showLicensePage(context: context, applicationName: 'Gnanam', applicationVersion: '1.0.0');
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

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref, double currentSize) {
    double tempSize = currentSize;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Font Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sample Text', style: TextStyle(fontSize: tempSize)),
              const SizedBox(height: 16),
              Slider(
                value: tempSize,
                min: 12.0,
                max: 32.0,
                divisions: 10,
                label: tempSize.round().toString(),
                onChanged: (value) {
                  setState(() => tempSize = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateFontSize(tempSize);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMathScaleDialog(BuildContext context, WidgetRef ref, double currentScale) {
    double tempScale = currentScale;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Math Rendering Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'E = mc²',
                style: TextStyle(fontSize: 20 * tempScale, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text('Scale: ${tempScale.toStringAsFixed(1)}x'),
              const SizedBox(height: 12),
              Slider(
                value: tempScale,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${tempScale.toStringAsFixed(1)}x',
                onChanged: (value) {
                  setState(() => tempScale = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateMathFontScale(tempScale);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}