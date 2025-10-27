// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 1. Import App Check
import 'firebase_options.dart';

import 'pages/sign_up.dart';
import 'pages/start_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Activate App Check
  // This tells Firebase to start generating the necessary tokens.
  // For Android, it uses Play Integrity by default.
  await FirebaseAppCheck.instance.activate(
    // You can also use webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

  await FirebaseAuth.instance.setLanguageCode("en");

  runApp(const MyApp());
}

// ... The rest of your MyApp class and StreamBuilder remains the same.
class MyApp extends StatelessWidget {
// ...

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaWell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF009FCC)),
      // Use a StreamBuilder to listen to auth changes in real-time
      home: StreamBuilder<User?>(
        // This stream emits a new value whenever the user logs in or out
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Handle errors from the stream itself
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Something went wrong. Please restart the app.")),
            );
          }

          // 2. Show a loading indicator while waiting for the first auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 3. Check if the user data exists (i.e., user is logged in)
          if (snapshot.hasData) {
            // User is logged in, now check if their email is verified
            User user = snapshot.data!;
            if (user.emailVerified) {
              // User is logged in and verified -> Go to StartPage
              // You can add back the SharedPreferences logic here if needed
              return StartPage(initialEmail: user.email ?? "");
            }
          }

          // 4. If snapshot has no data, user is logged out -> Go to SignUpPage
          return const SignUpPage();
        },
      ),
    );
  }
}
