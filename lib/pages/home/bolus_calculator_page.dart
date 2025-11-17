import 'package:flutter/material.dart';
import '../../data/services/insulin_service.dart';

class BolusCalculatorPage extends StatefulWidget {
  const BolusCalculatorPage({super.key});

  @override
  State<BolusCalculatorPage> createState() => _BolusCalculatorPageState();
}

class _BolusCalculatorPageState extends State<BolusCalculatorPage>
    with SingleTickerProviderStateMixin {
  final _carbsCtrl = TextEditingController();
  final _glucoseCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: "6.0");
  final _ratioCtrl = TextEditingController(text: "10"); // Соотношение углеводов на 1 единицу инсулина
  final _factorCtrl = TextEditingController(text: "2.0"); // Коррекционный коэффициент ммоль/л на 1 единицу

  double? _result;
  bool _showResult = false;
  final _service = InsulinService();

  @override
  void dispose() {
    _carbsCtrl.dispose();
    _glucoseCtrl.dispose();
    _targetCtrl.dispose();
    _ratioCtrl.dispose();
    _factorCtrl.dispose();
    super.dispose();
  }

  // Расчет болюса
  void _calculate() {
    final carbs = double.tryParse(_carbsCtrl.text) ?? 0;
    final glucose = double.tryParse(_glucoseCtrl.text) ?? 0;
    final target = double.tryParse(_targetCtrl.text) ?? 6.0;
    final ratio = double.tryParse(_ratioCtrl.text) ?? 10;
    final factor = double.tryParse(_factorCtrl.text) ?? 2.0;

    if (carbs <= 0 && glucose <= 0) return;

    final mealBolus = carbs / ratio; // Болюс на еду
    final correctionBolus = (glucose - target) / factor; // Коррекционный болюс

    final double total = (mealBolus + correctionBolus).clamp(0, 30).toDouble(); // Ограничиваем диапазон

    setState(() {
      _result = total;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Bolus Calculator"),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _gradientHeader(context),

            const SizedBox(height: 16),

            _inputField("Carbs (g)", _carbsCtrl, Icons.fastfood),
            const SizedBox(height: 12),

            _inputField("Current glucose (mmol/L)", _glucoseCtrl, Icons.bloodtype),
            const SizedBox(height: 12),

            _inputField("Target glucose (mmol/L)", _targetCtrl, Icons.track_changes),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                    child: _inputField("Carb ratio", _ratioCtrl, Icons.calculate)),
                const SizedBox(width: 12),
                Expanded(
                    child: _inputField("Correction factor", _factorCtrl, Icons.bolt)),
              ],
            ),

            const SizedBox(height: 20),

            // =======================
            // Кнопка расчета
            // =======================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Calculate",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_showResult) _resultCard(context), // Показываем карточку с результатом
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // Верхний градиентный баннер
  // ------------------------------------------------
  Widget _gradientHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
              : [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Bolus Calculator",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            "Based on carbs, glucose & targets",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------
  // Компонент поля ввода
  // ------------------------------------------------
  Widget _inputField(String label, TextEditingController ctrl, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: scheme.primary),
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ------------------------------------------------
  // Карточка с результатом (анимированная)
  // ------------------------------------------------
  Widget _resultCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = _result?.toStringAsFixed(1) ?? "0.0";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            "Recommended bolus",
            style:
            TextStyle(fontSize: 16, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 8),
          Text(
            "$value units",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Apply & Log"),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                await _service.addRecord(
                  _result ?? 0,
                  "bolus",
                  note: "Calculated automatically", // Сохраняем запись автоматически
                );
                if (!mounted) return;
                Navigator.pop(context); // Закрываем страницу
              },
            ),
          )
        ],
      ),
    );
  }
}
