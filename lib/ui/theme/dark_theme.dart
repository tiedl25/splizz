import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    surface: Color.fromARGB(255, 38, 39, 45),
    surfaceContainer: Color.fromARGB(255, 46, 47, 57),
    surfaceTint: Colors.cyanAccent,
  ),
  dividerColor: Colors.white54,
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
    foregroundColor: Colors.white,
  )),
);
