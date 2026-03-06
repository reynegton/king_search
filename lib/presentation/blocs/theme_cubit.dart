import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences prefs;
  static const String _themeKey = 'isDarkTheme';

  ThemeCubit({required this.prefs}) : super(_getInitialTheme(prefs));

  static ThemeMode _getInitialTheme(SharedPreferences prefs) {
    final isDark = prefs.getBool(_themeKey);
    if (isDark == null) return ThemeMode.light; // fallback padrão
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() async {
    final bool willBeDark =
        (state == ThemeMode.light || state == ThemeMode.system);
    await prefs.setBool(_themeKey, willBeDark);
    emit(willBeDark ? ThemeMode.dark : ThemeMode.light);
  }

  void setTheme(ThemeMode mode) async {
    if (mode != ThemeMode.system) {
      await prefs.setBool(_themeKey, mode == ThemeMode.dark);
    } else {
      await prefs.remove(_themeKey);
    }
    emit(mode);
  }
}
