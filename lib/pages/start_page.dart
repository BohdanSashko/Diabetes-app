import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'sign_up.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class StartPage extends StatefulWidget {
  final String? initialEmail; // 👈 Email passed from BiometricAuth

  const StartPage({super.key, this.initialEmail});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late final Box usersBox;
  late final Box sessionBox;
  String? _email;
  String? _name;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('secure_users');
    sessionBox = Hive.box('secure_session');

    // Delay a bit to ensure Hive writes are finished
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 250));
      _loadSession();
    });
  }

  void _loadSession() {
    // ✅ Use passed email first; fallback to Hive
    final email = widget.initialEmail ?? sessionBox.get('currentUser') as String?;
    if (email == null || email.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignUpPage()),
      );
      return;
    }

    final record = usersBox.get(email);
    final name = (record is Map) ? (record['name'] as String?) : null;

    setState(() {
      _email = email;
      _name = name?.trim().isEmpty == true ? null : name;
    });
  }

  void _signOut() {
    sessionBox.delete('currentUser');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _name != null
        ? 'Hi, $_name'
        : (_email != null ? 'Hi, $_email' : 'Welcome');

    return Scaffold(
      backgroundColor: const Color(0xFFE3F4FA),
      appBar: AppBar(
        title: const Text(
          'DiaWell',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: kBrandBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    Text(
                      _name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(_email ?? '', style: const TextStyle(color: Colors.white70)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _mainCard(),
              const SizedBox(height: 12),
              _bottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // 🧩 Components
  Widget _mainCard() {
    return Container(
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
        children: const [
          _HomeTile(
            icon: Icons.monitor_heart_outlined,
            title: 'Log glucose',
            subtitle: 'Quickly add a reading',
          ),
          Divider(height: 1),
          _HomeTile(
            icon: Icons.restaurant_menu_outlined,
            title: 'Meals & carbs',
            subtitle: 'Track meals and carbs',
          ),
          Divider(height: 1),
          _HomeTile(
            icon: Icons.show_chart_outlined,
            title: 'View trends',
            subtitle: 'Insights over time',
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.alarm),
            label: const Text('Reminders'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kBrandBlue,
              side: const BorderSide(color: kBrandBlue, width: 1.4),
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
              elevation: 4,
              shadowColor: kBrandBlue.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }

  ListTile _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: kBrandBlue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
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
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TODO: $title')),
      ),
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
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
