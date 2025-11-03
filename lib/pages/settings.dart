import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class AppSettingsPage extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const AppSettingsPage({super.key, this.onThemeChanged});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool darkMode = false;
  bool notificationsEnabled = true;
  bool autoSync = true;
  String unit = 'mg/dL';
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      autoSync = prefs.getBool('autoSync') ?? true;
      unit = prefs.getString('unit') ?? 'mg/dL';

      final timeString = prefs.getString('reminderTime');
      if (timeString != null) {
        final parts = timeString.split(':');
        reminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('autoSync', autoSync);
    await prefs.setString('unit', unit);
    await prefs.setString(
      'reminderTime',
      '${reminderTime.hour}:${reminderTime.minute}',
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );
    if (picked != null) {
      setState(() => reminderTime = picked);
      _savePrefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Appearance'),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: darkMode,
                  activeColor: kBrandBlue,
                  onChanged: (v) {
                    setState(() => darkMode = v);
                    _savePrefs();
                    widget.onThemeChanged?.call(v);
                  },
                ),
                const Divider(),

                _sectionTitle(context, 'Units'),
                DropdownButtonFormField<String>(
                  value: unit,
                  dropdownColor: scheme.surface,
                  decoration: _inputDecoration(context),
                  items: const [
                    DropdownMenuItem(value: 'mg/dL', child: Text('mg/dL')),
                    DropdownMenuItem(value: 'mmol/L', child: Text('mmol/L')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => unit = v);
                    _savePrefs();
                  },
                ),
                const Divider(),

                _sectionTitle(context, 'Notifications'),
                SwitchListTile(
                  title: const Text('Enable Daily Reminders'),
                  value: notificationsEnabled,
                  activeColor: kBrandBlue,
                  onChanged: (v) {
                    setState(() => notificationsEnabled = v);
                    _savePrefs();
                  },
                ),
                ListTile(
                  title: const Text('Reminder Time'),
                  subtitle: Text(reminderTime.format(context)),
                  trailing: Icon(Icons.access_time, color: scheme.primary),
                  onTap: _pickTime,
                ),
                const Divider(),

                _sectionTitle(context, 'Data Sync'),
                SwitchListTile(
                  title: const Text('Auto Sync with Cloud'),
                  value: autoSync,
                  activeColor: kBrandBlue,
                  onChanged: (v) {
                    setState(() => autoSync = v);
                    _savePrefs();
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      setState(() {
                        darkMode = false;
                        notificationsEnabled = true;
                        autoSync = true;
                        unit = 'mg/dL';
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings reset to default'),
                          ),
                        );
                      }
                    },
                    label: const Text(
                      'Reset to Default',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- helpers ---
  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: scheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }
}
