import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_app/models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<String?> getUserId() async {
    return currentUser?.id ?? _supabase.auth.currentSession?.user.id;
  }

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

// Load user profile
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


  Future<void> saveUserProfile(UserProfile profile) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('user_profiles').upsert(
      profile.toJson(),
      onConflict: 'id',
    );
  }

  Future<void> deleteProfile() async {
    final user = currentUser;
    if (user == null) return;

    await _supabase.from('user_profiles').delete().eq('id', user.id);
  }
}
