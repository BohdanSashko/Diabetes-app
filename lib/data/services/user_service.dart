import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/models/user_model.dart';

/// -------------------------
/// Сервіс користувача
/// -------------------------
class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  /// Отримати ID користувача навіть під час email verification
  Future<String?> getUserId() async {
    return currentUser?.id ?? _supabase.auth.currentSession?.user.id;
  }

  /// Перевірка, чи існує профіль
  Future<bool> hasProfile() async {
    final id = await getUserId();
    if (id == null) return false;

    final response = await _supabase
        .from('user_profiles')
        .select('id')
        .eq('id', id)
        .maybeSingle();

    return response != null;
  }

  /// Завантаження профілю
  Future<UserProfile?> fetchUserProfile() async {
    final id = await getUserId();
    if (id == null) return null;

    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(response));
  }

  /// Збереження або оновлення профілю
  Future<void> saveUserProfile(UserProfile profile) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('user_profiles').upsert(
      profile.toJson(),
      onConflict: 'id',
    );
  }

  /// Видалення профілю користувача
  Future<void> deleteProfile() async {
    final user = currentUser;
    if (user == null) return;

    await _supabase.from('user_profiles').delete().eq('id', user.id);
  }
}
