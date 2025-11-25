// questions_before_start.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/user_service.dart';
import '../../models/user_model.dart';
import '../home/start_page.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class DiabetesQuestionPage extends StatefulWidget {
  // kept for compatibility; page will navigate itself after save
  final VoidCallback? onFinished;

  const DiabetesQuestionPage({super.key, this.onFinished});

  @override
  State<DiabetesQuestionPage> createState() => _DiabetesQuestionPageState();
}

class _DiabetesQuestionPageState extends State<DiabetesQuestionPage> {
  final userService = UserService();

  // profile fields
  String? name;
  String? diabetesType;
  bool usesInsulin = false;
  double targetLow = 4.0;
  double targetHigh = 8.0;

  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await userService.fetchUserProfile();
    if (profile != null) {
      setState(() {
        name = profile.name;
        diabetesType = profile.diabetesType;
        usesInsulin = profile.usesInsulin;
        targetLow = profile.targetLow;
        targetHigh = profile.targetHigh;
      });
    }
    setState(() => _loaded = true);
  }

  Future<void> _finish() async {
    if (diabetesType == null || diabetesType!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diabetes type')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // build profile using current user id & metadata where available
      final profile = UserProfile(
        id: userService.currentUser!.id,
        name: userService.currentUser!.userMetadata?['name'] as String?,
        diabetesType: diabetesType,
        usesInsulin: usesInsulin,
        targetLow: targetLow,
        targetHigh: targetHigh,
      );

      // Save to Supabase (await!)
      await userService.saveUserProfile(profile);

      // Save local flag so questions won't show again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstLoginDone', true);

      // If widget was unmounted while saving, stop here
      if (!mounted) return;

      // Navigate using THIS page's context (safe). Use pushReplacement to StartPage.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              StartPage(initialEmail: userService.currentUser?.email ?? ''),
        ),
      );

      // optionally call callback if provided (but don't rely on caller's context)
      // NOTE: do NOT call a caller-captured context for navigation — keep this optional
      widget.onFinished?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: const Center(child: CircularProgressIndicator(color: kBrandBlue)),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Tell us about you'),
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Text(
              "Tell us about you",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "To personalize your experience",
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),

            // diabetes type
            _sectionCard(
              scheme,
              title: "Diabetes type",
              child: DropdownButtonFormField<String>(
                value: diabetesType,
                decoration: _dropdownDecoration(scheme),
                items: const [
                  DropdownMenuItem(value: 'Type 1', child: Text('Type 1')),
                  DropdownMenuItem(value: 'Type 2', child: Text('Type 2')),
                  DropdownMenuItem(
                    value: 'Gestational',
                    child: Text('Gestational'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other / Not sure'),
                  ),
                ],
                onChanged: (v) => setState(() => diabetesType = v),
              ),
            ),

            const SizedBox(height: 20),

            // insulin usage
            _sectionCard(
              scheme,
              title: "Insulin usage",
              child: SwitchListTile(
                title: const Text("Do you use insulin?"),
                activeColor: kBrandBlue,
                value: usesInsulin,
                onChanged: (v) => setState(() => usesInsulin = v),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 20),

            // target range
            _sectionCard(
              scheme,
              title: "Target glucose range (mmol/L)",
              child: Row(
                children: [
                  Expanded(
                    child: _smallNumberField(
                      "Low",
                      targetLow,
                      (v) => targetLow = double.tryParse(v) ?? targetLow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _smallNumberField(
                      "High",
                      targetHigh,
                      (v) => targetHigh = double.tryParse(v) ?? targetHigh,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: kBrandBlue.withOpacity(0.4),
                ),
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    ColorScheme scheme, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _smallNumberField(
    String label,
    double value,
    Function(String) onChanged,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      initialValue: value.toStringAsFixed(1),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(ColorScheme scheme) {
    return InputDecoration(
      filled: true,
      fillColor: scheme.surfaceVariant.withOpacity(0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
