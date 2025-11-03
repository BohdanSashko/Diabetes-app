// lib/utils.dart
import 'package:flutter/material.dart';

class Utils {
  // This is a static method that can be called from anywhere in the app
  static void showSnackBar(BuildContext context, String text) {
    // Hide any currently displayed snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.redAccent, // Good for showing errors
      ),
    );
  }
}
