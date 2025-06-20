import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart' as models;
import 'services.dart';
import 'screens.dart';

class AuthProvider extends ChangeNotifier {
  models.User? _user;
  models.User? get user => _user;
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      print('AuthProvider: Auth state changed: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn) {
        loadCurrentUser();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password, BuildContext context) async {
    try {
      print('AuthProvider: Attempting login with email: $email');
      final user = await _authService.login(email, password);
      if (user != null) {
        print('AuthProvider: Login successful, user: ${user.id}');
        _user = user;
        notifyListeners();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      } else {
        print('AuthProvider: Login failed, user is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      print('AuthProvider: Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      print('AuthProvider: Loading current user');
      final user = await _authService.getCurrentUser();
      _user = user;
      notifyListeners();
      print('AuthProvider: User load result: ${_user?.id ?? 'null'}');
    } catch (e) {
      print('AuthProvider: Load current user error: $e');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
    print('AuthProvider: Signed out');
  }
}

class ComplaintProvider extends ChangeNotifier {
  List<models.Complaint> _complaints = [];
  List<models.Complaint> get complaints => _complaints;

  Future<void> fetchComplaints(String userId, String role) async {
    try {
      print('ComplaintProvider: Fetching complaints for user: $userId, role: $role');
      _complaints = await DatabaseService().getComplaints(userId, role);
      print('ComplaintProvider: Fetched ${_complaints.length} complaints');
      notifyListeners();
    } catch (e) {
      print('ComplaintProvider: Fetch error: $e');
      throw 'Failed to fetch complaints: $e';
    }
  }
}