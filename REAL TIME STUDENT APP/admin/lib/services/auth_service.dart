import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return "Login failed";

      // Check user role from 'users' table
      final roleResponse = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      if (roleResponse['role'] != 'admin') {
        return "Access denied: Only admins can log in here.";
      }

      return null; // login successful
    } catch (e) {
      return "Login error: ${e.toString()}";
    }
  }
}
