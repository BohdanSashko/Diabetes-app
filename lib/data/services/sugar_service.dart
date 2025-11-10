import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/data/services/sugar_record.dart';

class SugarService {
  final _supabase = Supabase.instance.client;

  Future<List<SugarRecord>> fetchRecords() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('sugar_records')
        .select()
        .eq('user_id', user.id)
        .order('measured_at', ascending: false);

    return (data as List).map((json) => SugarRecord.fromJson(json)).toList();
  }

  Future<void> addRecord(double glucose, {String? note}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('sugar_records').insert({
      'user_id': user.id,
      'glucose': glucose,
      'note': note,
    });
  }

  Future<void> deleteRecord(String id) async {
    await _supabase.from('sugar_records').delete().eq('id', id);
  }
}
