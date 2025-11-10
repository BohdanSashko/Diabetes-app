import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diabetes_app/pages/auth/reg_page.dart';
import 'package:diabetes_app/pages/auth/sign_in.dart';
import 'package:diabetes_app/pages/home/start_page.dart';
import 'package:diabetes_app/pages/home/questions_before_start.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhzrpjcwwfylcyefwcxu.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoenJwamN3d2Z5bGN5ZWZ3Y3h1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTA0NjMsImV4cCI6MjA3NzE4NjQ2M30.D3Oa_wj7kK7BDcVNAL2-hD1m-XFG1wfydX4tEjIkjdI',
    debug: true,
  );

  // 🟩 Загружаем сохранённую тему до запуска
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString('themeMode') ?? 'system';
  final savedTheme = switch (themeString) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  runApp(MyApp(initialTheme: savedTheme));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialTheme;
  const MyApp({super.key, required this.initialTheme});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialTheme;
  }

  /// 🔹 Вызывается из SettingsPage
  Future<void> updateThemeMode(ThemeMode mode) async {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009FCC)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF009FCC),
          secondary: Color(0xFF007BA7),
          background: Color(0xFF0E1A24),
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
  bool _checking = true;
  bool _isLoggedIn = false;
  bool _firstLoginDone = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    // 👇 слушаем Supabase изменения
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        setState(() => _isLoggedIn = true);
      } else if (data.event == AuthChangeEvent.signedOut) {
        setState(() => _isLoggedIn = false);
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final firstLogin = prefs.getBool('firstLoginDone') ?? false;

    setState(() {
      _isLoggedIn = user != null;
      _firstLoginDone = firstLogin;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) return const SignInPage();

    if (!_firstLoginDone) {
      return DiabetesQuestionPage(
        onFinished: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('firstLoginDone', true);
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StartPage(
                  initialEmail:
                  Supabase.instance.client.auth.currentUser?.email ?? '',
                ),
              ),
            );
          }
        },
      );
    }

    return StartPage(
      initialEmail: Supabase.instance.client.auth.currentUser?.email ?? '',
    );
  }
}
