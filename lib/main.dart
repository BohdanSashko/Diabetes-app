import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth/sign_in.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/home/start_page.dart';
import 'pages/home/questions_before_start.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const Color kBrandBlue = Color(0xFF009FCC);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhzrpjcwwfylcyefwcxu.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoenJwamN3d2Z5bGN5ZWZ3Y3h1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTA0NjMsImV4cCI6MjA3NzE4NjQ2M30.D3Oa_wj7kK7BDcVNAL2-hD1m-XFG1wfydX4tEjIkjdI',
    debug: true,
  );

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
    _listenAuthEvents();
  }

  // ---------------------------------------------
  // LOAD SELECTED THEME FROM SHARED PREFERENCES
  // ---------------------------------------------
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


  // LISTEN FOR SUPABASE AUTH EVENTS
  // (important for password reset deeplink)
  void _listenAuthEvents() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final e = event.event;

      if (e == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "DiaWell",
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBrandBlue),
        useMaterial3: true,
      ),

      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: kBrandBlue,
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
  bool _loading = true;
  bool _loggedIn = false;
  bool _firstLoginDone = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // ---------------------------------------------
  // CHECK LOGIN + local firstLoginDone
  // ---------------------------------------------
  Future<void> _checkLogin() async {
    final user = Supabase.instance.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getBool('firstLoginDone') ?? false;

    setState(() {
      _loggedIn = user != null;
      _firstLoginDone = first;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_loggedIn) {
      return const SignInPage();
    }

    // FIRST LOGIN? show questions
    if (!_firstLoginDone) {
      return DiabetesQuestionPage(
        onFinished: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('firstLoginDone', true);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StartPage(
                initialEmail:
                Supabase.instance.client.auth.currentUser?.email ?? "",
              ),
            ),
          );
        },
      );
    }

    // NORMAL LOGIN
    return StartPage(
      initialEmail:
      Supabase.instance.client.auth.currentUser?.email ?? "",
    );
  }
}
