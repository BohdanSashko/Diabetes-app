import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/models/insulin_record.dart';

class InsulinService {
  final supabase = Supabase.instance.client;

  /// Fetch all insulin logs for current user
  Future<List<InsulinRecord>> fetchRecords() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('insulin_records')
        .select()
        .eq('user_id', user.id)
        .order('recorded_at', ascending: false);

    return data.map((d) => InsulinRecord.fromJson(d)).toList();
  }

  /// Add new insulin entry
  Future<void> addRecord(double units, String type, {String? note}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('insulin_records').insert({
      'user_id': user.id,
      'units': units,
      'type': type,
      'note': note,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete insulin entry
  Future<void> deleteRecord(int id) async {
    await supabase.from('insulin_records').delete().eq('id', id);
  }
}
