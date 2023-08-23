import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0x522B2B2B),
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    background: Color(0xFF2B2B2B),
    surface: Color(0xFF383838),
  ),
  dividerColor: Colors.white54,
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white
    )
  ),
);