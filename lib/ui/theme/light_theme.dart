import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
      elevation: 0),
  colorScheme: const ColorScheme.light(
      surface: Color.fromARGB(255, 238, 236, 245),
      surfaceContainer: Color.fromARGB(255, 227, 224, 236),
      surfaceTint: Colors.deepPurpleAccent),
  dividerColor: Colors.black,
  textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
    foregroundColor: Colors.black,
  )),
);
