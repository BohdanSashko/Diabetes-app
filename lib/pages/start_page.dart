import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/bio_auth.dart';
import 'sign_up.dart';

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

  @override
  void initState() {
    super.initState();
    _email = widget.initialEmail;
    _loadName();
  }

  Future<void> _loadName() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _name = user?.displayName ?? '');
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
          (route) => false,
    );
  }

  ListTile _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: kBrandBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _name?.isNotEmpty == true
        ? "Hi, $_name"
        : "Hi, ${_email ?? 'Guest'}";

    return Scaffold(
      backgroundColor: const Color(0xFFE3F4FA),

      appBar: AppBar(
        title: const Text(
          'DiaWell',
          style: TextStyle(
            color: kBrandBlue,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBrandBlue),
      ),

      drawer: Drawer(
        child: Container(
          color: const Color(0xFFE3F4FA),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: kBrandBlue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 42, color: kBrandBlue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _name?.isNotEmpty == true ? _name! : "User",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _email ?? "",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _drawerTile(Icons.monitor_heart_outlined, 'Log glucose', () {}),
              _drawerTile(Icons.restaurant_menu_outlined, 'Enter meals', () {}),
              _drawerTile(Icons.bar_chart_outlined, 'Sugar history', () {}),
              _drawerTile(Icons.settings_outlined, 'Settings', () {}),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sign out',
                    style: TextStyle(color: Colors.redAccent)),
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black12,
                      offset: Offset(0, 8),
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
                      icon: const Icon(Icons.alarm),
                      label: const Text('Reminders'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBrandBlue,
                        side: const BorderSide(
                          color: kBrandBlue,
                          width: 1.4,
                        ),
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
                        backgroundColor: kBrandBlue,
                        foregroundColor: Colors.white,
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

  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('TODO: $title'))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F4FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kBrandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
