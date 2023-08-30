import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    background: Color(0xFF282828),//2B2B2BFF
    surface: Color(0xFF383838),//0xFF383838
    surfaceTint: Colors.cyanAccent,
  ),
  dividerColor: Colors.white54,
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
    )
  ),
  textTheme: const TextTheme(
    labelLarge: TextStyle(color: Colors.cyanAccent)
  ),
);