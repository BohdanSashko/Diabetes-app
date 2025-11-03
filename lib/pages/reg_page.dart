import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_email.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;
  bool _loading = false;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  // -------------------- Registration --------------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_agree) {
      _showError('Please complete all fields and accept terms.');
      return;
    }

    setState(() => _loading = true);

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _pwdCtrl.text.trim();

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (authResponse.user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerifyEmailPage(userEmail: email)),
        );
      } else {
        _showError('Failed to register user.');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onBackground.withOpacity(0.85);

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Create account'),
        centerTitle: true,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _input(
                    _nameCtrl,
                    'Full name',
                    Icons.person_outline,
                    _validateName,
                    scheme,
                  ),
                  const SizedBox(height: 12),
                  _input(
                    _emailCtrl,
                    'Email',
                    Icons.email_outlined,
                    _validateEmail,
                    scheme,
                  ),
                  const SizedBox(height: 12),
                  _input(
                    _pwdCtrl,
                    'Password',
                    Icons.lock_outline,
                    _validatePassword,
                    scheme,
                    obscure: _obscure1,
                    toggle: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  const SizedBox(height: 12),
                  _input(
                    _pwd2Ctrl,
                    'Confirm password',
                    Icons.lock_outline,
                    _validatePasswordConfirm,
                    scheme,
                    obscure: _obscure2,
                    toggle: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                        activeColor: kBrandBlue,
                      ),
                      Expanded(
                        child: Text(
                          'I agree to the Terms and Privacy Policy',
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                          : const Text(
                        'Sign up',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- Validators --------------------
  String? _validateName(String? v) =>
      (v == null || v.trim().length < 2) ? 'Enter your name' : null;

  String? _validateEmail(String? v) {
    final email = v?.trim() ?? '';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      return 'Invalid email';
    }
    return null;
  }

  String? _validatePassword(String? v) =>
      (v == null || v.length < 6) ? 'Min 6 characters' : null;

  String? _validatePasswordConfirm(String? v) =>
      (v != _pwdCtrl.text) ? 'Passwords do not match' : null;

  // -------------------- Input Builder --------------------
  Widget _input(
      TextEditingController c,
      String hint,
      IconData icon,
      String? Function(String?) validator,
      ColorScheme scheme, {
        bool obscure = false,
        VoidCallback? toggle,
      }) {
    return TextFormField(
      controller: c,
      validator: validator,
      obscureText: obscure,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: scheme.primary),
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: toggle != null
            ? IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: scheme.onSurface.withOpacity(0.6),
          ),
          onPressed: toggle,
        )
            : null,
      ),
    );
  }
}
