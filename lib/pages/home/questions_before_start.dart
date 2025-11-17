import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/user_service.dart';

const Color kBrandBlue = Color(0xFF009FCC);

class DiabetesQuestionPage extends StatefulWidget {
  final VoidCallback onFinished;
  const DiabetesQuestionPage({super.key, required this.onFinished});

  @override
  State<DiabetesQuestionPage> createState() => _DiabetesQuestionPageState();
}

class _DiabetesQuestionPageState extends State<DiabetesQuestionPage> {
  final userService = UserService();

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
    // 📌 Загружаем профиль пользователя из Supabase через сервис
    // Если профиль есть — заполняем поля (редактирование, а не только первый вход)
    final profile = await userService.fetchUserProfile();
    if (profile != null) {
      setState(() {
        diabetesType = profile.diabetesType;
        usesInsulin = profile.usesInsulin;
        targetLow = profile.targetLow;
        targetHigh = profile.targetHigh;
      });
    }
    setState(() => _loaded = true); // 📌 Страница готова к отображению
  }

  Future<void> _finish() async {
    // 📌 Проверка на обязательный выбор типа диабета
    if (diabetesType == null || diabetesType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diabetes type')),
      );
      return;
    }

    setState(() => _saving = true);

    // 📌 Создаём объект профиля (сложность здесь: собираем данные из UI → модель)
    final profile = UserProfile(
      id: userService.currentUser!.id,
      diabetesType: diabetesType,
      usesInsulin: usesInsulin,
      targetLow: targetLow,
      targetHigh: targetHigh,
    );

    // 📌 Отправляем на сервер через сервис (абстракция над Supabase)
    await userService.saveUserProfile(profile);

    // 📌 Локальный флаг, чтобы не показывать вопросы при следующем запуске
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLoginDone', true);

    if (mounted) widget.onFinished(); // 📌 Возвращаем в вызывающую страницу
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            const Text(
              'What type of diabetes do you have?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 📌 Используем initialValue, чтобы корректно показывать данные профиля
            DropdownButtonFormField<String>(
              initialValue:
              diabetesType?.isNotEmpty == true ? diabetesType : null,
              items: const [
                DropdownMenuItem(value: 'Type 1', child: Text('Type 1')),
                DropdownMenuItem(value: 'Type 2', child: Text('Type 2')),
                DropdownMenuItem(value: 'Gestational', child: Text('Gestational')),
                DropdownMenuItem(value: 'Other', child: Text('Other / Not sure')),
              ],
              onChanged: (v) => setState(() => diabetesType = v),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text('Do you use insulin?'),
              activeThumbColor: kBrandBlue,
              value: usesInsulin,
              onChanged: (v) => setState(() => usesInsulin = v),
            ),
            const SizedBox(height: 20),

            const Text('Target glucose range (mmol/L):'),
            const SizedBox(height: 8),

            // 📌 Поля низ / верх зоны глюкозы → важно сохранить double из строки
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

                // 📌 Показываем индикатор, пока сохраняем
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
