import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _pwd1Ctrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _pwd1Ctrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final p1 = _pwd1Ctrl.text.trim();
    final p2 = _pwd2Ctrl.text.trim();

    if (p1.length < 6) {
      _msg("Password must be at least 6 characters", isErr: true);
      return;
    }

    if (p1 != p2) {
      _msg("Passwords do not match", isErr: true);
      return;
    }

    setState(() => _loading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: p1),
      );

      if (!mounted) return;

      _msg("Password updated successfully!", isErr: false);

      Navigator.pop(context); // назад на SignIn
    } on AuthException catch (e) {
      _msg(e.message, isErr: true);
    } catch (e) {
      _msg("Unexpected error: $e", isErr: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String text, {bool isErr = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isErr ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Set New Password"),
        centerTitle: true,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              "Enter your new password",
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _pwd1Ctrl,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: "New password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscure1 = !_obscure1);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _pwd2Ctrl,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: "Confirm password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscure2 = !_obscure2);
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                child: _loading
                    ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                    : const Text("Save New Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
