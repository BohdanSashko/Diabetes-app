// lib/pages/theme.dart
import 'package:flutter/material.dart';

final ThemeData lightMode = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
        surface: Colors.white,
        primary: Colors.blue.shade400,
        secondary: Colors.blue.shade200,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
    ),
    textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
    ),
);

final ThemeData darkMode = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
        surface: Colors.black45,
        primary: Colors.blue.shade800,
        secondary: Colors.blue.shade700,
    ),
    scaffoldBackgroundColor: Colors.black54,
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
    ),
    textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white38),
    ),
);
