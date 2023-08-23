import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
      backgroundColor: Color(0x886E6E6E),
      elevation: 0
  ),
  colorScheme: const ColorScheme.light(
    background: Color(0xFFEFEFEF),
    surface: Color(0xFFCECECE)
  ),
  dividerColor: Colors.black,
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: Colors.black
        )
    )
);