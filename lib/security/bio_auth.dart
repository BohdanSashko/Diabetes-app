import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/start_page.dart';
import '../pages/sign_up.dart';

class BiometricAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Biometric support check failed: $e');
      return false;
    }
  }

  Future<void> checkBiometric(
      BuildContext context,
      Widget failScreen, {
        required bool setupMode,
      }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan fingerprint to continue',
      );

      if (!authenticated) {
        debugPrint('❌ Fingerprint failed');
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => failScreen),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      String email = prefs.getString('biometricEmail') ?? '';

      if (email.isEmpty) {
        debugPrint('⚠️ No biometric email found');
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => failScreen),
          );
        }
        return;
      }

      if (setupMode) {
        await prefs.setBool('isBiometricEnabled', true);
      }

      debugPrint('✅ Biometric login success: $email');

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StartPage(initialEmail: email),
          ),
        );
      }
    } catch (e) {
      debugPrint('💥 Biometric error: $e');
    }
  }
}
