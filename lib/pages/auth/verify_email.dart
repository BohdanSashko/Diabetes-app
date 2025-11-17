import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
const Color kBrandBlue = Color(0xFF009FCC);

class VerifyEmailPage extends StatefulWidget {
  final String userEmail;

  const VerifyEmailPage({super.key, required this.userEmail});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = false;

  // Функция повторной отправки письма с подтверждением
  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      // Отправляем письмо через Supabase
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.userEmail,
      );

      if (mounted) {
        // Показываем сообщение об успешной отправке
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ A new verification email has been sent.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        // Показываем ошибку авторизации
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Показываем сообщение о неизвестной ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ An unexpected error occurred.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Снимаем индикатор загрузки
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFE3F4FA), // Фоновый цвет страницы
      appBar: AppBar(
        title: const Text("Verify Your Email"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Отключаем кнопку назад
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка письма
              const Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: kBrandBlue,
              ),
              const SizedBox(height: 24),

              // Текст инструкции
              const Text(
                'A verification link has been sent to:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Отображаем email пользователя
              Text(
                widget.userEmail,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Дополнительная инструкция
              const Text(
                'Please click the link in the email to continue. You can close this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Кнопка повторной отправки письма
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _resendVerificationEmail,
                icon: _isLoading
                    ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Icon(Icons.send_outlined),
                label: const Text('Resend Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
