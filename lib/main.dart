import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/pages/auth/sign_in.dart';
import 'package:diabetes_app/pages/home/start_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:diabetes_app/pages/home/questions_before_start.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin(); // 🔹 Глобальный экземпляр плагина — так приложение может вызывать нотификации откуда угодно.

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
  InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings);
  // 🔹 Инициализация локальных уведомлений. Без initialize()
  //    Android не позволит приложению показывать нотификации.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhzrpjcwwfylcyefwcxu.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoenJwamN3d2Z5bGN5ZWZ3Y3h1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTA0NjMsImV4cCI6MjA3NzE4NjQ2M30.D3Oa_wj7kK7BDcVNAL2-hД1m-XFG1wfydX4tEjIkjdI',
    debug: true,
  );
  // 🔹 Подключение к Supabase происходит до runApp().
  //    Это важно, чтобы весь UI уже имел доступ к Supabase.instance.

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';

    // 🔹 Сохраняем тему как строку (light/dark/system),
    //    а тут переводим строку обратно в ThemeMode.
    setState(() {
      _themeMode = switch (themeString) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  void updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);

    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaWell',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: const Color(0xFF009FCC)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF009FCC),
          secondary: Color(0xFF007BA7),
          surface: Color(0xFF0E1A24),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true; // 🔹 Пока проверяем — показываем загрузку
  bool _isLoggedIn = false;
  bool _needsQuestions = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      // 🔹 Если user == null — значит человек НЕ авторизован.
      setState(() {
        _isLoggedIn = false;
        _checking = false;
      });
      return;
    }

    // 🔹 Пытаемся получить профиль пользователя из таблицы user_profiles
    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle(); // возвращает либо запись, либо null, без ошибки

    // 🔹 Если нет профиля или не заполнено поле diabetes_type → нужно задать вопросы.
    final needsQuestions =
        profile == null || profile['diabetes_type'] == null;

    setState(() {
      _isLoggedIn = true;
      _needsQuestions = needsQuestions;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        // 🔹 Показываем индикатор загрузки,
        //    чтобы избежать дерганья между экранами.
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ Пользователь НЕ авторизован → на страницу входа
    if (!_isLoggedIn) {
      return const SignInPage();
    }

    // 🟡 Пользователь авторизован, но профиль НЕ заполнен → задаем вопросы
    if (_needsQuestions) {
      return DiabetesQuestionPage(
        onFinished: () async {
          if (!mounted) return;

          // 🔹 После завершения вопросов переходим на главную
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StartPage(
                initialEmail: Supabase.instance.client.auth.currentUser?.email ?? '',
              ),
            ),
          );
        },
      );
    }

    // 🟢 Профиль заполнен → на главную страницу
    return StartPage(
      initialEmail:
      Supabase.instance.client.auth.currentUser?.email ?? '',
    );
  }
}
