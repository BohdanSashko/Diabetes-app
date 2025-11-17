import 'package:flutter/material.dart';
import '../../data/services/meal_service.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class LogMealPage extends StatefulWidget {
  const LogMealPage({super.key});

  @override
  State<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends State<LogMealPage> {
  final _service = MealService();

  final TextEditingController _productCtrl = TextEditingController();
  final TextEditingController _carbsCtrl = TextEditingController();
  final TextEditingController _servingsCtrl = TextEditingController(text: "1");
  final TextEditingController _noteCtrl = TextEditingController();

  String _category = "Breakfast";

  double get _carbsPerServing =>
      double.tryParse(_carbsCtrl.text.trim()) ?? 0;

  double get _servings =>
      double.tryParse(_servingsCtrl.text.trim()) ?? 1;

  double get _totalCarbs => _carbsPerServing * _servings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Meal"),
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ---------------------------
            // MEAL CATEGORY
            // ---------------------------
            _sectionTitle("Meal category"),
            const SizedBox(height: 8),

            Wrap(
              spacing: 12,
              children: [
                _chip("Breakfast", Icons.free_breakfast),
                _chip("Lunch", Icons.restaurant),
                _chip("Dinner", Icons.dining),
                _chip("Snack", Icons.cookie),
              ],
            ),

            const SizedBox(height: 22),

            // ---------------------------
            // PRODUCT NAME
            // ---------------------------
            _sectionTitle("Product name"),
            const SizedBox(height: 8),
            _inputField(_productCtrl, "e.g. Pasta, Yogurt, Bread"),

            const SizedBox(height: 22),

            // ---------------------------
            // CARBS + SERVINGS
            // ---------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Carbs & servings"),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Carbs (g)",
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            _miniField(
                              controller: _carbsCtrl,
                              label: "",
                              type: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Servings",
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(height: 6),
                            _miniField(
                              controller: _servingsCtrl,
                              label: "",
                              type: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      "Total carbs: ${_totalCarbs.toStringAsFixed(1)} g",
                      style: const TextStyle(
                        color: kBrandBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 22),

            // NOTE FIELD
            _sectionTitle("Note (optional)"),
            const SizedBox(height: 8),
            _inputField(_noteCtrl, "Any additional info..."),

            const SizedBox(height: 40),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Save meal"),
                onPressed: () async {
                  final name = _productCtrl.text.trim();
                  final carbs = _totalCarbs;

                  if (name.isEmpty) return;

                  await _service.add(
                    name,
                    carbs.round(),
                    category: _category,
                    servings: _servings,
                    note: _noteCtrl.text.trim(),
                    carbsPerServing: _carbsPerServing,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // UI HELPERS
  // ---------------------------

  Widget _chip(String label, IconData icon) {
    final isSelected = _category == label;
    final scheme = Theme
        .of(context)
        .colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _category = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: scheme.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? scheme.onPrimary : scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? scheme.onPrimary : scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _inputField(TextEditingController c, String hint) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }

  Widget _miniField({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
  }) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    return TextField(
      controller: controller,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
