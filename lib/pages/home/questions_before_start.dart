import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/user_service.dart';
import '../../models/user_model.dart';


const Color kBrandBlue = Color(0xFF009FCC);

class DiabetesQuestionPage extends StatefulWidget {
  final VoidCallback onFinished;

  const DiabetesQuestionPage({super.key, required this.onFinished});

  @override
  State<DiabetesQuestionPage> createState() => _DiabetesQuestionPageState();
}

class _DiabetesQuestionPageState extends State<DiabetesQuestionPage> {
  final userService = UserService();

  /// User profile fields
  String? diabetesType;
  bool usesInsulin = false;
  double targetLow = 4.0;
  double targetHigh = 8.0;

  bool _saving = false;    // Prevent double-clicking "Continue"
  bool _loaded = false;    // Show loader while profile loads

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load saved values if profile exists
  }

  /// Loads user profile from Supabase (if exists)
  Future<void> _loadUserProfile() async {
    final profile = await userService.fetchUserProfile();

    if (profile != null) {
      setState(() {
        diabetesType = profile.diabetesType;
        usesInsulin = profile.usesInsulin;
        targetLow = profile.targetLow;
        targetHigh = profile.targetHigh;
      });
    }

    setState(() => _loaded = true);
  }

  /// Called when user taps "Continue"
  Future<void> _finish() async {
    // User must select diabetes type
    if (diabetesType == null || diabetesType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diabetes type')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Build the profile object
      final profile = UserProfile(
        id: userService.currentUser!.id,
        diabetesType: diabetesType,
        usesInsulin: usesInsulin,
        targetLow: targetLow,
        targetHigh: targetHigh,
      );

      // Save to Supabase
      await userService.saveUserProfile(profile);

      // Store local flag so onboarding does not repeat
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstLoginDone', true);

      if (!mounted) return;

      // VERY IMPORTANT:
      // We call the callback AFTER the current frame.
      // This avoids: "setState() called after dispose"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFinished(); // Usually navigates to StartPage
      });

    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    /// Show loader until everything is loaded
    if (!_loaded) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: const Center(
          child: CircularProgressIndicator(color: kBrandBlue),
        ),
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

            /// HEADER TEXT
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

            /// DIABETES TYPE CARD
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

            /// INSULIN SWITCH CARD
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

            /// TARGET RANGE CARD
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

            /// BOTTOM BUTTON
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


  /// Beautiful card wrapper for dropdown/switch sections
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

  /// Numeric text field used for low/high glucose
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

  /// Dropdown background styling
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
