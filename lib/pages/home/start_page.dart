import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/sign_in.dart';
import 'settings.dart';
import '../../data/services/user_service.dart';
import '../../pages/home/sugar_history_page.dart';

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

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final userName = user.userMetadata?['name'] as String?;
      final profile = await userService
          .fetchUserProfile(); // ✅ получаем профиль

      setState(() {
        _name = userName ?? '';
        _email = user.email;
        _diabetesType = profile?.diabetesType ?? 'Not specified';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Error during sign out: $e");
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

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
    final greeting = _name?.isNotEmpty == true
        ? "Hi, $_name"
        : "Hi, ${_email ?? 'Guest'}";

    return Scaffold(
      backgroundColor: scheme.background,
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
      drawer: Drawer(
        child: Container(
          color: scheme.surface,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
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
              _drawerTile(Icons.monitor_heart_outlined, 'Log glucose', () {}),
              _drawerTile(Icons.restaurant_menu_outlined, 'Enter meals', () {}),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                      title: 'Log glucose',
                      subtitle: 'Quickly add a reading',
                    ),
                    const Divider(height: 1),
                    _HomeTile(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Meals & carbs',
                      subtitle: 'Track meals and carbs',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.alarm, color: scheme.primary),
                      label: Text(
                        'Reminders',
                        style: TextStyle(color: scheme.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: scheme.primary, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap; // ✅ добавлено

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap, // ✅ добавлено
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {}, // ✅ теперь можно передать кастомный переход
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
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
