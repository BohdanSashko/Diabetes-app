// lib/pages/theme.dart
import 'package:flutter/material.dart';

final ThemeData lightMode = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
        surface: Colors.white,
        primary: Colors.blue.shade400,
        secondary: Colors.blue.shade200,
        background: Colors.blue.shade50,
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
        surface: Colors.black,
        primary: Colors.blue.shade800,
        secondary: Colors.blue.shade700,
        background: Color(0xFF1E1E1E),
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
    ),
    textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white38),
    ),
);
