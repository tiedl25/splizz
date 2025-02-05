import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0),
  colorScheme: const ColorScheme.light(
      surface: Color(0xFFEFEFEF),
      surfaceContainer: Color.fromARGB(255, 196, 196, 196),
      surfaceTint: Colors.deepPurpleAccent),
  dividerColor: Colors.black,
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
    foregroundColor: Colors.black,
  )),
);
