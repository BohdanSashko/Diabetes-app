// lib/pages/sign_up.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_app/security/bio_auth.dart';
import '../main.dart' show secureUsersBox, secureSessionBox;
import '../security/secure_hive.dart'; // for hashPassword
import 'reg_page.dart';
import 'start_page.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _canUseBiometric = false;//check if biometrics supported

  late final Box usersBox;
  late final Box sessionBox;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box(secureUsersBox);
    sessionBox = Hive.box(secureSessionBox);
    _checkBiometricSupport(); // check support
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  // 🔹 Snackbar shortcut
  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // 🔹 Regular email/password login
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _pwdCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _error('Please fill in email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (!usersBox.containsKey(email)) {
        throw Exception('No account found for this email.');
      }

      final record = Map<String, dynamic>.from(usersBox.get(email));
      final salt = record['salt'] as String? ?? '';
      final storedHash = record['hash'] as String? ?? '';

      final attemptHash = hashPassword(pass, salt);
      if (attemptHash != storedHash) {
        throw Exception('Incorrect password.');
      }

      //  Save session
      await sessionBox.put('currentUser', email);

      //  Save biometric email (for next fingerprint login)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometricEmail', email);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StartPage(initialEmail: email)),
      );
    } catch (e) {
      _error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🔹 Register page
  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  // 🔹 Biometric check support
  Future<void> _checkBiometricSupport() async {
    final bio = BiometricAuth();
    final canUse = await bio.canCheckBiometrics();
    if (mounted) setState(() => _canUseBiometric = canUse);
  }

  // 🔹 Biometric login
  Future<void> _bioLogin() async {
    final bio = BiometricAuth();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometricEmail', _emailCtrl.text.trim().toLowerCase());

    bio.checkBiometric(
      context,
      StartPage(initialEmail: _emailCtrl.text.trim().toLowerCase()), //  direct link
      const SignUpPage(), // fallback
      setupMode: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F4FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo + tagline
                Image.asset('assets/images/DiaWell.png', width: 140, height: 140),
                const SizedBox(height: 8),
                const Text(
                  'Your daily diabetes companion',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 28),

                // Card with form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black12,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDecoration('Enter email'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pwdCtrl,
                        obscureText: _obscure,
                        textAlign: TextAlign.center,
                        decoration: _fieldDecoration('Enter password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.black54,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 12),

                      // Create account
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: _openRegister,
                          style: TextButton.styleFrom(
                            foregroundColor: kBrandBlue,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          child: const Text('Create new account'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _signIn,
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: kBrandBlue.withOpacity(0.4),
                          ),
                        ),
                      ),

                      //  Biometric Login Button
                      if (_canUseBiometric) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _bioLogin,
                          icon: const Icon(Icons.fingerprint, size: 26),
                          label: const Text('Login with Biometrics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kBrandBlue,
                            side: const BorderSide(color: kBrandBlue, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // (Optional) Forgot password placeholder
                TextButton(
                  onPressed: () => _error('Password reset is not implemented yet.'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FCFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}
