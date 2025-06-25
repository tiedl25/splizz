import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeCubit manages the theme mode based on persisted settings
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences prefs;
  
  ThemeCubit(this.prefs)
      : super(_getInitialTheme(prefs));

  // Initialize theme mode based on shared preferences
  static ThemeMode _getInitialTheme(SharedPreferences prefs) {
    bool systemTheme = prefs.getBool('systemTheme') ?? true;
    bool darkMode = prefs.getBool('darkMode') ?? false;
    return systemTheme ? ThemeMode.system : (darkMode ? ThemeMode.dark : ThemeMode.light);
  }

  // Toggle system theme option. For example when a switch is toggled in settings.
  Future<void> toggleSystemTheme(bool value) async {
    await prefs.setBool('systemTheme', value);
    if (value) {
      emit(ThemeMode.system);
    } else {
      // Optionally maintain previous darkMode setting if system theme is off.
      bool darkMode = prefs.getBool('darkMode') ?? false;
      emit(darkMode ? ThemeMode.dark : ThemeMode.light);
    }
  }
  
  // Toggle dark mode when system theme is disabled.
  Future<void> toggleDarkMode(bool value) async {
    await prefs.setBool('darkMode', value);
    emit(value ? ThemeMode.dark : ThemeMode.light);
  }
}