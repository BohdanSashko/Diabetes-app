import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/models/meal_model.dart';

class MealService {
  final supabase = Supabase.instance.client;

  Future<List<MealRecord>> fetch() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('meal_logs')
        .select()
        .eq('user_id', user.id)
        .order('time', ascending: false);

    return data.map((e) => MealRecord.fromJson(e)).toList();
  }

  Future<void> add(
      String food,
      int totalCarbs, {
        required String category,
        required double servings,
        required double carbsPerServing,
        String? note,
      }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('meal_logs').insert({
      'user_id': user.id,
      'meal_type': category,
      'food': food,
      'carbs': carbsPerServing,
      'servings': servings,
      'total_carbs': totalCarbs,
      'note': note,
      'time': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(int id) async {
    await supabase.from('meal_logs').delete().eq('id', id);
  }
}
