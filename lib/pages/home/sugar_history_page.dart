import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/sugar_record.dart';
import '../../data/services/sugar_service.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class SugarHistoryPage extends StatefulWidget {
  const SugarHistoryPage({super.key});

  @override
  State<SugarHistoryPage> createState() => _SugarHistoryPageState();
}

class _SugarHistoryPageState extends State<SugarHistoryPage> {
  final _service = SugarService();
  List<SugarRecord> _records = [];
  bool _loading = true;
  String _unit = 'mmol/L'; // <--- добавлено

  @override
  void initState() {
    super.initState();
    _loadUnit();
    _loadRecords();
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _unit = prefs.getString('unit') ?? 'mmol/L';
    });
  }

  Future<void> _loadRecords() async {
    final records = await _service.fetchRecords();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  double _convert(double value) {
    // 1 mmol/L ≈ 18 mg/dL
    return _unit == 'mg/dL' ? (value * 18) : value;
  }

  Future<void> _addRecordDialog() async {
    final controller = TextEditingController();
    final noteCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
        isDark ? const Color(0xFF1E1E1E) : scheme.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Add sugar record ($_unit)", // <--- отображаем единицы
          style: TextStyle(
              color: scheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Glucose ($_unit)",
                labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: "Note (optional)",
                labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: scheme.primary, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null) {
                // сохраняем всегда в mmol/L (чтобы база единая)
                final mmolValue =
                _unit == 'mg/dL' ? (value / 18) : value;

                await _service.addRecord(mmolValue, note: noteCtrl.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadRecords();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBlue,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Save",
                style:
                TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0E1A24) : scheme.surface.withOpacity(0.95),
      appBar: AppBar(
        title: Text("Sugar History ($_unit)"), // <--- единицы в заголовке
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadUnit(); // обновляем единицы при нажатии
              _loadRecords();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kBrandBlue,
        icon: const Icon(Icons.add),
        label: const Text("Add"),
        onPressed: _addRecordDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? Center(
        child: Text("No records yet",
            style: TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
                fontSize: 16)),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await _loadUnit();
          await _loadRecords();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildChartCard(),
            const SizedBox(height: 16),
            ..._records.map(_buildSugarCard),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    if (_records.isEmpty) return const SizedBox.shrink();

    final lastRecords = _records.take(10).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recent trend", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    dotData: FlDotData(show: false),
                    spots: [
                      for (var i = 0; i < lastRecords.length; i++)
                        FlSpot(
                          i.toDouble(),
                          _convert(lastRecords[i].glucose),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugarCard(SugarRecord r) {
    final color = _glucoseColor(r.glucose);
    final icon = _glucoseIcon(r.glucose);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
    isDark ? color.withOpacity(0.18) : color.withOpacity(0.12);
    final textColor = isDark ? Colors.white : Colors.black87;

    final value = _convert(r.glucose);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        title: Text(
          "${value.toStringAsFixed(1)} $_unit", // <--- конвертация и отображение
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Text(
          "${r.measuredAt.toLocal().toString().split('.')[0]}\n${r.note ?? ''}",
          style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54, height: 1.3),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            await _service.deleteRecord(r.id);
            _loadRecords();
          },
        ),
      ),
    );
  }

  Color _glucoseColor(double value) {
    if (value < 4.0) return Colors.orangeAccent;
    if (value > 10.0) return Colors.redAccent;
    return kBrandBlue;
  }

  IconData _glucoseIcon(double value) {
    if (value < 4.0) return Icons.warning_amber_rounded;
    if (value > 10.0) return Icons.trending_up_rounded;
    return Icons.favorite_rounded;
  }
}
