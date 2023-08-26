import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    background: Color(0xFF2B2B2B),
    surface: Color(0xFF383838),
  ),
  dividerColor: Colors.white54,
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
    )
  ),
  textTheme: const TextTheme(
    labelLarge: TextStyle(color: Colors.white)
  )
);