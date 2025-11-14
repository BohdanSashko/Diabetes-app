import 'package:flutter/material.dart';
import '../../data/services/insulin_service.dart';

class LogInsulinPage extends StatefulWidget {
  const LogInsulinPage({super.key});

  @override
  State<LogInsulinPage> createState() => _LogInsulinPageState();
}

class _LogInsulinPageState extends State<LogInsulinPage> {
  final _service = InsulinService();
  double _units = 4;
  String _type = "rapid";
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Log Insulin"),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            // --------------------------
            // TYPE SELECT CARD
            // --------------------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
                      : [Colors.lightBlue.shade100, Colors.lightBlue.shade50],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Insulin type",
                    style: TextStyle(
                      fontSize: 16,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _insulinChip("Rapid", "rapid", Icons.bolt),
                      const SizedBox(width: 12),
                      _insulinChip("Basal", "basal", Icons.water_drop),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------
            // DOSAGE CARD
            // --------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Dose (units)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _units.toStringAsFixed(1),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Slider(
                    min: 0,
                    max: 40,
                    divisions: 80,
                    value: _units,
                    activeColor: scheme.primary,
                    onChanged: (v) => setState(() => _units = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------
            // NOTE FIELD
            // --------------------------
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: "Note (optional)",
                filled: true,
                fillColor: scheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const Spacer(),

            // --------------------------
            // SAVE BUTTON
            // --------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Save"),
                onPressed: () async {
                  await _service.add(
                    _units,
                    _type,
                    note: _noteCtrl.text,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --------------------------
  // Insulin TYPE CHIP
  // --------------------------
  Widget _insulinChip(String label, String value, IconData icon) {
    final isSelected = _type == value;
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? scheme.primary : scheme.surface,
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: scheme.primary.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? scheme.onPrimary : scheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? scheme.onPrimary : scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
