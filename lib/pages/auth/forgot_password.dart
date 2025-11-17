import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailCtrl = TextEditingController(); // Контроллер для поля email
  bool _loading = false; // Индикатор загрузки

  final supabase = Supabase.instance.client; // Клиент Supabase

  @override
  void dispose() {
    _emailCtrl.dispose(); // Освобождаем контроллер
    super.dispose();
  }

  // 🔹 Сброс пароля
  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    // Проверка на пустое поле
    if (email.isEmpty) {
      _showMsg('Please enter your registered email.', isError: true);
      return;
    }

    setState(() => _loading = true); // Включаем индикатор
    try {
      // Отправка запроса на сброс пароля
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMsg('✅ Password reset email sent to $email.', isError: false);
    } on AuthException catch (e) {
      // Ошибка аутентификации
      _showMsg('⚠️ ${e.message}', isError: true);
    } catch (e) {
      // Любая другая ошибка
      _showMsg('⚠️ Unexpected error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false); // Выключаем индикатор
    }
  }

  // 🔹 Показ сообщения пользователю
  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: colorScheme.surface, // ✅ Динамический фон для темы
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
        backgroundColor: colorScheme.primary.withOpacity(0.1),
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface, // Цвет контейнера под тему
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_reset, size: 60, color: colorScheme.primary), // Иконка сброса пароля
                  const SizedBox(height: 10),
                  Text(
                    'Reset your password', // Заголовок
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email address and we’ll send you a reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Поле для ввода email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Кнопка отправки запроса на сброс пароля
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _resetPassword,
                      icon: const Icon(
                        Icons.email_outlined,
                        color: Colors.white,
                      ),
                      label: _loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Send Reset Link'),
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
                  const SizedBox(height: 16),
                  // Кнопка возврата на экран входа
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Sign In',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
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
}
