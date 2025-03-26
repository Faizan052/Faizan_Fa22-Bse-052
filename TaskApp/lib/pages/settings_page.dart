import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_app/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme Mode'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(newMode);
                }
              },
              items: ThemeMode.values.map((ThemeMode mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.toString().split('.').last),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: const Text('Font Size'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                label: settings.fontSize.toString(),
                onChanged: (double value) {
                  ref.read(settingsProvider.notifier).setFontSize(value);
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Font Family'),
            trailing: DropdownButton<String>(
              value: settings.fontFamily,
              onChanged: (String? newFont) {
                if (newFont != null) {
                  ref.read(settingsProvider.notifier).setFontFamily(newFont);
                }
              },
              items: [
                'Roboto',
                'Open Sans',
                'Lato',
                'Montserrat',
                'Source Sans Pro',
              ].map((String font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font, style: GoogleFonts.getFont(font)),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('Full Screen Progress'),
            value: settings.fullScreenProgress,
            onChanged: (bool value) {
              ref.read(settingsProvider.notifier).setFullScreenProgress(value);
            },
          ),
        ],
      ),
    );
  }
}