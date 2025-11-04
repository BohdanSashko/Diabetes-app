import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class DiabetesQuestionPage extends StatefulWidget {
  final VoidCallback onFinished;
  const DiabetesQuestionPage({super.key, required this.onFinished});

  @override
  State<DiabetesQuestionPage> createState() => _DiabetesQuestionPageState();
}

class _DiabetesQuestionPageState extends State<DiabetesQuestionPage> {
  final supabase = Supabase.instance.client;

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
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        diabetesType = response['diabetes_type'];
        usesInsulin = response['uses_insulin'] ?? false;
        targetLow = (response['target_low'] ?? 4.0).toDouble();
        targetHigh = (response['target_high'] ?? 8.0).toDouble();
      });
    }

    setState(() => _loaded = true);
  }

  // 🔹 Збереження або оновлення профілю користувача у Supabase
  Future<void> _saveUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('user_profiles').upsert({
      'id': user.id,
      'diabetes_type': diabetesType,
      'uses_insulin': usesInsulin,
      'target_low': targetLow,
      'target_high': targetHigh,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _finish() async {
    if (diabetesType == null || diabetesType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diabetes type')),
      );
      return;
    }

    setState(() => _saving = true);
    await _saveUserProfile();

    // також ставимо флаг firstLoginDone у локальних prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLoginDone', true);

    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Scaffold(
        backgroundColor: scheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: kBrandBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.background,
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
            const Text(
              'What type of diabetes do you have?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: diabetesType?.isNotEmpty == true ? diabetesType : null,
              items: const [
                DropdownMenuItem(value: 'Type 1', child: Text('Type 1')),
                DropdownMenuItem(value: 'Type 2', child: Text('Type 2')),
                DropdownMenuItem(value: 'Gestational', child: Text('Gestational')),
                DropdownMenuItem(value: 'Other', child: Text('Other / Not sure')),
              ],
              onChanged: (v) => setState(() => diabetesType = v),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Do you use insulin?'),
              activeColor: kBrandBlue,
              value: usesInsulin,
              onChanged: (v) => setState(() => usesInsulin = v),
            ),
            const SizedBox(height: 20),
            const Text('Target glucose range (mmol/L):'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: targetLow.toStringAsFixed(1),
                    decoration: const InputDecoration(labelText: 'Low'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) =>
                    targetLow = double.tryParse(v) ?? targetLow,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: targetHigh.toStringAsFixed(1),
                    decoration: const InputDecoration(labelText: 'High'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) =>
                    targetHigh = double.tryParse(v) ?? targetHigh,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
