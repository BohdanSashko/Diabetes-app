import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reg_page.dart';
import 'start_page.dart';
import 'forgot_password.dart';
import 'questions_before_start.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class SignUpPage extends StatefulWidget {
  final void Function(bool)? onThemeChanged; // optional callback for theme toggle

  const SignUpPage({super.key, this.onThemeChanged});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // 🔹 Sign in with Supabase
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _error('Email and password are required.');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('biometricEmail', email);

        final firstLoginDone = prefs.getBool('firstLoginDone') ?? false;

        if (!mounted) return;

        if (!firstLoginDone) {
          // ✅ show diabetes questionnaire only on FIRST login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DiabetesQuestionPage(
                onFinished: () async {
                  await prefs.setBool('firstLoginDone', true);
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StartPage(initialEmail: email),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          // ✅ skip questionnaire for next logins
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StartPage(initialEmail: email),
            ),
          );
        }
      } else {
        _error('Invalid credentials. Please try again.');
      }
    } on AuthException catch (e) {
      _error(e.message);
    } catch (e) {
      _error('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onBackground.withOpacity(0.8);

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/images/DiaWell.png'
                      : 'assets/images/DiaWell_dark.png',
                  width: 140,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your daily diabetes companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),

                const SizedBox(height: 28),

                _textField(
                  _emailCtrl,
                  "Email",
                  isPassword: false,
                  scheme: scheme,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                _textField(
                  _pwdCtrl,
                  "Password",
                  isPassword: true,
                  scheme: scheme,
                  textColor: textColor,
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text("Continue"),
                  ),
                ),

                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: Text(
                    "Create new account",
                    style: TextStyle(color: scheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                  ),
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Custom textfield builder (now theme-based)
  Widget _textField(
      TextEditingController controller,
      String hint, {
        required bool isPassword,
        required ColorScheme scheme,
        required Color textColor,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscure,
      textAlign: TextAlign.center,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: scheme.onSurface.withOpacity(0.6),
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : null,
      ),
    );
  }
}
