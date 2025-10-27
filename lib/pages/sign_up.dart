import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_app/security/bio_auth.dart';
import 'reg_page.dart';
import 'start_page.dart';
import 'forgot_password.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _error('Email and password required');
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometricEmail', email);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StartPage(initialEmail: email)),
      );
    } on FirebaseAuthException catch (e) {
      _error(e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkBiometricSupport() async {
    final bio = BiometricAuth();
    final canUse = await bio.canCheckBiometrics();
    if (mounted) setState(() => _canUseBiometric = canUse);
  }

  Future<void> _bioLogin() async {
    final bio = BiometricAuth();
    await bio.checkBiometric(
      context,
      const SignUpPage(),
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
              children: [
                Image.asset('assets/images/DiaWell.png', width: 140),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailCtrl,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(hintText: "Email"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pwdCtrl,
                  obscureText: _obscure,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Password",
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: const Text("Continue"),
                ),
                if (_canUseBiometric) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _bioLogin,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text("Login with Biometrics"),
                  ),
                ],
                TextButton(
                  onPressed: () =>
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterPage())),
                  child: const Text("Create new account"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                  child: const Text("Forgot password?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
