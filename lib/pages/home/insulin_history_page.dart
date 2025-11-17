import 'package:flutter/material.dart';
import '../../models/insulin_record.dart';
import '../../data/services/insulin_service.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class InsulinHistoryPage extends StatefulWidget {
  const InsulinHistoryPage({super.key});

  @override
  State<InsulinHistoryPage> createState() => _InsulinHistoryPageState();
}

class _InsulinHistoryPageState extends State<InsulinHistoryPage> {
  final _service = InsulinService();
  List<InsulinRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords(); // Загружаем данные при инициализации
  }

  Future<void> _loadRecords() async {
    final records = await _service.fetchRecords(); // Получаем записи из сервиса
    setState(() {
      _records = records;
      _loading = false; // Убираем индикатор загрузки
    });
  }

  // Определяем цвет карточки в зависимости от типа инсулина
  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'bolus':
        return Colors.blueAccent;
      case 'basal':
        return Colors.green;
      case 'correction':
        return Colors.orangeAccent;
      default:
        return kBrandBlue;
    }
  }

  // Определяем иконку в зависимости от типа инсулина
  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bolus':
        return Icons.flash_on;
      case 'basal':
        return Icons.water_drop;
      case 'correction':
        return Icons.auto_fix_high;
      default:
        return Icons.medication;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Insulin History"),
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator()) // Показываем индикатор, пока данные загружаются
          : _records.isEmpty
          ? const Center(child: Text("No insulin records yet")) // Если записей нет
          : RefreshIndicator(
        onRefresh: _loadRecords, // Обновление списка свайпом вниз
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _records.length,
          itemBuilder: (_, i) => _buildRecordCard(_records[i]),
        ),
      ),
    );
  }

  // Строим карточку одной записи инсулина
  Widget _buildRecordCard(InsulinRecord r) {
    final color = _typeColor(r.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.22) : color.withOpacity(0.15), // Прозрачность зависит от темы
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25), // Тень карточки
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(_typeIcon(r.type)),
        ),
        title: Text(
          "${r.units} units — ${r.type}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${r.recorded_at.toLocal().toString().split('.')[0]}\n${r.note ?? ''}", // Дата и заметка
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            await _service.deleteRecord(r.id); // Удаляем запись
            _loadRecords(); // Обновляем список
          },
        ),
      ),
    );
  }
}
