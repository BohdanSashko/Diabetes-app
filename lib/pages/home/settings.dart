import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // for MyAppState

const Color kBrandBlue = Color(0xFF009FCC);

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late ThemeMode _themeMode;
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

    final theme = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _themeMode = switch (theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
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
    await prefs.setString('themeMode', _themeMode.name);
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

  void _updateTheme(ThemeMode newMode) {
    final parent = context.findAncestorStateOfType<MyAppState>();
    parent?.updateThemeMode(newMode);
    setState(() => _themeMode = newMode);
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(context, 'Appearance'),
          _themeSelector(context),
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
                  _themeMode = ThemeMode.system;
                  notificationsEnabled = true;
                  autoSync = true;
                  unit = 'mg/dL';
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to default')),
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
    );
  }

  // --- UI helpers ---
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
      fillColor: scheme.surfaceVariant.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  Widget _themeSelector(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
      ],
      selected: {_themeMode},
      onSelectionChanged: (selection) => _updateTheme(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        ),
      ),
    );
  }
}
