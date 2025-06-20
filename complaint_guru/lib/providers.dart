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
      final user = await _authService.login(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(user: user)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  Future<void> loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}

class ComplaintProvider extends ChangeNotifier {
  List<models.Complaint> _complaints = [];
  List<models.Complaint> get complaints => _complaints;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchComplaints(String userId, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      _complaints = await DatabaseService().getComplaints(userId, role);
    } catch (e) {
      print('Error fetching complaints: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshComplaints(String userId, String role) async {
    await fetchComplaints(userId, role);
  }
}

class AdminProvider extends ChangeNotifier {
  List<models.Department> _departments = [];
  List<models.Batch> _batches = [];
  List<models.User> _users = [];
  bool _isLoading = false;

  List<models.Department> get departments => _departments;
  List<models.Batch> get batches => _batches;
  List<models.User> get users => _users;
  bool get isLoading => _isLoading;

  Future<void> fetchDepartments() async {
    _isLoading = true;
    notifyListeners();
    try {
      _departments = await DatabaseService().getDepartments();
    } catch (e) {
      print('Error fetching departments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBatches() async {
    _isLoading = true;
    notifyListeners();
    try {
      _batches = await DatabaseService().getBatches();
    } catch (e) {
      print('Error fetching batches: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await Supabase.instance.client.from('users').select();
      _users = response.map((e) => models.User.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}