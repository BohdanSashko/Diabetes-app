import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_app/pages/home/questions_before_start.dart';
import 'package:diabetes_app/pages/home/start_page.dart';
import 'reg_page.dart';
import 'forgot_password.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();

  bool _obscure = true; // Флаг для скрытия пароля
  bool _loading = false; // Флаг загрузки

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  // Показываем сообщение об ошибке
  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // 🔹 Авторизация и проверка наличия профиля пользователя
  Future<void> _signIn() async {
    FocusScope.of(context).unfocus(); // Скрываем клавиатуру
    final email = _emailCtrl.text.trim();
    final password = _pwdCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _error('Please enter your email and password.');
      return;
    }

    setState(() => _loading = true); // Включаем индикатор загрузки

    try {
      // Выполняем вход через Supabase
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        final user = response.user;
        if (user == null) {
          _error('Failed to retrieve user data.');
          return;
        }

        // ✅ Проверяем наличие профиля пользователя в базе
        final data = await supabase
            .from('user_profiles')
            .select('diabetes_type')
            .eq('id', user.id)
            .maybeSingle();

        // Сохраняем последний email локально
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastEmail', email);

        if (!mounted) return;

        if (data == null || data['diabetes_type'] == null) {
          // 🩸 Новый пользователь — показываем вопросы перед стартом
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Future.microtask(() {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiabetesQuestionPage(
                      onFinished: () async {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartPage(
                              initialEmail: user.email ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            });
          });
        } else {
          // ✅ Профиль уже есть — сразу открываем главную страницу
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Future.microtask(() {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => StartPage(initialEmail: email),
                  ),
                );
              }
            });
          });
        }
      } else {
        _error('Invalid credentials. Please try again.');
      }
    } on AuthException catch (e) {
      // Обработка ошибок авторизации
      _error(e.message);
    } catch (e) {
      // Обработка неожиданных ошибок
      _error('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false); // Выключаем индикатор
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип приложения
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
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Поля для ввода email и пароля
                textField(_emailCtrl, "Email", false, scheme),
                const SizedBox(height: 16),
                textField(_pwdCtrl, "Password", true, scheme),
                const SizedBox(height: 18),

                // Кнопка входа
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _loading ? null : _signIn, // Вызов авторизации
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

                const SizedBox(height: 18),
                // Кнопка регистрации нового пользователя
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text(
                    "Create new account",
                    style: TextStyle(color: kBrandBlue),
                  ),
                ),
                // Кнопка восстановления пароля
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  ),
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Компонент текстового поля
  Widget textField(
      TextEditingController controller,
      String hint,
      bool isPassword,
      ColorScheme scheme,
      ) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscure, // Скрытие текста для пароля
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
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
          onPressed: () => setState(() => _obscure = !_obscure), // Переключение видимости
        )
            : null,
      ),
    );
  }
}
