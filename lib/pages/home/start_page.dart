import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/sign_in.dart';
import 'settings.dart';
import '../../data/services/user_service.dart';
import '../../pages/home/sugar_history_page.dart';
import '../../pages/home/log_insulin_page.dart';
import '../../pages/home/bolus_calculator_page.dart';
import '../../pages/home/insulin_history_page.dart';
import '../../pages/home/meal_history_page.dart';

final userService = UserService();

const Color kBrandBlue = Color(0xFF009FCC);

class StartPage extends StatefulWidget {
  final String initialEmail;

  const StartPage({super.key, required this.initialEmail});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  String? _name;
  String? _email;
  String? _diabetesType;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _email = widget.initialEmail;
    _loadUserData();
  }

  /// Loads user info from Supabase Auth and user_profiles table.
  /// Auth stores only email and metadata — diabetes-related data is inside user_profiles.
  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // read display name from Auth metadata
      final userName = user.userMetadata?['name'] as String?;

      // read diabetes profile from database
      final profile = await userService.fetchUserProfile();

      setState(() {
        _name = userName ?? '';
        _email = user.email;
        _diabetesType = profile?.diabetesType ?? 'Not specified';
      });
    }
  }

  /// Fully signs the user out: clears local storage + Supabase session.
  Future<void> _signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();        // clear local app settings/cache
      await _supabase.auth.signOut(); // invalidate session
    } catch (e) {
      debugPrint("Error during sign out: $e");
    }

    if (!mounted) return;

    // remove all routes and go back to sign-in page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
    );
  }

  /// Utility builder for Drawer items.
  ListTile _drawerTile(IconData icon, String title, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // If name exists, show "Hi John"; Otherwise, fallback to email.
    final greeting = _name?.isNotEmpty == true
        ? "Hi, $_name"
        : "Hi, ${_email ?? 'Guest'}";

    return Scaffold(
      backgroundColor: scheme.surface,

      // ---------- APP BAR ----------
      appBar: AppBar(
        title: Text(
          'DiaWell',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.primary),
      ),

      // ---------- NAVIGATION DRAWER ----------
      drawer: Drawer(
        child: Container(
          color: scheme.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // User header card
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: scheme.primary),

                accountName: Text(
                  _name ?? 'User',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                accountEmail: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _email ?? 'Email',
                      style: TextStyle(
                        color: scheme.onPrimary.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diabetes type: ${_diabetesType ?? 'Not specified'}',
                      style: TextStyle(
                        color: scheme.onPrimary.withOpacity(0.9),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer navigation tiles
              _drawerTile(Icons.calculate, 'Bolus calculator', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BolusCalculatorPage(),
                  ),
                );
              }),

              _drawerTile(Icons.water_drop_outlined, 'Insulin history', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InsulinHistoryPage()),
                );
              }),

              _drawerTile(Icons.restaurant_menu_outlined, 'Meals & carbs', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealHistoryPage()),
                );
              }),

              _drawerTile(Icons.bar_chart_outlined, 'Sugar history', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SugarHistoryPage()),
                );
              }),

              _drawerTile(Icons.settings_outlined, 'Settings', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingsPage()),
                );
              }),

              const Divider(),

              // Sign out
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),

      // ---------- MAIN HOME CONTENT ----------
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 12),

              // Greeting text
              Center(
                child: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Main card with home actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: scheme.shadow.withOpacity(0.2),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    _HomeTile(
                      icon: Icons.monitor_heart_outlined,
                      title: 'Log insulin',
                      subtitle: 'Quickly add a reading',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LogInsulinPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1),

                    _HomeTile(
                      icon: Icons.calculate,
                      title: 'Bolus calculator',
                      subtitle: 'Smart insulin dose calculator',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BolusCalculatorPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1),

                    _HomeTile(
                      icon: Icons.healing,
                      title: 'Insulin history',
                      subtitle: 'Check your insulin history',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InsulinHistoryPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1),

                    _HomeTile(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Meals & carbs',
                      subtitle: 'Track meals and carbs',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MealHistoryPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1),

                    _HomeTile(
                      icon: Icons.show_chart_outlined,
                      title: 'View trends',
                      subtitle: 'Insights over time',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SugarHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable home menu tile widget.
class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {},    // avoid null errors

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // icon container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.primary),
            ),

            const SizedBox(width: 12),

            // title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: scheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
