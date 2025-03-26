import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsState {
  final ThemeMode themeMode;
  final double fontSize;
  final String fontFamily;
  final bool fullScreenProgress;

  const SettingsState({
    required this.themeMode,
    required this.fontSize,
    required this.fontFamily,
    required this.fullScreenProgress,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    String? fontFamily,
    bool? fullScreenProgress,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      fullScreenProgress: fullScreenProgress ?? this.fullScreenProgress,
    );
  }
}

const defaultSettings = SettingsState(
  themeMode: ThemeMode.system,
  fontSize: 16.0,
  fontFamily: 'Roboto',
  fullScreenProgress: false,
);

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(defaultSettings) {
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final themeStr = _prefs.getString('themeMode') ?? 'system';
      final fontSize = _prefs.getDouble('fontSize') ?? 16.0;
      final fontFamily = _prefs.getString('fontFamily') ?? 'Roboto';
      final fullScreenProgress = _prefs.getBool('fullScreenProgress') ?? false;

      state = SettingsState(
        themeMode: ThemeMode.values.firstWhere(
              (e) => e.toString() == 'ThemeMode.$themeStr',
          orElse: () => ThemeMode.system,
        ),
        fontSize: fontSize,
        fontFamily: fontFamily,
        fullScreenProgress: fullScreenProgress,
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
      state = defaultSettings;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _prefs.setString('themeMode', mode.toString().split('.').last);
      state = state.copyWith(themeMode: mode);
    } catch (e) {
      debugPrint('Error setting theme mode: $e');
    }
  }

  Future<void> setFontSize(double size) async {
    try {
      await _prefs.setDouble('fontSize', size);
      state = state.copyWith(fontSize: size);
    } catch (e) {
      debugPrint('Error setting font size: $e');
    }
  }

  Future<void> setFontFamily(String family) async {
    try {
      await _prefs.setString('fontFamily', family);
      state = state.copyWith(fontFamily: family);
    } catch (e) {
      debugPrint('Error setting font family: $e');
    }
  }

  Future<void> setFullScreenProgress(bool value) async {
    try {
      await _prefs.setBool('fullScreenProgress', value);
      state = state.copyWith(fullScreenProgress: value);
    } catch (e) {
      debugPrint('Error setting full screen progress: $e');
    }
  }

  ThemeData getTheme(bool isDark) {
    try {
      return ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        textTheme: GoogleFonts.getTextTheme(
          state.fontFamily,
          ThemeData(brightness: isDark ? Brightness.dark : Brightness.light)
              .textTheme
              .apply(bodyColor: isDark ? Colors.white : Colors.black87),
        ).apply(
          bodyColor: isDark ? Colors.white : Colors.black87,
          displayColor: isDark ? Colors.white : Colors.black,
        ),
      );
    } catch (e) {
      debugPrint('Error creating theme: $e');
      return ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
      );
    }
  }
}

final settingsProvider =
StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});