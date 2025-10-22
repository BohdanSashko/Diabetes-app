import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../pages/start_page.dart';
import '../pages/sign_up.dart';

class BiometricAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if the device supports biometrics (fingerprint, FaceID, etc.)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('❌ Biometric check failed: $e');
      return false;
    }
  }

  /// Performs biometric authentication and handles session/login logic.
  Future<void> checkBiometric(
      BuildContext context,
      Widget successScreen,
      Widget failScreen, {
        bool setupMode = false,
      }) async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        debugPrint('❌ No biometric hardware found.');
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        debugPrint('❌ Authentication failed');
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => failScreen),
          );
        }
        return;
      }

      // ✅ STEP 1: Load prefs
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(const Duration(milliseconds: 100)); // timing fix
      String email = prefs.getString('biometricEmail') ?? '';

      // ✅ STEP 2: Optional fallback to Hive session
      final sessionBox = Hive.box('secure_session');
      if (email.isEmpty) {
        email = sessionBox.get('currentUser') ?? '';
        debugPrint('⚠️ biometricEmail not found in prefs, fallback used: $email');
      }

      // ✅ STEP 3: Mark biometrics enabled (setup only)
      if (setupMode) {
        prefs.setBool('isbiometricenabled', true);
      }

      // ✅ STEP 4: Save session
      if (email.isNotEmpty) {
        await sessionBox.put('currentUser', email);
        debugPrint('✅ Biometric login success: $email');

        // ✅ STEP 5: Navigate AFTER saving
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StartPage(initialEmail: email),
            ),
          );
        }
      } else {
        debugPrint('❌ No email found for biometric login');
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => failScreen),
          );
        }
      }
    } catch (e) {
      debugPrint('💥 Biometric auth error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
