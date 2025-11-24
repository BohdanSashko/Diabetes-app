import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_app/main.dart';
import 'package:diabetes_app/data/services/notification_service.dart';

late NotificationService notif;

const Color kBrandBlue = Color(0xFF009FCC);

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  /// Current theme setting
  ThemeMode _themeMode = ThemeMode.system;

  /// App settings loaded from SharedPreferences
  bool notificationsEnabled = true;
  bool autoSync = true;
  String unit = 'mg/dL';

  /// Daily reminder time (stored as "HH:MM")
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs(); // Load saved settings on launch
  }

  /// Loads all saved user settings from SharedPreferences
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final theme = prefs.getString('themeMode') ?? 'system';

    setState(() {
      // Restore selected theme
      _themeMode = switch (theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };

      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      autoSync = prefs.getBool('autoSync') ?? true;
      unit = prefs.getString('unit') ?? 'mg/dL';

      // Restore reminder time
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

  /// Saves the current settings to SharedPreferences
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final hour = reminderTime.hour.toString().padLeft(2, '0');
    final minute = reminderTime.minute.toString().padLeft(2, '0');

    await prefs.setString('themeMode', _themeMode.name);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('autoSync', autoSync);
    await prefs.setString('unit', unit);
    await prefs.setString('reminderTime', "$hour:$minute");
  }

  /// Opens a time picker for daily reminders
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );

    if (picked != null) {
      setState(() => reminderTime = picked);
      await _savePrefs();

      // Re-schedule notifications only if user enabled them
      if (notificationsEnabled) {
        await notif.scheduleDaily(picked);
      }
    }
  }

  /// Updates the global app theme (calls MyAppState.updateThemeMode)
  void _updateTheme(ThemeMode newMode) {
    final parent = context.findAncestorStateOfType<MyAppState>();

    parent?.updateThemeMode(newMode);  // Apply theme globally
    setState(() => _themeMode = newMode);

    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,

      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // APPEARANCE SECTION
          _sectionTitle(context, 'Appearance'),
          _themeSelector(context),
          const Divider(),

          // UNITS SECTION
          _sectionTitle(context, 'Units'),
          DropdownButtonFormField<String>(
            initialValue: unit,
            dropdownColor: scheme.surface,
            decoration: _inputDecoration(context),
            items: const [
              DropdownMenuItem(value: 'mg/dL', child: Text('mg/dL')),
              DropdownMenuItem(value: 'mmol/L', child: Text('mmol/L')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => unit = v);
                _savePrefs();
              }
            },
          ),
          const Divider(),

          // NOTIFICATIONS SECTION
          _sectionTitle(context, 'Notifications'),
          SwitchListTile(
            title: const Text("Enable Daily Reminder"),
            value: notificationsEnabled,
            onChanged: (v) async {
              setState(() => notificationsEnabled = v);
              await _savePrefs();

              // Enable/disable daily scheduled notification
              if (v) {
                await notif.scheduleDaily(reminderTime);
              } else {
                await notif.cancel();
              }
            },
          ),

          ListTile(
            title: const Text("Reminder time"),
            subtitle: Text(reminderTime.format(context)),
            onTap: _pickTime, // Use time picker
          ),

          const Divider(),
          // DATA SYNC SECTION
          _sectionTitle(context, 'Data Sync'),
          SwitchListTile(
            title: const Text('Auto Sync with Cloud'),
            value: autoSync,
            activeThumbColor: kBrandBlue,
            onChanged: (v) {
              setState(() => autoSync = v);
              _savePrefs();
            },
          ),

          const SizedBox(height: 20),


          // RESET ALL SETTINGS
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Reset to Default',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
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
            ),
          ),
        ],
      ),
    );
  }
  // UI HELPER
  /// Section title text with consistent styling
  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Reusable decoration for dropdowns + input fields
  InputDecoration _inputDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
    );
  }

  /// Theme selector (System / Light / Dark) with custom styling
  Widget _themeSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
      ],
      selected: {_themeMode},
      onSelectionChanged: (selection) => _updateTheme(selection.first),

      // Custom segmented button theme
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary; // Active segment
          }
          return scheme.surfaceContainerHighest.withOpacity(0.2);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? Colors.white70 : Colors.black87;
        }),
        side: WidgetStateProperty.all(
          BorderSide(
            color: isDark
                ? Colors.white24
                : scheme.outlineVariant.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
