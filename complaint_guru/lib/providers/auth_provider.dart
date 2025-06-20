import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/helpers.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final AuthService _authService = AuthService();

  User? get user => _user;

  Future<void> login(String email, String password, BuildContext context) async {
    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _user = user;
        notifyListeners();
      } else {
        Helpers.showSnackBar(context, 'Invalid credentials');
      }
    } catch (e) {
      Helpers.showSnackBar(context, e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }
}