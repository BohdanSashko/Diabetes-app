import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/models/insulin_record.dart';

class InsulinService {
  final supabase = Supabase.instance.client;

  Future<List<InsulinRecord>> fetch() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('insulin_records')
        .select()
        .eq('user_id', user.id)
        .order('time', ascending: false);

    return data.map((d) => InsulinRecord.fromJson(d)).toList();
  }

  Future<void> add(double units, String type, {String? note}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('insulin_records').insert({
      'user_id': user.id,
      'units': units,
      'type': type,
      'note': note,
      'time': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(int id) async {
    await supabase.from('insulin_records').delete().eq('id', id);
  }
}
