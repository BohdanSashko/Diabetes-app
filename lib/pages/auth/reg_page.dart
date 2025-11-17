import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_email.dart';
import '../../data/services/user_service.dart';

const Color kBrandBlue = Color(0xFF009FCC);
final userService = UserService(); // Сервис для работы с пользователем

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>(); // Ключ формы для валидации
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();

  bool _obscure1 = true; // Скрытие для поля пароля
  bool _obscure2 = true; // Скрытие для поля подтверждения пароля
  bool _agree = false; // Флаг согласия с условиями
  bool _loading = false; // Индикатор загрузки

  final _supabase = Supabase.instance.client; // Клиент Supabase

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  // 🔹 Регистрация пользователя
  Future<void> _register() async {
    // Проверка формы и согласия с условиями
    if (!_formKey.currentState!.validate() || !_agree) {
      _showError('Please complete all fields and accept terms.');
      return;
    }

    setState(() => _loading = true); // Включаем индикатор

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();
      final password = _pwdCtrl.text.trim();

      // ✅ Регистрация пользователя с deep link для верификации
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'diabetesapp://login-callback', // deep link
        data: {'name': name}, // Сохраняем имя в raw_user_meta_data
      );

      final user = authResponse.user;

      if (user != null) {
        // ✅ Показываем экран "Проверьте почту"
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerifyEmailPage(userEmail: email)),
        );
      } else {
        _showError('Check your email for verification link.');
      }

    } on AuthException catch (e) {
      // Обработка ошибок регистрации
      _showError(e.message);
    } catch (e) {
      // Обработка неожиданных ошибок
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false); // Выключаем индикатор
    }
  }

  // Показываем сообщение об ошибке
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface.withOpacity(0.85);

    return Scaffold(
      backgroundColor: scheme.surface,
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
              key: _formKey, // Форма с ключом для валидации
              child: Column(
                children: [
                  // Поля ввода с валидацией
                  _input(_nameCtrl, '(Only) First name', Icons.person_outline,
                      _validateName, scheme),
                  const SizedBox(height: 12),
                  _input(_emailCtrl, 'Email', Icons.email_outlined,
                      _validateEmail, scheme),
                  const SizedBox(height: 12),
                  _input(_pwdCtrl, 'Password', Icons.lock_outline,
                      _validatePassword, scheme,
                      obscure: _obscure1,
                      toggle: () => setState(() => _obscure1 = !_obscure1)),
                  const SizedBox(height: 12),
                  _input(_pwd2Ctrl, 'Confirm password', Icons.lock_outline,
                      _validatePasswordConfirm, scheme,
                      obscure: _obscure2,
                      toggle: () => setState(() => _obscure2 = !_obscure2)),
                  const SizedBox(height: 12),

                  // Checkbox для согласия с условиями
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

                  // Кнопка регистрации
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
                          : const Text('Sign up', style: TextStyle(fontSize: 16)),
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

  // -------------------- Валидация полей --------------------
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

  // 🔹 Компонент текстового поля с иконкой и возможностью скрытия
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
        fillColor: scheme.surfaceContainerHighest,
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
          onPressed: toggle, // Переключение видимости пароля
        )
            : null,
      ),
    );
  }
}
