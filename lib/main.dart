// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/sign_up.dart';
import 'pages/start_page.dart';
import 'pages/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhzrpjcwwfylcyefwcxu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoenJwamN3d2Z5bGN5ZWZ3Y3h1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTA0NjMsImV4cCI6MjA3NzE4NjQ2M30.D3Oa_wj7kK7BDcVNAL2-hD1m-XFG1wfydX4tEjIkjdI',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaWell',
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: ThemeMode.system,
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Something went wrong.")),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data!.session != null) {
            final session = snapshot.data!.session!;
            return StartPage(initialEmail: session.user.email ?? '');
          }
          return const SignUpPage();
        },
      ),
    );
  }
}