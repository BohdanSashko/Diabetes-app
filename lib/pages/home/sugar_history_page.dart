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

  String _unit = 'mmol/L'; // 🔹 Current unit (mmol/L or mg/dL)

  @override
  void initState() {
    super.initState();
    _loadUnit(); // 🔹 Load saved unit from local storage
    _loadRecords(); // 🔹 Load glucose records from the database
  }

  Future<void> _loadUnit() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _unit = prefs.getString('unit') ?? 'mmol/L';
      // 🔹 Load saved unit so UI matches the user's preference
    });
  }

  Future<void> _loadRecords() async {
    final records = await _service.fetchRecords();

    setState(() {
      _records = records;
      _loading = false; // 🔹 Hide loading after data is received
    });
  }

  double _convert(double value) {
    // 🔹 Convert mmol/L to mg/dL for display
    //    Database always stores mmol/L
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
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : scheme.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add sugar record ($_unit)"),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: "Glucose ($_unit)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(labelText: "Note (optional)"),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);

              if (value != null) {
                // 🔹 Convert mg/dL → mmol/L before saving
                final mmolValue = _unit == 'mg/dL' ? (value / 18) : value;

                await _service.addRecord(mmolValue, note: noteCtrl.text);

                if (context.mounted) {
                  Navigator.pop(context);
                  _loadRecords(); // 🔹 Refresh data
                }
              }
            },
            child: const Text("Save"),
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
      backgroundColor: isDark
          ? const Color(0xFF0E1A24)
          : scheme.surface.withOpacity(0.95),

      appBar: AppBar(
        title: Text("Sugar History ($_unit)"),
        backgroundColor: kBrandBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadUnit(); // 🔹 User may change units in settings
              _loadRecords(); // 🔹 Reload records from database
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecordDialog,
        backgroundColor: kBrandBlue,
        label: const Text("Add"),
        icon: const Icon(Icons.add),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // 🔹 Initial loading
          : _records.isEmpty
          ? Center(
              child: Text(
                "No records yet",
                style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
              ),
            )
          : RefreshIndicator(
              // 🔹 Pull to refresh
              onRefresh: () async {
                await _loadUnit();
                await _loadRecords();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildChartCard(), // 🔹 Chart of last 10 values
                  const SizedBox(height: 16),
                  ..._records.map(_buildSugarCard),
                ],
              ),
            ),
    );
  } //           CHART CARD

  Widget _buildChartCard() {
    if (_records.isEmpty) return const SizedBox.shrink();

    // 🔹 Use only last 10 records for clarity
    final lastRecords = _records.take(10).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
        ),
        borderRadius: BorderRadius.circular(18),
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
                    // 🔹 Smooth line
                    color: Colors.white,
                    barWidth: 3,

                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.2),
                    ),

                    dotData: FlDotData(show: false),

                    spots: [
                      for (var i = 0; i < lastRecords.length; i++)
                        FlSpot(i.toDouble(), _convert(lastRecords[i].glucose)),
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

  //          SUGAR CARD
  Widget _buildSugarCard(SugarRecord r) {
    final color = _glucoseColor(r.glucose); // 🔹 Color based on glucose level
    final icon = _glucoseIcon(r.glucose); // 🔹 Icon based on level

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? color.withOpacity(0.18) : color.withOpacity(0.12);

    final textColor = isDark ? Colors.white : Colors.black87;

    final value = _convert(r.glucose); // 🔹 Convert for UI

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
          child: Icon(icon, color: Colors.white),
        ),

        title: Text(
          "${value.toStringAsFixed(1)} $_unit",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),

        subtitle: Text(
          "${r.measuredAt.toLocal().toString().split('.')[0]}\n${r.note ?? ''}",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.3,
          ),
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

  // 🔹 Pick card color based on glucose value
  Color _glucoseColor(double value) {
    if (value < 4.0) return Colors.orangeAccent; // Low
    if (value > 10.0) return Colors.redAccent; // High
    return kBrandBlue; // Normal
  }

  // 🔹 Pick icon based on glucose value
  IconData _glucoseIcon(double value) {
    if (value < 4.0) return Icons.warning_amber_rounded;
    if (value > 10.0) return Icons.trending_up_rounded;
    return Icons.favorite_rounded;
  }
}
