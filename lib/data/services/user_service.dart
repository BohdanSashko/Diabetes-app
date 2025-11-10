import 'package:supabase_flutter/supabase_flutter.dart';

/// -------------------------
/// Модель профілю користувача
/// -------------------------
class UserProfile {
  final String id;
  final String? diabetesType;
  final bool usesInsulin;
  final double targetLow;
  final double targetHigh;
  final String? name;

  UserProfile({
    required this.id,
    this.name,
    this.diabetesType,
    this.usesInsulin = false,
    this.targetLow = 4.0,
    this.targetHigh = 8.0,
  });

  /// Конструктор з JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      diabetesType: json['diabetes_type'] as String?,
      usesInsulin: json['uses_insulin'] ?? false,
      targetLow: (json['target_low'] ?? 4.0).toDouble(),
      targetHigh: (json['target_high'] ?? 8.0).toDouble(),
    );
  }

  /// Конвертація у JSON для Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'diabetes_type': diabetesType,
      'uses_insulin': usesInsulin,
      'target_low': targetLow,
      'target_high': targetHigh,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

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
