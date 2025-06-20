import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../utils/helpers.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<User?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();
      return User.fromJson(userData);
    }
    return null;
  }

  Future<void> addUser({
    required String email,
    required String password,
    required String name,
    required String role,
    String? batchId,
    String? departmentId,
  }) async {
    try {
      // Sign up user in auth.users
      final response = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Auto-verify email
          appMetadata: {'role': role},
        ),
      );

      // Insert user in users table
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'role': role,
        'name': name,
        'batch_id': batchId,
        'department_id': departmentId,
      });
    } catch (e) {
      throw Exception('Failed to add user: $e');
    }
  }
}