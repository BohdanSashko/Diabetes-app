import 'package:flutter/material.dart';
import '../../data/services/meal_service.dart';
import 'package:diabetes_app/models/meal_model.dart';
import 'log_meal_page.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  final _service = MealService();
  List<MealRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _service.fetch();
    setState(() {
      _records = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meals & Carbs"),
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBrandBlue,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogMealPage()),
          ).then((_) => _load());
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(child: Text("No meals logged yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (_, i) => _buildCard(_records[i]),
      ),
    );
  }

  Widget _buildCard(MealRecord r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final color = isDark
        ? Colors.tealAccent.withOpacity(0.15)
        : kBrandBlue.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kBrandBlue,
          child: const Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(
          "${r.mealType} — ${r.carbs}g carbs",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "${r.time.toLocal().toString().split('.')[0]}\n${r.note ?? ''}",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            await _service.delete(r.id);
            _load();
          },
        ),
      ),
    );
  }
}
