import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0
  ),
  colorScheme: const ColorScheme.light(
    background: Color(0xFFEFEFEF),
    surface: Color(0xFFDADADA),
    surfaceTint: Colors.deepPurpleAccent
  ),
  dividerColor: Colors.black,
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: Colors.black,
      )
  ),
  textTheme: const TextTheme(
      labelLarge: TextStyle(color: Colors.deepPurpleAccent)
  )
);