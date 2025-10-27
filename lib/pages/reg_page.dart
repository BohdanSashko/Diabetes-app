// C:/Users/Codersbay/diabetes_app/lib/pages/reg_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sign_up.dart'; // Make sure sign_up.dart is the correct login page

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

  // It's good practice to make these final as they won't be reassigned
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  // --- Validators ---
  String? _nameValidator(String? v) {
    if (v == null || v.trim().length < 2) return 'Please enter a valid name';
    return null;
  }

  String? _emailValidator(String? v) {
    final email = v?.trim() ?? "";
    // Using a more common and slightly more robust regex
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _pwdValidator(String? v) {
    if (v == null || v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _pwd2Validator(String? v) {
    if (v != _pwdCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _register() async {
    // 1. IMPROVEMENT: Check if the widget is still mounted before proceeding
    if (!mounted) return;

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (!_agree) {
      _showError('You must agree to the Terms & Privacy Policy');
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _pwdCtrl.text; // No need to trim again
      final name = _nameCtrl.text.trim();

      // Create Firebase user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Null check the user object for safety
      final user = credential.user;
      if (user == null) {
        throw Exception("User creation failed, please try again.");
      }

      // Save user profile to Firestore
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(), // 2. IMPROVEMENT: Use server timestamp
      });

      // Send verification email
      await user.sendEmailVerification();

      // 3. IMPROVEMENT: Check mounted status before showing SnackBar or navigating
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account created! Please verify your email before logging in.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignUpPage()),
            (route) => false, // This removes all previous routes from the stack
      );
      // ... inside _register()
    } on FirebaseAuthException catch (e) {
      // This part is fine, it handles specific auth errors
      if (mounted) {print("FIREBASE AUTH ERROR: Code: ${e.code}, Message: ${e.message}"); // Also print the detailed error
      _showError(_firebaseError(e.code));
      }
    } catch (e, s) { // Also catch the stack trace 's'
      // THIS IS THE CRITICAL CHANGE
      // We will now print the detailed error to the debug console.
      print("A GENERIC ERROR OCCURRED: $e");
      print("STACK TRACE: $s");
      if (mounted) _showError("An unexpected error occurred. Check the debug console for details.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please log in.';
      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger one.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An unknown error occurred. Please try again.';
    }
  }

  void _showError(String msg) {
    // Check mounted status here as well for safety
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  // --- Build Method and Widgets ---
  // No changes needed here, the existing code is great.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F4FA),
      appBar: AppBar(
        title: const Text('Create account'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _input(_nameCtrl, 'Full name', Icons.person_outline, _nameValidator),
                  const SizedBox(height: 12),
                  _input(_emailCtrl, 'Email', Icons.email_outlined, _emailValidator),
                  const SizedBox(height: 12),
                  _input(_pwdCtrl, 'Password', Icons.lock_outline, _pwdValidator,
                      obscure: _obscure1,
                      toggle: () => setState(() => _obscure1 = !_obscure1)),
                  const SizedBox(height: 12),
                  _input(_pwd2Ctrl, 'Confirm password', Icons.lock_outline,
                      _pwd2Validator,
                      obscure: _obscure2,
                      toggle: () => setState(() => _obscure2 = !_obscure2)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                        activeColor: kBrandBlue,
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms and Privacy Policy',
                          style: TextStyle(fontSize: 13),
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
                        backgroundColor: kBrandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : const Text('Sign up', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  Widget _input(TextEditingController c, String hint, IconData icon,
      String? Function(String?) validator,
      {bool obscure = false, VoidCallback? toggle}) {
    return TextFormField(
      controller: c,
      validator: validator,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF9FCFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        suffixIcon: toggle != null
            ? IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        )
            : null,
      ),
    );
  }
}
